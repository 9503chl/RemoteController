"use client";

import { useState, useEffect, useRef } from "react";
import { useRouter } from "next/navigation";
import Image from "next/image";

const API_URL = process.env.NEXT_PUBLIC_API_URL || "http://localhost:8000";

export default function ControllerPage() {
  const router = useRouter();
  const videoRef = useRef<HTMLVideoElement>(null);
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const [sourceFace, setSourceFace] = useState<File | null>(null);
  const [processedImage, setProcessedImage] = useState<string | null>(null);
  const [isProcessing, setIsProcessing] = useState(false);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [mouthMask, setMouthMask] = useState(false);
  const [isSourceSet, setIsSourceSet] = useState(false);
  const processedImageUrlRef = useRef<string | null>(null);
  
  // Authenticate and start webcam
  useEffect(() => {
    if (localStorage.getItem("authenticated") !== "true") {
      router.push("/");
      return;
    }
    
    const startWebcam = async () => {
      try {
        const stream = await navigator.mediaDevices.getUserMedia({ video: true });
        if (videoRef.current) {
          videoRef.current.srcObject = stream;
        }
      } catch (e) {
        console.error("Failed to start webcam:", e);
        setError("웹캠을 시작할 수 없습니다. 권한을 확인해주세요.");
      }
    };
    startWebcam();

    const currentVideoRef = videoRef.current;
    return () => {
        // Cleanup: Stop webcam stream when component unmounts
        if (currentVideoRef && currentVideoRef.srcObject) {
            const stream = currentVideoRef.srcObject as MediaStream;
            stream.getTracks().forEach(track => track.stop());
        }
    }
  }, [router]);

  // Main processing loop
  useEffect(() => {
    let animationFrameId: number;

    const processFrame = async () => {
      if (!videoRef.current || !canvasRef.current) return;

      const video = videoRef.current;
      const canvas = canvasRef.current;
      canvas.width = video.videoWidth;
      canvas.height = video.videoHeight;
      const context = canvas.getContext("2d");
      
      if (!context) return;

      context.drawImage(video, 0, 0, canvas.width, canvas.height);
      canvas.toBlob(async (blob) => {
        if (!blob) {
           // Continue loop even if blob creation fails
          if(isProcessing) animationFrameId = requestAnimationFrame(processFrame);
          return;
        }

        const formData = new FormData();
        formData.append('frame', blob, 'frame.jpg');

        try {
          const response = await fetch(`${API_URL}/process_frame`, {
            method: 'POST',
            body: formData,
          });

          if (!response.ok) {
            throw new Error('프레임 처리 실패');
          }

          const imageBlob = await response.blob();
          
          if (processedImageUrlRef.current) {
            URL.revokeObjectURL(processedImageUrlRef.current);
          }

          const newImageUrl = URL.createObjectURL(imageBlob);
          setProcessedImage(newImageUrl);
          processedImageUrlRef.current = newImageUrl;

        } catch (error) {
          console.error(error);
        } finally {
          if (isProcessing) {
            animationFrameId = requestAnimationFrame(processFrame);
          }
        }
      }, 'image/jpeg');
    };

    if (isProcessing) {
      animationFrameId = requestAnimationFrame(processFrame);
    }

    return () => {
      cancelAnimationFrame(animationFrameId);
      if (processedImageUrlRef.current) {
        URL.revokeObjectURL(processedImageUrlRef.current);
      }
    };
  }, [isProcessing]);
  
  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    setSourceFace(e.target.files?.[0] || null);
    setIsSourceSet(false); // Reset on new file selection
  }

  const handleSetSourceFace = async () => {
    if (!sourceFace) {
      setError("먼저 소스 얼굴 이미지를 선택하세요.");
      return;
    }
    setIsLoading(true);
    setError(null);
    const formData = new FormData();
    formData.append("source_face", sourceFace);
    formData.append("mouth_mask", String(mouthMask));

    try {
      const res = await fetch(`${API_URL}/set_source`, { method: "POST", body: formData });
      const data = await res.json();
      if (!res.ok) throw new Error(data.error || "소스 얼굴 설정에 실패했습니다.");
      alert("소스 얼굴이 성공적으로 설정되었습니다! AI 효과를 시작할 수 있습니다.");
      setIsSourceSet(true);
    } catch (e: unknown) {
      if (e instanceof Error) setError(e.message);
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <main className="flex min-h-screen flex-col items-center p-8 bg-gray-900 text-white">
      <h1 className="text-4xl font-bold mb-8">[v4 최종] AI 컨트롤러</h1>
      
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-8 w-full max-w-7xl">
        {/* Control Panel */}
        <div className="lg:col-span-1 bg-gray-800 p-6 rounded-lg shadow-xl flex flex-col gap-6">
          <div>
            <h2 className="text-xl font-semibold mb-3">1. 소스 얼굴 설정</h2>
            <div className="space-y-4">
              <input type="file" accept="image/*" onChange={handleFileChange}
                className="block w-full text-sm text-gray-400 file:mr-4 file:py-2 file:px-4 file:rounded-full file:border-0 file:text-sm file:font-semibold file:bg-blue-50 file:text-blue-700 hover:file:bg-blue-100"/>
              <div className="flex items-center">
                  <input id="mouth-mask-checkbox" type="checkbox" checked={mouthMask} onChange={(e) => setMouthMask(e.target.checked)} className="w-4 h-4 text-blue-600 bg-gray-700 border-gray-600 rounded focus:ring-blue-600 ring-offset-gray-800 focus:ring-2"/>
                  <label htmlFor="mouth-mask-checkbox" className="ms-2 text-sm font-medium text-gray-300">입 가리개 활성화</label>
              </div>
              <button onClick={handleSetSourceFace} disabled={!sourceFace || isLoading}
                className="w-full px-6 py-3 bg-blue-600 hover:bg-blue-700 text-white font-semibold rounded-lg shadow-md transition-colors disabled:bg-gray-500 disabled:cursor-not-allowed">
                {isLoading ? "설정 중..." : "소스 얼굴 전송 및 AI 초기화"}
              </button>
            </div>
          </div>
          <div>
            <h2 className="text-xl font-semibold mb-3">2. AI 효과 제어</h2>
            <button onClick={() => setIsProcessing(prev => !prev)} disabled={isLoading || !isSourceSet}
              className={`w-full px-6 py-3 text-white font-semibold rounded-lg shadow-md transition-colors disabled:bg-gray-500 ${isProcessing ? "bg-red-600 hover:bg-red-700" : "bg-green-600 hover:bg-green-700"}`}>
              {isProcessing ? "AI 효과 중지" : "AI 효과 시작"}
            </button>
          </div>
        </div>

        {/* Display Area */}
        <div className="lg:col-span-2 bg-black rounded-lg shadow-xl flex flex-col md:flex-row items-center justify-center gap-2 p-2 aspect-video">
          <div className="w-full h-full relative">
            <video ref={videoRef} autoPlay playsInline muted className="w-full h-full object-contain"></video>
            <p className="absolute bottom-2 left-2 bg-black bg-opacity-50 text-white text-xs px-2 py-1 rounded">원본 영상</p>
          </div>
          <div className="w-full h-full relative flex items-center justify-center bg-gray-900">
             {processedImage ? (
                 <Image src={processedImage} alt="Processed Frame" fill style={{objectFit: 'contain'}} unoptimized />
             ) : (
                <p className="text-gray-400">AI 결과 대기 중...</p>
             )}
            <p className="absolute bottom-2 left-2 bg-black bg-opacity-50 text-white text-xs px-2 py-1 rounded">AI 적용 결과</p>
          </div>
        </div>
      </div>
      
      <canvas ref={canvasRef} style={{ display: "none" }}></canvas>
      {error && <div className="fixed bottom-8 bg-red-800 text-white py-3 px-6 rounded-lg shadow-xl animate-pulse"><p>오류: {error}</p></div>}
    </main>
  );
} 