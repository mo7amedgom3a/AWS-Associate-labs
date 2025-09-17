from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import List, Optional
from datetime import datetime
import boto3
import os

# Initialize FastAPI app
app = FastAPI()

# Initialize AWS clients
dynamodb = boto3.resource('dynamodb', region_name=os.environ.get('AWS_REGION', 'us-east-1'))
table = dynamodb.Table(os.environ.get('DYNAMODB_TABLE_NAME', 'ImageMetadata'))

# Pydantic model for image metadata
class ImageMetadata(BaseModel):
    ImageId: str
    FileName: str
    Bucket: str
    UploadTime: str
    ContentType: str
    Size: int

# API Endpoints
@app.get("/images", response_model=List[ImageMetadata])
async def list_images():
    try:
        response = table.scan()
        return response['Items']
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/image/{image_id}", response_model=ImageMetadata)
async def get_image_details(image_id: str):
    try:
        response = table.get_item(Key={'ImageId': image_id})
        item = response.get('Item')
        if not item:
            raise HTTPException(status_code=404, detail="Image not found")
        return item
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# Celery worker (simplified for demonstration)
# In a real application, Celery would run as a separate process
# and consume messages from SQS.

# This function would be called by a Celery task
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

# Example of how to manually trigger processing (for testing without SQS/Celery setup)
@app.post("/process-image-manual")
async def manual_process_image(message: dict):
    process_sqs_message(message)
    return {"message": "Manual processing initiated"}
