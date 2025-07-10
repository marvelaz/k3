from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, and_, func
from sqlalchemy.orm import selectinload
from typing import List, Optional
from datetime import date
from app.database import get_db
from app.models import User, Expense, Category
from app.schemas import (
    ExpenseCreate, ExpenseUpdate, Expense as ExpenseSchema,
    ExpenseListResponse, PaginatedResponse
)
from app.dependencies import get_current_user

router = APIRouter()

@router.get("/", response_model=ExpenseListResponse)
async def get_expenses(
    page: int = Query(1, ge=1),
    limit: int = Query(20, ge=1, le=100),
    category_id: Optional[str] = None,
    start_date: Optional[date] = None,
    end_date: Optional[date] = None,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    # Build query conditions
    conditions = [Expense.user_id == current_user.id]
    
    if category_id:
        conditions.append(Expense.category_id == category_id)
    if start_date:
        conditions.append(Expense.expense_date >= start_date)
    if end_date:
        conditions.append(Expense.expense_date <= end_date)
    
    # Get total count
    count_result = await db.execute(
        select(func.count(Expense.id)).where(and_(*conditions))
    )
    total = count_result.scalar()
    
    # Get expenses with pagination
    offset = (page - 1) * limit
    result = await db.execute(
        select(Expense)
        .options(selectinload(Expense.category))
        .where(and_(*conditions))
        .order_by(Expense.expense_date.desc())
        .offset(offset)
        .limit(limit)
    )
    expenses = result.scalars().all()
    
    pages = (total + limit - 1) // limit
    
    return ExpenseListResponse(
        expenses=expenses,
        pagination=PaginatedResponse(
            page=page,
            limit=limit,
            total=total,
            pages=pages
        )
    )

@router.post("/", response_model=ExpenseSchema)
async def create_expense(
    expense: ExpenseCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    # Verify category belongs to user
    result = await db.execute(
        select(Category).where(
            Category.id == expense.category_id,
            Category.user_id == current_user.id
        )
    )
    if not result.scalar_one_or_none():
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Category not found"
        )
    
    db_expense = Expense(
        user_id=current_user.id,
        **expense.dict()
    )
    db.add(db_expense)
    await db.commit()
    await db.refresh(db_expense, ["category"])
    return db_expense

@router.get("/{expense_id}", response_model=ExpenseSchema)
async def get_expense(
    expense_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    result = await db.execute(
        select(Expense)
        .options(selectinload(Expense.category))
        .where(
            Expense.id == expense_id,
            Expense.user_id == current_user.id
        )
    )
    expense = result.scalar_one_or_none()
    
    if not expense:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Expense not found"
        )
    
    return expense

@router.put("/{expense_id}", response_model=ExpenseSchema)
async def update_expense(
    expense_id: str,
    expense: ExpenseUpdate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    result = await db.execute(
        select(Expense).where(
            Expense.id == expense_id,
            Expense.user_id == current_user.id
        )
    )
    db_expense = result.scalar_one_or_none()
    
    if not db_expense:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Expense not found"
        )
    
    # Verify category belongs to user if category is being updated
    if expense.category_id:
        cat_result = await db.execute(
            select(Category).where(
                Category.id == expense.category_id,
                Category.user_id == current_user.id
            )
        )
        if not cat_result.scalar_one_or_none():
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Category not found"
            )
    
    for field, value in expense.dict(exclude_unset=True).items():
        setattr(db_expense, field, value)
    
    await db.commit()
    await db.refresh(db_expense, ["category"])
    return db_expense

@router.delete("/{expense_id}")
async def delete_expense(
    expense_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    result = await db.execute(
        select(Expense).where(
            Expense.id == expense_id,
            Expense.user_id == current_user.id
        )
    )
    db_expense = result.scalar_one_or_none()
    
    if not db_expense:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Expense not found"
        )
    
    await db.delete(db_expense)
    await db.commit()
    return {"message": "Expense deleted"}