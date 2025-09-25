from pydantic import BaseModel, Field
from typing import List, Optional
from enum import Enum
from decimal import Decimal

class OrderStatus(str, Enum):
    PENDING = "PENDING"
    PROCESSING = "PROCESSING"
    SHIPPED = "SHIPPED"
    DELIVERED = "DELIVERED"
    CANCELLED = "CANCELLED"

class Address(BaseModel):
    street: str = Field(..., example="123 Serverless Way")
    city: str = Field(..., example="Cloud City")
    zip_code: str = Field(..., example="12345")
    country: str = Field(..., example="AWS")

class OrderItem(BaseModel):
    product_id: str = Field(..., example="prod_1a2b3c4d")
    quantity: int = Field(..., example=1, gt=0)
    price_per_unit: Decimal = Field(..., example=99.99, gt=0)

class OrderBase(BaseModel):
    customer_id: str = Field(..., example="cust_a7b8c9d0")
    shipping_address: Address
    items: List[OrderItem]

class OrderCreate(OrderBase):
    pass

class OrderUpdate(BaseModel):
    customer_id: str = Field(..., example="cust_a7b8c9d0")
    order_status: OrderStatus = Field(..., example=OrderStatus.SHIPPED)

class OrderResponse(OrderBase):
    order_id: str = Field(..., example="a1b2c3d4-e5f6-7890-1234-567890abcdef")
    order_date: str = Field(..., example="2025-09-21T10:30:00Z")
    order_status: OrderStatus = Field(..., example=OrderStatus.PENDING)
    total_amount: Decimal = Field(..., example=149.98)
