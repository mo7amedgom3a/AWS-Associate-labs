from fastapi import FastAPI, HTTPException, Depends
from mangum import Mangum
from sqlalchemy.orm import Session
from typing import List, Optional
import os
import uuid

from app.database import get_db, init_db
from app.models import Product
from app.schemas import ProductCreate, ProductResponse, ProductUpdate

app = FastAPI(title="Products API")

@app.on_event("startup")
async def startup():
    init_db()

@app.get("/products", response_model=List[ProductResponse])
def get_products(
    skip: int = 0, 
    limit: int = 100, 
    active_only: bool = False,
    db: Session = Depends(get_db)
):
    """
    Get all products with pagination
    """
    query = db.query(Product)
    if active_only:
        query = query.filter(Product.is_active == True)
    products = query.offset(skip).limit(limit).all()
    return products

@app.post("/products", response_model=ProductResponse, status_code=201)
def create_product(
    product: ProductCreate, 
    db: Session = Depends(get_db)
):
    """
    Create a new product
    """
    # Check if product with the same SKU already exists
    existing_product = db.query(Product).filter(Product.sku == product.sku).first()
    if existing_product:
        raise HTTPException(status_code=400, detail="Product with this SKU already exists")
    
    # Create new product
    db_product = Product(
        product_id=str(uuid.uuid4()),
        sku=product.sku,
        name=product.name,
        description=product.description,
        price=product.price,
        stock_quantity=product.stock_quantity,
        is_active=product.is_active
    )
    
    db.add(db_product)
    db.commit()
    db.refresh(db_product)
    return db_product

@app.get("/products/{product_id}", response_model=ProductResponse)
def get_product(
    product_id: str, 
    db: Session = Depends(get_db)
):
    """
    Get a product by ID
    """
    product = db.query(Product).filter(Product.product_id == product_id).first()
    if not product:
        raise HTTPException(status_code=404, detail="Product not found")
    return product

@app.put("/products/{product_id}", response_model=ProductResponse)
def update_product(
    product_id: str, 
    product_update: ProductUpdate, 
    db: Session = Depends(get_db)
):
    """
    Update a product
    """
    db_product = db.query(Product).filter(Product.product_id == product_id).first()
    if not db_product:
        raise HTTPException(status_code=404, detail="Product not found")
    
    # Update product attributes
    update_data = product_update.dict(exclude_unset=True)
    for key, value in update_data.items():
        setattr(db_product, key, value)
    
    db.commit()
    db.refresh(db_product)
    return db_product

@app.delete("/products/{product_id}", status_code=204)
def delete_product(
    product_id: str, 
    db: Session = Depends(get_db)
):
    """
    Delete a product
    """
    db_product = db.query(Product).filter(Product.product_id == product_id).first()
    if not db_product:
        raise HTTPException(status_code=404, detail="Product not found")
    
    db.delete(db_product)
    db.commit()
    return None

# Lambda handler
handler = Mangum(app)
