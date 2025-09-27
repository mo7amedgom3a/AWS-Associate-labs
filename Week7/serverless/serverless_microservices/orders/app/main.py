from fastapi import FastAPI, HTTPException, Depends
from mangum import Mangum
from typing import List, Optional
import os
import uuid
from datetime import datetime

from app.database import get_dynamodb_client, get_table_name
from app.schemas import OrderCreate, OrderResponse, OrderUpdate, OrderStatus

app = FastAPI(title="Orders API")
@app.get("/orders")
def get_orders():
    """
    Get all orders
    """
    print("Hello, World!")
    return {"message": "orders get"}

@app.post("/orders", response_model=OrderResponse, status_code=201)
def create_order(order: OrderCreate):
    """
    Create a new order
    """
    dynamodb = get_dynamodb_client()
    table_name = get_table_name()
    
    # Generate a new order ID
    order_id = str(uuid.uuid4())
    
    # Calculate total amount from items
    total_amount = sum(item.price_per_unit * item.quantity for item in order.items)
    
    # Current timestamp
    timestamp = datetime.utcnow().isoformat()
    
    # Create order item for DynamoDB
    order_item = {
        "order_id": order_id,
        "customer_id": order.customer_id,
        "order_date": timestamp,
        "order_status": OrderStatus.PENDING.value,
        "total_amount": total_amount,
        "shipping_address": {
            "street": order.shipping_address.street,
            "city": order.shipping_address.city,
            "zip_code": order.shipping_address.zip_code,
            "country": order.shipping_address.country
        },
        "items": [
            {
                "product_id": item.product_id,
                "quantity": item.quantity,
                "price_per_unit": item.price_per_unit
            } for item in order.items
        ]
    }
    
    # Put item in DynamoDB
    dynamodb.put_item(
        TableName=table_name,
        Item={
            "order_id": {"S": order_id},
            "customer_id": {"S": order.customer_id},
            "order_date": {"S": timestamp},
            "order_status": {"S": OrderStatus.PENDING.value},
            "total_amount": {"N": str(total_amount)},
            "shipping_address": {"M": {
                "street": {"S": order.shipping_address.street},
                "city": {"S": order.shipping_address.city},
                "zip_code": {"S": order.shipping_address.zip_code},
                "country": {"S": order.shipping_address.country}
            }},
            "items": {"L": [
                {"M": {
                    "product_id": {"S": item.product_id},
                    "quantity": {"N": str(item.quantity)},
                    "price_per_unit": {"N": str(item.price_per_unit)}
                }} for item in order.items
            ]}
        }
    )
    
    # Return the created order
    return OrderResponse(
        order_id=order_id,
        customer_id=order.customer_id,
        order_date=timestamp,
        order_status=OrderStatus.PENDING,
        total_amount=total_amount,
        shipping_address=order.shipping_address,
        items=order.items
    )

@app.get("/orders/{order_id}", response_model=OrderResponse)
def get_order(order_id: str, customer_id: str):
    """
    Get an order by ID and customer ID
    """
    dynamodb = get_dynamodb_client()
    table_name = get_table_name()
    
    # Get item from DynamoDB
    response = dynamodb.get_item(
        TableName=table_name,
        Key={
            "order_id": {"S": order_id},
            "customer_id": {"S": customer_id}
        }
    )
    
    # Check if item exists
    if "Item" not in response:
        raise HTTPException(status_code=404, detail="Order not found")
    
    # Parse DynamoDB response
    item = response["Item"]
    
    return OrderResponse(
        order_id=item["order_id"]["S"],
        customer_id=item["customer_id"]["S"],
        order_date=item["order_date"]["S"],
        order_status=OrderStatus(item["order_status"]["S"]),
        total_amount=float(item["total_amount"]["N"]),
        shipping_address={
            "street": item["shipping_address"]["M"]["street"]["S"],
            "city": item["shipping_address"]["M"]["city"]["S"],
            "zip_code": item["shipping_address"]["M"]["zip_code"]["S"],
            "country": item["shipping_address"]["M"]["country"]["S"]
        },
        items=[
            {
                "product_id": i["M"]["product_id"]["S"],
                "quantity": int(i["M"]["quantity"]["N"]),
                "price_per_unit": float(i["M"]["price_per_unit"]["N"])
            } for i in item["items"]["L"]
        ]
    )

@app.get("/customers/{customer_id}/orders", response_model=List[OrderResponse])
def get_customer_orders(customer_id: str):
    """
    Get all orders for a customer
    """
    dynamodb = get_dynamodb_client()
    table_name = get_table_name()
    
    # Query DynamoDB
    response = dynamodb.query(
        TableName=table_name,
        KeyConditionExpression="customer_id = :customer_id",
        ExpressionAttributeValues={
            ":customer_id": {"S": customer_id}
        }
    )
    
    # Parse DynamoDB response
    orders = []
    for item in response.get("Items", []):
        orders.append(OrderResponse(
            order_id=item["order_id"]["S"],
            customer_id=item["customer_id"]["S"],
            order_date=item["order_date"]["S"],
            order_status=OrderStatus(item["order_status"]["S"]),
            total_amount=float(item["total_amount"]["N"]),
            shipping_address={
                "street": item["shipping_address"]["M"]["street"]["S"],
                "city": item["shipping_address"]["M"]["city"]["S"],
                "zip_code": item["shipping_address"]["M"]["zip_code"]["S"],
                "country": item["shipping_address"]["M"]["country"]["S"]
            },
            items=[
                {
                    "product_id": i["M"]["product_id"]["S"],
                    "quantity": int(i["M"]["quantity"]["N"]),
                    "price_per_unit": float(i["M"]["price_per_unit"]["N"])
                } for i in item["items"]["L"]
            ]
        ))
    
    return orders

@app.put("/orders/{order_id}", response_model=OrderResponse)
def update_order_status(order_id: str, order_update: OrderUpdate):
    """
    Update an order's status
    """
    dynamodb = get_dynamodb_client()
    table_name = get_table_name()
    
    # Get item from DynamoDB to check if it exists
    response = dynamodb.get_item(
        TableName=table_name,
        Key={
            "order_id": {"S": order_id},
            "customer_id": {"S": order_update.customer_id}
        }
    )
    
    # Check if item exists
    if "Item" not in response:
        raise HTTPException(status_code=404, detail="Order not found")
    
    # Update item in DynamoDB
    response = dynamodb.update_item(
        TableName=table_name,
        Key={
            "order_id": {"S": order_id},
            "customer_id": {"S": order_update.customer_id}
        },
        UpdateExpression="SET order_status = :order_status",
        ExpressionAttributeValues={
            ":order_status": {"S": order_update.order_status.value}
        },
        ReturnValues="ALL_NEW"
    )
    
    # Parse DynamoDB response
    item = response["Attributes"]
    
    return OrderResponse(
        order_id=item["order_id"]["S"],
        customer_id=item["customer_id"]["S"],
        order_date=item["order_date"]["S"],
        order_status=OrderStatus(item["order_status"]["S"]),
        total_amount=float(item["total_amount"]["N"]),
        shipping_address={
            "street": item["shipping_address"]["M"]["street"]["S"],
            "city": item["shipping_address"]["M"]["city"]["S"],
            "zip_code": item["shipping_address"]["M"]["zip_code"]["S"],
            "country": item["shipping_address"]["M"]["country"]["S"]
        },
        items=[
            {
                "product_id": i["M"]["product_id"]["S"],
                "quantity": int(i["M"]["quantity"]["N"]),
                "price_per_unit": float(i["M"]["price_per_unit"]["N"])
            } for i in item["items"]["L"]
        ]
    )

# Lambda handler
handler = Mangum(app)
