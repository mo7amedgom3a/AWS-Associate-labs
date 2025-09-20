from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from mangum import Mangum

# FastAPI app
app = FastAPI(
    title="User Profile Service",
    description="A mock user profile service using FastAPI + Mangum",
    version="1.0.0",
)

# Mock DB
USERS = {}

# Request/Response Models
class User(BaseModel):
    id: str
    name: str
    email: str


@app.get("/users", response_model=list[User])
def list_users():
    return list(USERS.values())

# Create a profile
@app.post("/users", response_model=User)
def create_user(user: User):
    if user.id in USERS:
        raise HTTPException(status_code=400, detail="User already exists")
    USERS[user.id] = user.dict()
    return user

# Get a profile
@app.get("/users/{user_id}", response_model=User)
def get_user(user_id: str):
    user = USERS.get(user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return user

# Update a profile
@app.put("/users/{user_id}", response_model=User)
def update_user(user_id: str, user: User):
    if user_id not in USERS:
        raise HTTPException(status_code=404, detail="User not found")
    USERS[user_id] = user.dict()
    return user

# Delete a profile
@app.delete("/users/{user_id}")
def delete_user(user_id: str):
    if user_id not in USERS:
        raise HTTPException(status_code=404, detail="User not found")
    del USERS[user_id]
    return {"message": "User deleted"}

# Mangum adapter to handle API Gateway → Lambda
handler = Mangum(app)
