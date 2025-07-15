import React from "react";

export default function CategoryList({ categories }) {
  if (!categories.length) return null;
  return (
    <div className="mt-6">
      <h2 className="text-sm font-semibold mb-2">Categories</h2>
      <div className="flex flex-wrap gap-2">
        {categories.map(cat => (
          <span
            key={cat.id}
            className="px-2 py-1 rounded text-xs"
            style={{ background: cat.color || "#eee" }}
          >
            {cat.icon ? <span className="mr-1">{cat.icon}</span> : null}
            {cat.name}
          </span>
        ))}
      </div>
    </div>
  );
}