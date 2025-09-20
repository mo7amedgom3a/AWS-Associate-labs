import json
import os
import tempfile
import uuid
from datetime import datetime, timezone

import boto3
from botocore.exceptions import ClientError

try:
	from PIL import Image, ImageEnhance
except Exception as import_error:
	# Pillow should be packaged with the deployment. If it's missing, we still want a clear error.
	raise import_error


s3_client = boto3.client("s3")
dynamodb = boto3.resource("dynamodb")
sns_client = boto3.client("sns")


TABLE_NAME = os.environ.get("TABLE_NAME")
SNS_TOPIC_ARN = os.environ.get("SNS_TOPIC_ARN")
TARGET_BUCKET_NAME = os.environ.get("TARGET_BUCKET_NAME")
ENHANCED_PREFIX = os.environ.get("ENHANCED_PREFIX", "enhanced/")


def _iso_now() -> str:
	return datetime.now(timezone.utc).isoformat()


def _enhance_image(input_path: str, output_path: str) -> None:
	"""Apply simple enhancements: auto-contrast and slight sharpening/brightness.

	This keeps dependencies light and fast while demonstrating the pipeline.
	"""
	with Image.open(input_path) as img:
		img = img.convert("RGB")
		contrast = ImageEnhance.Contrast(img).enhance(1.2)
		sharp = ImageEnhance.Sharpness(contrast).enhance(1.1)
		bright = ImageEnhance.Brightness(sharp).enhance(1.05)
		bright.save(output_path, format="JPEG", quality=90)


def _put_metadata(table, image_id: str, user_id: str, status: str, source_bucket: str, source_key: str, enhanced_bucket: str, enhanced_key: str) -> None:
	item = {
		"ImageId": image_id,
		"UserId": user_id,
		"Timestamp": _iso_now(),
		"Status": status,
		"SourceBucket": source_bucket,
		"SourceKey": source_key,
		"EnhancedBucket": enhanced_bucket,
		"EnhancedKey": enhanced_key,
	}
	table.put_item(Item=item)


def _publish_sns(topic_arn: str, message: str, subject: str = "Image Enhanced") -> None:
	if not topic_arn:
		return
	sns_client.publish(TopicArn=topic_arn, Message=message, Subject=subject)


def lambda_handler(event, context):
	if not (TABLE_NAME and TARGET_BUCKET_NAME):
		raise RuntimeError("Environment variables TABLE_NAME and TARGET_BUCKET_NAME must be set")

	table = dynamodb.Table(TABLE_NAME)

	records = event.get("Records", [])
	results = []
	for record in records:
		# Handle S3 Put event
		s3_info = record.get("s3", {})
		source_bucket = s3_info.get("bucket", {}).get("name")
		source_key = s3_info.get("object", {}).get("key")
		if not source_bucket or not source_key:
			continue

		# Avoid infinite loops if we also process enhanced objects
		if source_key.startswith(ENHANCED_PREFIX):
			continue

		# Decide target bucket and key
		target_bucket = TARGET_BUCKET_NAME
		enhanced_key = f"{ENHANCED_PREFIX}{source_key}"

		# Download original to /tmp
		file_ext = os.path.splitext(source_key)[1] or ".jpg"
		local_original = os.path.join(tempfile.gettempdir(), f"orig_{uuid.uuid4()}{file_ext}")
		local_enhanced = os.path.join(tempfile.gettempdir(), f"enh_{uuid.uuid4()}.jpg")

		try:
			# First check if the object exists
			try:
				s3_client.head_object(Bucket=source_bucket, Key=source_key)
			except ClientError as e:
				if e.response['Error']['Code'] == '404':
					print(f"Object not found: s3://{source_bucket}/{source_key}")
					# Store not found metadata
					image_id = source_key
					user_id = record.get("userIdentity", {}).get("principalId", "anonymous")
					_put_metadata(
						table=table,
						image_id=image_id,
						user_id=user_id,
						status="NOT_FOUND",
						source_bucket=source_bucket,
						source_key=source_key,
						enhanced_bucket="",
						enhanced_key="",
					)
					continue  # Skip to next record
				else:
					raise  # Re-raise if it's not a 404 error
					
			s3_client.download_file(source_bucket, source_key, local_original)
			_enhance_image(local_original, local_enhanced)
			s3_client.upload_file(local_enhanced, target_bucket, enhanced_key, ExtraArgs={"ContentType": "image/jpeg"})

			# Create item metadata
			image_id = source_key
			user_id = record.get("userIdentity", {}).get("principalId", "anonymous")
			_put_metadata(
				table=table,
				image_id=image_id,
				user_id=user_id,
				status="ENHANCED",
				source_bucket=source_bucket,
				source_key=source_key,
				enhanced_bucket=target_bucket,
				enhanced_key=enhanced_key,
			)

			# Notify via SNS
			message = json.dumps(
				{
					"status": "ENHANCED",
					"enhanced_image": {
						"bucket": target_bucket,
						"key": enhanced_key,
					},
					"source_image": {
						"bucket": source_bucket,
						"key": source_key,
					},
				}
			)
			_publish_sns(SNS_TOPIC_ARN, message)

			results.append({"source": f"s3://{source_bucket}/{source_key}", "enhanced": f"s3://{target_bucket}/{enhanced_key}"})
		except ClientError as e:
			# Store failure metadata
			image_id = source_key
			user_id = record.get("userIdentity", {}).get("principalId", "anonymous")
			_put_metadata(
				table=table,
				image_id=image_id,
				user_id=user_id,
				status="FAILED",
				source_bucket=source_bucket,
				source_key=source_key,
				enhanced_bucket="",
				enhanced_key="",
			)
			print(f"Error processing {source_bucket}/{source_key}: {str(e)}")
			# Don't re-raise the exception to allow processing of other records
		finally:
			for p in (local_original, local_enhanced):
				try:
					if p and os.path.exists(p):
						os.remove(p)
				except Exception:
					pass

	return {
		"statusCode": 200,
		"body": json.dumps({"processed": results}),
	}
