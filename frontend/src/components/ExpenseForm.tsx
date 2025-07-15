import React, { useState } from "react";
import api from "../api/client";

export default function ExpenseForm({ categories, onCreated }) {
  const [amount, setAmount] = useState("");
  const [description, setDescription] = useState("");
  const [categoryId, setCategoryId] = useState(categories[0]?.id || "");
  const [date, setDate] = useState(new Date().toISOString().slice(0, 10));
  const [loading, setLoading] = useState(false);

  async function handleSubmit(e) {
    e.preventDefault();
    setLoading(true);
    try {
      const res = await api.post("/expenses", {
        category_id: categoryId,
        amount,
        description,
        expense_date: date,
        tags: [],
      });
      onCreated(res.data);
      setAmount("");
      setDescription("");
    } finally {
      setLoading(false);
    }
  }

  return (
    <form className="mb-4 space-y-2" onSubmit={handleSubmit}>
      <div className="flex gap-2">
        <input
          className="flex-1 border rounded px-2 py-1"
          type="number"
          min="0"
          step="0.01"
          placeholder="Amount"
          value={amount}
          onChange={e => setAmount(e.target.value)}
          required
        />
        <select
          className="border rounded px-2 py-1"
          value={categoryId}
          onChange={e => setCategoryId(e.target.value)}
        >
          {categories.map(cat => (
            <option key={cat.id} value={cat.id}>{cat.name}</option>
          ))}
        </select>
      </div>
      <input
        className="w-full border rounded px-2 py-1"
        type="text"
        placeholder="Description"
        value={description}
        onChange={e => setDescription(e.target.value)}
        required
      />
      <input
        className="w-full border rounded px-2 py-1"
        type="date"
        value={date}
        onChange={e => setDate(e.target.value)}
        required
      />
      <button
        className="w-full bg-green-600 text-white py-1 rounded"
        type="submit"
        disabled={loading}
      >
        {loading ? "Adding..." : "Add Expense"}
      </button>
    </form>
  );
}