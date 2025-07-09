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
      const apiUrl = process.env.NODE_ENV === 'development' 
        ? '/api' 
        : process.env.NEXT_PUBLIC_API_URL;

      const response = await fetch(`${apiUrl}/login`, {
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
        setError(data.error || "잘못된 PIN 번호입니다.");
      }
    } catch (err) {
      setError("서버에 연결할 수 없습니다. 서버가 실행 중인지 확인해주세요.");
      console.error(err);
    }
  };

  return (
    <main className="flex min-h-screen flex-col items-center justify-center bg-gray-100 p-8">
      <div className="w-full max-w-xs rounded-lg bg-white p-8 shadow-md">
        <div className="mb-8 text-center">
          <h1 className="text-2xl font-bold text-red-600">웹 컨트롤러</h1>
          <p className="text-sm text-gray-500">Deep Live Cam 웹 컨트롤러 v1.0</p>
        </div>
        <div className="mb-4">
          <label htmlFor="pin" className="mb-2 block text-sm font-bold text-gray-700">
            PIN 번호
          </label>
          <input
            type="password"
            id="pin"
            value={pin}
            onChange={(e: React.ChangeEvent<HTMLInputElement>) => setPin(e.target.value)}
            onKeyPress={(e: React.KeyboardEvent<HTMLInputElement>) => e.key === 'Enter' && handleLogin()}
            className="focus:shadow-outline w-full appearance-none rounded border px-3 py-2 leading-tight text-gray-700 shadow focus:outline-none"
            placeholder="PIN 번호를 입력하세요"
          />
        </div>
        {error && <p className="mb-4 text-xs italic text-red-500">{error}</p>}
        <button
          onClick={handleLogin}
          className="focus:shadow-outline w-full rounded bg-black px-4 py-2 font-bold text-white hover:bg-gray-800 focus:outline-none"
        >
          로그인
        </button>
      </div>
    </main>
  );
}
