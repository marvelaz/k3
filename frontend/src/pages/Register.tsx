import React, { useState } from "react";
import AuthForm from "../components/AuthForm";
import api from "../api/client";
import { useNavigate } from "react-router-dom";

export default function Register() {
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");
  const navigate = useNavigate();

  async function handleRegister(email: string, password: string) {
    setLoading(true);
    setError("");
    try {
      await api.post("/auth/register", {
        email,
        password,
        first_name: "User",
        last_name: "Test"
      });
      navigate("/login");
    } catch (e) {
      setError("Registration failed");
    } finally {
      setLoading(false);
    }
  }

  return (
    <div>
      <AuthForm onSubmit={handleRegister} loading={loading} title="Register" />
      {error && <div className="text-red-600 text-center mt-2">{error}</div>}
      <div className="text-center mt-4">
        <a href="/login" className="text-blue-600 underline">Back to login</a>
      </div>
    </div>
  );
}