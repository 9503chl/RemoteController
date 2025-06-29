"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";

export default function LoginPage() {
  const [pin, setPin] = useState("");
  const [error, setError] = useState("");
  const router = useRouter();

  const handleLogin = async () => {
    setError("");
    try {
      const response = await fetch("http://127.0.0.1:8000/login", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({ pin }),
      });

      if (response.ok) {
    router.push("/control");
      } else {
        const data = await response.json();
        setError(data.error || "Invalid PIN.");
      }
    } catch (err) {
      setError("Failed to connect to the server. Is it running?");
      console.error(err);
    }
  };

  return (
    <main className="flex min-h-screen flex-col items-center justify-center bg-gray-100 p-8">
      <div className="w-full max-w-xs rounded-lg bg-white p-8 shadow-md">
        <div className="mb-8 text-center">
          <h1 className="text-2xl font-bold text-red-600">WEB Controller</h1>
          <p className="text-sm text-gray-500">DLC 웹 컨트롤러 v1.0</p>
        </div>
        <div className="mb-4">
          <label htmlFor="pin" className="mb-2 block text-sm font-bold text-gray-700">
            PIN
          </label>
          <input
            type="password"
            id="pin"
            value={pin}
            onChange={(e) => setPin(e.target.value)}
            onKeyPress={(e) => e.key === 'Enter' && handleLogin()}
            className="focus:shadow-outline w-full appearance-none rounded border px-3 py-2 leading-tight text-gray-700 shadow focus:outline-none"
            placeholder="Enter PIN"
          />
        </div>
        {error && <p className="mb-4 text-xs italic text-red-500">{error}</p>}
        <button
          onClick={handleLogin}
          className="focus:shadow-outline w-full rounded bg-black px-4 py-2 font-bold text-white hover:bg-gray-800 focus:outline-none"
        >
          Login
        </button>
      </div>
    </main>
  );
}
