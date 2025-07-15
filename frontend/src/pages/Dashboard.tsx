import React, { useEffect, useState } from "react";
import api from "../api/client";
import ExpenseList from "../components/ExpenseList";
import ExpenseForm from "../components/ExpenseForm";
import CategoryList from "../components/CategoryList";
import { useNavigate } from "react-router-dom";

export default function Dashboard() {
  const [expenses, setExpenses] = useState([]);
  const [categories, setCategories] = useState([]);
  const [loading, setLoading] = useState(true);
  const navigate = useNavigate();

  useEffect(() => {
    async function fetchData() {
      try {
        const [expRes, catRes] = await Promise.all([
          api.get("/expenses"),
          api.get("/categories"),
        ]);
        setExpenses(expRes.data.expenses || []);
        setCategories(catRes.data || []);
      } catch (e) {
        if (e.response?.status === 401) {
          localStorage.removeItem("access_token");
          navigate("/login");
        }
      } finally {
        setLoading(false);
      }
    }
    fetchData();
  }, [navigate]);

  if (loading) return <div className="text-center mt-12">Loading...</div>;

  return (
    <div className="max-w-lg mx-auto p-4">
      <h1 className="text-xl font-bold mb-4">My Expenses</h1>
      <ExpenseForm categories={categories} onCreated={exp => setExpenses([exp, ...expenses])} />
      <ExpenseList expenses={expenses} />
      <CategoryList categories={categories} />
    </div>
  );
}