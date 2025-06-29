"use client";

import { useRouter } from "next/navigation";
import { useEffect } from "react";

export default function LoginPage() {
  const router = useRouter();

  // This component will now just act as a gate
  useEffect(() => {
    localStorage.setItem("authenticated", "true");
  }, []);

  const goToController = () => {
    router.push("/control");
  };

  return (
    <main className="flex min-h-screen flex-col items-center justify-center p-24 bg-gray-900 text-white">
      <div className="text-center">
        <h1 className="text-4xl font-bold mb-4">로그인 페이지 테스트</h1>
        <p className="mb-8">
          이 화면이 보인다면, 최신 코드가 로드된 것입니다.
        </p>
        <button
          onClick={goToController}
          className="px-8 py-4 bg-blue-600 hover:bg-blue-700 text-white font-bold rounded-lg text-xl"
        >
          컨트롤러 페이지로 바로가기
        </button>
      </div>
    </main>
  );
}
