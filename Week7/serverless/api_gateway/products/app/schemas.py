from pydantic import BaseModel, Field, validator
from typing import Optional
from decimal import Decimal
from datetime import datetime

class ProductBase(BaseModel):
    sku: str = Field(..., description="Stock Keeping Unit", example="PROD-12345")
    name: str = Field(..., description="Product name", example="Wireless Headphones")
    description: Optional[str] = Field(None, description="Product description", example="High-quality wireless headphones with noise cancellation")
    price: Decimal = Field(..., description="Product price", example=99.99, ge=0)
    stock_quantity: int = Field(0, description="Available stock quantity", example=100, ge=0)
    is_active: bool = Field(True, description="Whether the product is active")

class ProductCreate(ProductBase):
    pass

class ProductUpdate(BaseModel):
    sku: Optional[str] = None
    name: Optional[str] = None
    description: Optional[str] = None
    price: Optional[Decimal] = None
    stock_quantity: Optional[int] = None
    is_active: Optional[bool] = None

    @validator('price')
    def price_must_be_positive(cls, v):
        if v is not None and v < 0:
            raise ValueError('Price must be greater than or equal to zero')
        return v

    @validator('stock_quantity')
    def stock_must_be_positive(cls, v):
        if v is not None and v < 0:
            raise ValueError('Stock quantity must be greater than or equal to zero')
        return v

class ProductResponse(ProductBase):
    product_id: str
    created_at: datetime
    updated_at: datetime

    class Config:
        orm_mode = True
