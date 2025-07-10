from pydantic import BaseModel, EmailStr, validator
from typing import Optional, List
from datetime import datetime, date
from decimal import Decimal
import uuid

# User schemas
class UserBase(BaseModel):
    email: EmailStr
    first_name: str
    last_name: str

class UserCreate(UserBase):
    password: str
    
    @validator('password')
    def validate_password(cls, v):
        if len(v) < 8:
            raise ValueError('Password must be at least 8 characters long')
        return v

class UserLogin(BaseModel):
    email: EmailStr
    password: str

class User(UserBase):
    id: uuid.UUID
    created_at: datetime
    
    class Config:
        from_attributes = True

# Category schemas
class CategoryBase(BaseModel):
    name: str
    color: Optional[str] = "#6B7280"
    icon: Optional[str] = "receipt"

class CategoryCreate(CategoryBase):
    pass

class CategoryUpdate(CategoryBase):
    pass

class Category(CategoryBase):
    id: uuid.UUID
    user_id: uuid.UUID
    created_at: datetime
    
    class Config:
        from_attributes = True

# Expense schemas
class ExpenseBase(BaseModel):
    category_id: uuid.UUID
    amount: Decimal
    description: str
    expense_date: date
    receipt_url: Optional[str] = None
    tags: Optional[List[str]] = []
    
    @validator('amount')
    def validate_amount(cls, v):
        if v <= 0:
            raise ValueError('Amount must be positive')
        return v

class ExpenseCreate(ExpenseBase):
    pass

class ExpenseUpdate(ExpenseBase):
    pass

class Expense(ExpenseBase):
    id: uuid.UUID
    user_id: uuid.UUID
    category: Category
    created_at: datetime
    updated_at: datetime
    
    class Config:
        from_attributes = True

# Auth schemas
class Token(BaseModel):
    access_token: str
    token_type: str

class TokenData(BaseModel):
    email: Optional[str] = None

class UserResponse(BaseModel):
    user: User
    access_token: str
    token_type: str

# Pagination
class PaginationParams(BaseModel):
    page: int = 1
    limit: int = 20

class PaginatedResponse(BaseModel):
    page: int
    limit: int
    total: int
    pages: int

class ExpenseListResponse(BaseModel):
    expenses: List[Expense]
    pagination: PaginatedResponse

# Analytics schemas
class CategorySummary(BaseModel):
    category: Category
    total_amount: Decimal
    expense_count: int
    percentage: Decimal

class DailySummary(BaseModel):
    date: date
    total_amount: Decimal
    expense_count: int

class AnalyticsSummary(BaseModel):
    total_amount: Decimal
    expense_count: int
    average_per_day: Decimal
    by_category: List[CategorySummary]
    daily_totals: List[DailySummary]