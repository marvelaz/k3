import React, { useState } from "react";

type Props = {
  onSubmit: (email: string, password: string) => void;
  loading?: boolean;
  title: string;
};

export default function AuthForm({ onSubmit, loading, title }: Props) {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");

  return (
    <form
      className="max-w-xs mx-auto mt-12 p-6 bg-white rounded shadow space-y-4"
      onSubmit={e => {
        e.preventDefault();
        onSubmit(email, password);
      }}
    >
      <h1 className="text-2xl font-bold text-center">{title}</h1>
      <input
        className="w-full border rounded px-3 py-2"
        type="email"
        placeholder="Email"
        autoComplete="username"
        value={email}
        onChange={e => setEmail(e.target.value)}
        required
      />
      <input
        className="w-full border rounded px-3 py-2"
        type="password"
        placeholder="Password"
        autoComplete="current-password"
        value={password}
        onChange={e => setPassword(e.target.value)}
        required
      />
      <button
        className="w-full bg-blue-600 text-white py-2 rounded hover:bg-blue-700 transition"
        type="submit"
        disabled={loading}
      >
        {loading ? "Loading..." : title}
      </button>
    </form>
  );
}