from celery import Celery
import boto3
import os
from datetime import datetime
import uuid

# Initialize Celery app
celery_app = Celery('tasks', broker=os.environ.get('CELERY_BROKER_URL', 'redis://localhost:6379/0'))

# Initialize AWS clients
dynamodb = boto3.resource('dynamodb', region_name=os.environ.get('AWS_REGION', 'us-east-1'))
table = dynamodb.Table(os.environ.get('DYNAMODB_TABLE_NAME', 'ImageMetadata'))

@celery_app.task
def process_sqs_message(message_body: dict):
    try:
        # Extract metadata from SQS message (example structure)
        s3_event = message_body.get('Records')[0].get('s3')
        bucket_name = s3_event.get('bucket').get('name')
        object_key = s3_event.get('object').get('key')

        # Get object details from S3 (optional, but good for comprehensive metadata)
        s3_client = boto3.client('s3', region_name=os.environ.get('AWS_REGION', 'us-east-1'))
        s3_object = s3_client.head_object(Bucket=bucket_name, Key=object_key)

        metadata = {
            'ImageId': str(uuid.uuid4()), # Generate a unique ID for DynamoDB
            'FileName': object_key,
            'Bucket': bucket_name,
            'UploadTime': datetime.utcnow().isoformat(),
            'ContentType': s3_object['ContentType'],
            'Size': s3_object['ContentLength'],
        }

        table.put_item(Item=metadata)
        print(f"Successfully processed and stored metadata for {object_key}")
    except Exception as e:
        print(f"Error processing SQS message: {e}")

