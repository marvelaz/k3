import React from "react";

export default function ExpenseList({ expenses }) {
  if (!expenses.length) return <div className="text-gray-500">No expenses yet.</div>;
  return (
    <ul className="divide-y">
      {expenses.map(exp => (
        <li key={exp.id} className="py-2 flex justify-between items-center">
          <div>
            <div className="font-medium">{exp.description}</div>
            <div className="text-xs text-gray-500">{exp.expense_date}</div>
          </div>
          <div className="text-right">
            <div className="text-green-700 font-bold">${exp.amount}</div>
            <div className="text-xs">{exp.category?.name}</div>
          </div>
        </li>
      ))}
    </ul>
  );
}