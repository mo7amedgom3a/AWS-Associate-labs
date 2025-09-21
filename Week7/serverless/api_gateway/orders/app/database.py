import boto3
import os
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Get table name from environment variable
DYNAMODB_TABLE = os.getenv("DYNAMODB_TABLE", "orders")

def get_dynamodb_client():
    """
    Get DynamoDB client
    """
    return boto3.client('dynamodb')

def get_table_name():
    """
    Get DynamoDB table name
    """
    return DYNAMODB_TABLE
