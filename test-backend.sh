#!/usr/bin/env python3
"""
Comprehensive test script for the Expense Tracker Backend API
Tests all endpoints including auth, users, categories, expenses, and analytics
"""

import requests
import json
import sys
from datetime import datetime, date, timedelta
from decimal import Decimal
import time

class ExpenseTrackerTester:
    def __init__(self, base_url="http://localhost:8000"):
        self.base_url = base_url
        self.api_url = f"{base_url}/api/v1"
        self.access_token = None
        self.headers = {"Content-Type": "application/json"}
        self.test_user = {
            "email": "test@example.com",
            "password": "TestPassword123",
            "first_name": "Test",
            "last_name": "User"
        }
        self.test_category_id = None
        self.test_expense_id = None
        
    def log(self, message, status="INFO"):
        timestamp = datetime.now().strftime("%H:%M:%S")
        print(f"[{timestamp}] {status}: {message}")
        
    def make_request(self, method, endpoint, data=None, auth=True):
        """Make HTTP request with proper headers and error handling"""
        url = f"{self.api_url}{endpoint}"
        headers = self.headers.copy()
        
        if auth and self.access_token:
            headers["Authorization"] = f"Bearer {self.access_token}"
            
        try:
            if method.upper() == "GET":
                response = requests.get(url, headers=headers, params=data)
            elif method.upper() == "POST":
                response = requests.post(url, headers=headers, json=data)
            elif method.upper() == "PUT":
                response = requests.put(url, headers=headers, json=data)
            elif method.upper() == "DELETE":
                response = requests.delete(url, headers=headers)
            else:
                raise ValueError(f"Unsupported HTTP method: {method}")
                
            return response
        except requests.exceptions.RequestException as e:
            self.log(f"Request failed: {e}", "ERROR")
            return None
    
    def test_health_check(self):
        """Test the health check endpoint"""
        self.log("Testing health check endpoint...")
        
        try:
            response = requests.get(f"{self.base_url}/health")
            if response.status_code == 200:
                self.log("✅ Health check passed", "SUCCESS")
                return True
            else:
                self.log(f"❌ Health check failed: {response.status_code}", "ERROR")
                return False
        except Exception as e:
            self.log(f"❌ Health check failed: {e}", "ERROR")
            return False
    
    def test_root_endpoint(self):
        """Test the root endpoint"""
        self.log("Testing root endpoint...")
        
        try:
            response = requests.get(self.base_url)
            if response.status_code == 200:
                data = response.json()
                self.log(f"✅ Root endpoint: {data.get('message', 'No message')}", "SUCCESS")
                return True
            else:
                self.log(f"❌ Root endpoint failed: {response.status_code}", "ERROR")
                return False
        except Exception as e:
            self.log(f"❌ Root endpoint failed: {e}", "ERROR")
            return False
    
    def test_user_registration(self):
        """Test user registration"""
        self.log("Testing user registration...")
        
        response = self.make_request("POST", "/auth/register", self.test_user, auth=False)
        
        if response and response.status_code == 200:
            data = response.json()
            self.access_token = data.get("access_token")
            user_data = data.get("user", {})
            self.log(f"✅ User registered: {user_data.get('email')}", "SUCCESS")
            self.log(f"   Token received: {self.access_token[:20]}...", "SUCCESS")
            return True
        elif response and response.status_code == 400:
            # User might already exist, try login instead
            self.log("User already exists, will try login", "INFO")
            return self.test_user_login()
        else:
            error_msg = response.json().get("detail", "Unknown error") if response else "No response"
            self.log(f"❌ Registration failed: {error_msg}", "ERROR")
            return False
    
    def test_user_login(self):
        """Test user login"""
        self.log("Testing user login...")
        
        login_data = {
            "email": self.test_user["email"],
            "password": self.test_user["password"]
        }
        
        response = self.make_request("POST", "/auth/login", login_data, auth=False)
        
        if response and response.status_code == 200:
            data = response.json()
            self.access_token = data.get("access_token")
            user_data = data.get("user", {})
            self.log(f"✅ User logged in: {user_data.get('email')}", "SUCCESS")
            self.log(f"   Token received: {self.access_token[:20]}...", "SUCCESS")
            return True
        else:
            error_msg = response.json().get("detail", "Unknown error") if response else "No response"
            self.log(f"❌ Login failed: {error_msg}", "ERROR")
            return False
    
    def test_get_current_user(self):
        """Test getting current user info"""
        self.log("Testing get current user...")
        
        response = self.make_request("GET", "/users/me")
        
        if response and response.status_code == 200:
            user_data = response.json()
            self.log(f"✅ Current user: {user_data.get('email')}", "SUCCESS")
            return True
        else:
            error_msg = response.json().get("detail", "Unknown error") if response else "No response"
            self.log(f"❌ Get current user failed: {error_msg}", "ERROR")
            return False
    
    def test_create_category(self):
        """Test creating a category"""
        self.log("Testing category creation...")
        
        category_data = {
            "name": "Test Food",
            "color": "#FF5733",
            "icon": "utensils"
        }
        
        response = self.make_request("POST", "/categories", category_data)
        
        if response and response.status_code == 200:
            data = response.json()
            self.test_category_id = data.get("id")
            self.log(f"✅ Category created: {data.get('name')} (ID: {self.test_category_id})", "SUCCESS")
            return True
        else:
            error_msg = response.json().get("detail", "Unknown error") if response else "No response"
            self.log(f"❌ Category creation failed: {error_msg}", "ERROR")
            return False
    
    def test_get_categories(self):
        """Test getting categories"""
        self.log("Testing get categories...")
        
        response = self.make_request("GET", "/categories")
        
        if response and response.status_code == 200:
            categories = response.json()
            self.log(f"✅ Retrieved {len(categories)} categories", "SUCCESS")
            for cat in categories:
                self.log(f"   - {cat.get('name')} ({cat.get('color')})", "INFO")
            return True
        else:
            error_msg = response.json().get("detail", "Unknown error") if response else "No response"
            self.log(f"❌ Get categories failed: {error_msg}", "ERROR")
            return False
    
    def test_create_expense(self):
        """Test creating an expense"""
        self.log("Testing expense creation...")
        
        if not self.test_category_id:
            self.log("❌ No category ID available for expense creation", "ERROR")
            return False
        
        expense_data = {
            "category_id": self.test_category_id,
            "amount": "25.50",
            "description": "Test lunch at restaurant",
            "expense_date": date.today().isoformat(),
            "tags": ["lunch", "restaurant", "test"]
        }
        
        response = self.make_request("POST", "/expenses", expense_data)
        
        if response and response.status_code == 200:
            data = response.json()
            self.test_expense_id = data.get("id")
            self.log(f"✅ Expense created: ${data.get('amount')} - {data.get('description')}", "SUCCESS")
            self.log(f"   ID: {self.test_expense_id}", "SUCCESS")
            return True
        else:
            error_msg = response.json().get("detail", "Unknown error") if response else "No response"
            self.log(f"❌ Expense creation failed: {error_msg}", "ERROR")
            return False
    
    def test_get_expenses(self):
        """Test getting expenses with pagination"""
        self.log("Testing get expenses...")
        
        # Test basic get
        response = self.make_request("GET", "/expenses")
        
        if response and response.status_code == 200:
            data = response.json()
            expenses = data.get("expenses", [])
            pagination = data.get("pagination", {})
            
            self.log(f"✅ Retrieved {len(expenses)} expenses", "SUCCESS")
            self.log(f"   Pagination: page {pagination.get('page')}/{pagination.get('pages')}, total: {pagination.get('total')}", "INFO")
            
            for expense in expenses[:3]:  # Show first 3
                self.log(f"   - ${expense.get('amount')} - {expense.get('description')}", "INFO")
            
            return True
        else:
            error_msg = response.json().get("detail", "Unknown error") if response else "No response"
            self.log(f"❌ Get expenses failed: {error_msg}", "ERROR")
            return False
    
    def test_get_expense_by_id(self):
        """Test getting a specific expense"""
        self.log("Testing get expense by ID...")
        
        if not self.test_expense_id:
            self.log("❌ No expense ID available", "ERROR")
            return False
        
        response = self.make_request("GET", f"/expenses/{self.test_expense_id}")
        
        if response and response.status_code == 200:
            data = response.json()
            self.log(f"✅ Retrieved expense: ${data.get('amount')} - {data.get('description')}", "SUCCESS")
            return True
        else:
            error_msg = response.json().get("detail", "Unknown error") if response else "No response"
            self.log(f"❌ Get expense by ID failed: {error_msg}", "ERROR")
            return False
    
    def test_update_expense(self):
        """Test updating an expense"""
        self.log("Testing expense update...")
        
        if not self.test_expense_id:
            self.log("❌ No expense ID available", "ERROR")
            return False
        
        update_data = {
            "category_id": self.test_category_id,
            "amount": "30.75",
            "description": "Updated test lunch at restaurant",
            "expense_date": date.today().isoformat(),
            "tags": ["lunch", "restaurant", "test", "updated"]
        }
        
        response = self.make_request("PUT", f"/expenses/{self.test_expense_id}", update_data)
        
        if response and response.status_code == 200:
            data = response.json()
            self.log(f"✅ Expense updated: ${data.get('amount')} - {data.get('description')}", "SUCCESS")
            return True
        else:
            error_msg = response.json().get("detail", "Unknown error") if response else "No response"
            self.log(f"❌ Expense update failed: {error_msg}", "ERROR")
            return False
    
    def test_analytics_summary(self):
        """Test analytics summary endpoint"""
        self.log("Testing analytics summary...")
        
        # Test with date range
        end_date = date.today()
        start_date = end_date - timedelta(days=30)
        
        params = {
            "start_date": start_date.isoformat(),
            "end_date": end_date.isoformat()
        }
        
        response = self.make_request("GET", "/analytics/summary", params)
        
        if response and response.status_code == 200:
            data = response.json()
            self.log(f"✅ Analytics summary retrieved", "SUCCESS")
            self.log(f"   Total amount: ${data.get('total_amount', 0)}", "INFO")
            self.log(f"   Expense count: {data.get('expense_count', 0)}", "INFO")
            self.log(f"   Average per day: ${data.get('average_per_day', 0)}", "INFO")
            self.log(f"   Categories: {len(data.get('by_category', []))}", "INFO")
            self.log(f"   Daily entries: {len(data.get('daily_totals', []))}", "INFO")
            return True
        else:
            error_msg = response.json().get("detail", "Unknown error") if response else "No response"
            self.log(f"❌ Analytics summary failed: {error_msg}", "ERROR")
            return False
    
    def test_delete_expense(self):
        """Test deleting an expense"""
        self.log("Testing expense deletion...")
        
        if not self.test_expense_id:
            self.log("❌ No expense ID available", "ERROR")
            return False
        
        response = self.make_request("DELETE", f"/expenses/{self.test_expense_id}")
        
        if response and response.status_code == 200:
            data = response.json()
            self.log(f"✅ Expense deleted: {data.get('message')}", "SUCCESS")
            return True
        else:
            error_msg = response.json().get("detail", "Unknown error") if response else "No response"
            self.log(f"❌ Expense deletion failed: {error_msg}", "ERROR")
            return False
    
    def test_delete_category(self):
        """Test deleting a category"""
        self.log("Testing category deletion...")
        
        if not self.test_category_id:
            self.log("❌ No category ID available", "ERROR")
            return False
        
        response = self.make_request("DELETE", f"/categories/{self.test_category_id}")
        
        if response and response.status_code == 200:
            data = response.json()
            self.log(f"✅ Category deleted: {data.get('message')}", "SUCCESS")
            return True
        else:
            error_msg = response.json().get("detail", "Unknown error") if response else "No response"
            self.log(f"❌ Category deletion failed: {error_msg}", "ERROR")
            return False
    
    def run_all_tests(self):
        """Run all tests in sequence"""
        self.log("=" * 60)
        self.log("Starting Expense Tracker Backend API Tests")
        self.log("=" * 60)
        
        tests = [
            ("Health Check", self.test_health_check),
            ("Root Endpoint", self.test_root_endpoint),
            ("User Registration/Login", self.test_user_registration),
            ("Get Current User", self.test_get_current_user),
            ("Create Category", self.test_create_category),
            ("Get Categories", self.test_get_categories),
            ("Create Expense", self.test_create_expense),
            ("Get Expenses", self.test_get_expenses),
            ("Get Expense by ID", self.test_get_expense_by_id),
            ("Update Expense", self.test_update_expense),
            ("Analytics Summary", self.test_analytics_summary),
            ("Delete Expense", self.test_delete_expense),
            ("Delete Category", self.test_delete_category),
        ]
        
        passed = 0
        failed = 0
        
        for test_name, test_func in tests:
            self.log(f"\n--- Running: {test_name} ---")
            try:
                if test_func():
                    passed += 1
                else:
                    failed += 1
            except Exception as e:
                self.log(f"❌ Test '{test_name}' crashed: {e}", "ERROR")
                failed += 1
            
            # Small delay between tests
            time.sleep(0.5)
        
        # Summary
        self.log("\n" + "=" * 60)
        self.log("TEST SUMMARY")
        self.log("=" * 60)
        self.log(f"✅ Passed: {passed}")
        self.log(f"❌ Failed: {failed}")
        self.log(f"📊 Total: {passed + failed}")
        
        if failed == 0:
            self.log("🎉 All tests passed!", "SUCCESS")
            return True
        else:
            self.log(f"💥 {failed} test(s) failed", "ERROR")
            return False

def main():
    """Main function to run tests"""
    import argparse
    
    parser = argparse.ArgumentParser(description="Test Expense Tracker Backend API")
    parser.add_argument(
        "--url", 
        default="http://localhost:8000",
        help="Base URL of the API (default: http://localhost:8000)"
    )
    parser.add_argument(
        "--wait",
        type=int,
        default=0,
        help="Wait N seconds before starting tests (useful for startup delays)"
    )
    
    args = parser.parse_args()
    
    if args.wait > 0:
        print(f"Waiting {args.wait} seconds before starting tests...")
        time.sleep(args.wait)
    
    tester = ExpenseTrackerTester(args.url)
    success = tester.run_all_tests()
    
    sys.exit(0 if success else 1)

if __name__ == "__main__":
    main()