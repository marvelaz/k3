import React, { useState } from "react";
import AuthForm from "../components/AuthForm";
import api from "../api/client";
import { useNavigate } from "react-router-dom";

export default function Login() {
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");
  const navigate = useNavigate();

  async function handleLogin(email: string, password: string) {
    setLoading(true);
    setError("");
    try {
      const res = await api.post("/auth/login", { email, password });
      localStorage.setItem("access_token", res.data.access_token);
      navigate("/");
    } catch (e) {
      setError("Invalid credentials");
    } finally {
      setLoading(false);
    }
  }

  return (
    <div>
      <AuthForm onSubmit={handleLogin} loading={loading} title="Sign In" />
      {error && <div className="text-red-600 text-center mt-2">{error}</div>}
      <div className="text-center mt-4">
        <a href="/register" className="text-blue-600 underline">Create account</a>
      </div>
    </div>
  );
}