# API Gateway Configuration for Serverless E-commerce

This document explains the API Gateway configuration and how to test the Lambda functions.

## API Gateway Routes

The API Gateway is configured with the following routes:

- `GET /` - Root endpoint that returns a welcome message
- `GET /products` - Get all products
- `GET /products/{product_id}` - Get a specific product
- `POST /products` - Create a new product
- `PUT /products/{product_id}` - Update a product
- `DELETE /products/{product_id}` - Delete a product
- `GET /orders` - Get all orders (requires customer_id query parameter)
- `POST /orders` - Create a new order
- `GET /orders/{order_id}` - Get a specific order (requires customer_id query parameter)
- `PUT /orders/{order_id}` - Update an order's status
- `GET /customers/{customer_id}/orders` - Get all orders for a customer

## Testing Lambda Functions

### Using AWS Console

1. Navigate to the Lambda function in AWS Console
2. Click on the "Test" tab
3. Create a new test event using one of the sample events in the `test_events` directory
4. Click "Test" to execute the function with the event

### Using AWS CLI

```bash
aws lambda invoke \
  --function-name serverless-ecommerce-dev-products-service \
  --payload file://test_events/products_get_test_event.json \
  --cli-binary-format raw-in-base64-out \
  response.json
```

```bash
aws lambda invoke \
  --function-name serverless-ecommerce-dev-orders-service \
  --payload file://test_events/orders_get_test_event.json \
  --cli-binary-format raw-in-base64-out \
  response.json
```

## Common Issues and Solutions

### 404 Not Found Error

If you're getting a 404 Not Found error when accessing the API endpoints:

1. Make sure the API Gateway routes are correctly configured
2. Verify that the Lambda functions are properly integrated with API Gateway
3. Check that the Lambda function permissions allow API Gateway to invoke them
4. Ensure you're using the correct API endpoint URL with the stage name (e.g., `/dev/products`)

### Lambda Function Errors

If the Lambda function returns an error:

1. Check the CloudWatch logs for the specific Lambda function
2. Verify that the function has the necessary permissions to access DynamoDB or RDS
3. Ensure the environment variables are correctly set
4. Test the function directly using the provided test events

## Applying Changes

After making changes to the Terraform configuration:

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

This will update the API Gateway configuration with the new routes and integrations.