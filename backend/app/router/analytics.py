from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func, and_
from sqlalchemy.orm import selectinload
from typing import Optional
from datetime import date, timedelta
from decimal import Decimal
from app.database import get_db
from app.models import User, Expense, Category
from app.schemas import AnalyticsSummary, CategorySummary, DailySummary
from app.dependencies import get_current_user

router = APIRouter()

@router.get("/summary", response_model=AnalyticsSummary)
async def get_analytics_summary(
    start_date: Optional[date] = Query(None),
    end_date: Optional[date] = Query(None),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    # Default to last 30 days if no dates provided
    if not end_date:
        end_date = date.today()
    if not start_date:
        start_date = end_date - timedelta(days=30)
    
    # Build base conditions
    conditions = [
        Expense.user_id == current_user.id,
        Expense.expense_date >= start_date,
        Expense.expense_date <= end_date
    ]
    
    # Get total amount and count
    result = await db.execute(
        select(
            func.sum(Expense.amount).label('total_amount'),
            func.count(Expense.id).label('expense_count')
        ).where(and_(*conditions))
    )
    totals = result.first()
    
    total_amount = totals.total_amount or Decimal('0')
    expense_count = totals.expense_count or 0
    
    # Calculate average per day
    days_diff = (end_date - start_date).days + 1
    average_per_day = total_amount / days_diff if days_diff > 0 else Decimal('0')
    
    # Get expenses by category
    cat_result = await db.execute(
        select(
            Category,
            func.sum(Expense.amount).label('total_amount'),
            func.count(Expense.id).label('expense_count')
        )
        .join(Expense)
        .where(and_(*conditions))
        .group_by(Category.id)
        .order_by(func.sum(Expense.amount).desc())
    )
    
    by_category = []
    for row in cat_result:
        category, cat_total, cat_count = row
        percentage = (cat_total / total_amount * 100) if total_amount > 0 else Decimal('0')
        by_category.append(CategorySummary(
            category=category,
            total_amount=cat_total,
            expense_count=cat_count,
            percentage=percentage
        ))
    
    # Get daily totals
    daily_result = await db.execute(
        select(
            Expense.expense_date,
            func.sum(Expense.amount).label('total_amount'),
            func.count(Expense.id).label('expense_count')
        )
        .where(and_(*conditions))
        .group_by(Expense.expense_date)
        .order_by(Expense.expense_date)
    )
    
    daily_totals = [
        DailySummary(
            date=row.expense_date,
            total_amount=row.total_amount,
            expense_count=row.expense_count
        )
        for row in daily_result
    ]
    
    return AnalyticsSummary(
        total_amount=total_amount,
        expense_count=expense_count,
        average_per_day=average_per_day,
        by_category=by_category,
        daily_totals=daily_totals
    )