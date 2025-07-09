"use client";

import { useState, useEffect } from "react";
import { Camera, AlertTriangle, Video, Sliders, Power, RefreshCw, Radio } from 'lucide-react';

// A simple modal component
const Modal = ({ title, message, onConfirm, onCancel }: { title: string, message: string, onConfirm: () => void, onCancel: () => void }) => (
  <div className="fixed inset-0 z-10 flex items-center justify-center bg-black bg-opacity-50">
    <div className="w-full max-w-xs rounded-lg bg-white p-6 shadow-lg">
      <h3 className="mb-2 text-lg font-bold">{title}</h3>
      <p className="mb-6 text-sm text-gray-600">{message}</p>
      <div className="flex justify-end space-x-4">
        <button
          onClick={onCancel}
          className="rounded px-4 py-2 text-sm font-medium text-gray-600 hover:bg-gray-100"
        >
          닫기
        </button>
        <button
          onClick={onConfirm}
          className="rounded bg-blue-600 px-4 py-2 text-sm font-medium text-white hover:bg-blue-700"
        >
          적용
        </button>
      </div>
    </div>
  </div>
);

export default function ControlPage() {
    const [serverCameras, setServerCameras] = useState<Camera[]>([]);
    const [clientCameras, setClientCameras] = useState<MediaDeviceInfo[]>([]);
    const [selectedServerCamera, setSelectedServerCamera] = useState<string>('');
    const [selectedClientCamera, setSelectedClientCamera] = useState<string>('');
    const [filters, setFilters] = useState<string[]>(['Filter1', 'Filter2', 'Filter3']); // 예시 필터
    const [selectedFilter, setSelectedFilter] = useState<string>('');
    const [isLoading, setIsLoading] = useState(true);
    const [error, setError] = useState<string | null>(null);

    const apiUrl = process.env.NEXT_PUBLIC_API_URL || "http://localhost:8080";

    // 서버 웹캠 목록 가져오기
    const getServerCameras = async () => {
        try {
            const response = await fetch(`${apiUrl}/list_cameras`);
            if (!response.ok) {
                throw new Error('서버 웹캠 목록을 불러오는 데 실패했습니다.');
            }
            const data = await response.json();
            setServerCameras(data);
        } catch (err) {
            console.error(err);
            setError('서버 웹캠 목록을 불러오는 데 실패했습니다.');
        }
    };

    // 클라이언트 웹캠 목록 가져오기
    const getClientCameras = async () => {
        try {
            const stream = await navigator.mediaDevices.getUserMedia({ video: true });
            const devices = await navigator.mediaDevices.enumerateDevices();
            const videoDevices = devices.filter(device => device.kind === 'videoinput');
            setClientCameras(videoDevices);
            stream.getTracks().forEach(track => track.stop()); // 스트림 즉시 중지
        } catch (err) {
            console.error(err);
            setError('클라이언트 웹캠 목록을 불러오는 데 실패했습니다.');
        }
    };

    // 필터 변경 핸들러
    const handleFilterChange = async (filterName: string) => {
        setSelectedFilter(filterName);
        console.log(`Setting filter to: ${filterName}`);
        try {
            const res = await fetch(`${apiUrl}/set_filter`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ filter_name: filterName }),
            });
            if (!res.ok) throw new Error('Failed to set filter');
            console.log("Filter set successfully");
        } catch (e) {
            console.error(e);
            setError('필터 설정에 실패했습니다.');
        }
    };

    // 서버 카메라 변경 핸들러
    const handleCameraChange = async (cameraIndex: number) => {
        setSelectedServerCamera(cameraIndex.toString());
        console.log(`Setting server camera to index: ${cameraIndex}`);
        try {
            const res = await fetch(`${apiUrl}/set_camera`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ camera_index: cameraIndex }),
            });
            if (!res.ok) throw new Error('Failed to set camera');
            console.log("Server camera set successfully");
        } catch (e) {
            console.error(e);
            setError('서버 카메라 설정에 실패했습니다.');
        }
    };

    // START 버튼 핸들러
    const handleStart = async () => {
        console.log("START button clicked");
        setError(null);
        try {
            const res = await fetch(`${apiUrl}/start`, {
                method: 'POST',
            });
            if (!res.ok) {
                const errData = await res.json();
                throw new Error(errData.error || 'Failed to start processing');
            }
            console.log("Processing started successfully");
        } catch (e) {
            console.error(e);
            if (e instanceof Error) {
                setError(`시작 실패: ${e.message}`);
            } else {
                setError('알 수 없는 오류로 시작에 실패했습니다.');
            }
        }
    };
    
    // RESET 버튼 핸들러
    const handleReset = async () => {
        console.log("RESET button clicked");
        try {
            await fetch(`${apiUrl}/reset`, { method: 'POST' });
            alert("서버가 재시작됩니다. 잠시 후 페이지를 새로고침해주세요.");
        } catch (e) {
            console.error(e);
            setError('리셋 요청에 실패했습니다.');
        }
    };

    // LIVE 버튼 핸들러
    const handleLive = async () => {
        console.log("LIVE button clicked");
        try {
            await fetch(`${apiUrl}/live`, { method: 'POST' });
            console.log("Live mode toggled");
        } catch (e) {
            console.error(e);
            setError('라이브 모드 전환에 실패했습니다.');
        }
    };


    useEffect(() => {
        const fetchInitialData = async () => {
            await getServerCameras();
            await getClientCameras();
            setIsLoading(false);
        };
        fetchInitialData();
    }, []);

  return (
    <main className="flex min-h-screen flex-col items-center justify-center bg-gray-100 p-4">
      <div className="w-full max-w-sm rounded-lg bg-white p-6 shadow-md">
        
        <div className="mb-4">
          <label htmlFor="filterName" className="mb-2 block text-sm font-bold text-gray-700">
            필터 명
          </label>
          <div className="flex">
            <input
              type="text"
              id="filterName"
              value={selectedFilter}
              onChange={(e) => handleFilterChange(e.target.value)}
              className="focus:shadow-outline flex-grow appearance-none rounded-l border px-3 py-2 leading-tight text-gray-700 shadow focus:outline-none"
              placeholder="확장자 제외하고 입력"
            />
            <button
              onClick={() => handleFilterChange(selectedFilter)}
              className="rounded-r bg-gray-600 px-4 py-2 font-bold text-white hover:bg-gray-700"
            >
              확인
            </button>
          </div>
        </div>

        <div className="mb-4">
          <label htmlFor="cameraIndexSelect" className="mb-2 block text-sm font-bold text-gray-700">
            서버 웹캠 인덱스
          </label>
          <div className="flex">
            <select
              id="cameraIndexSelect"
              value={selectedServerCamera}
              onChange={(e) => handleCameraChange(Number(e.target.value))}
              className="focus:shadow-outline flex-grow appearance-none rounded-l border px-3 py-2 leading-tight text-gray-700 shadow focus:outline-none"
            >
              {serverCameras.map((camera, index) => (
                <option key={index} value={index}>
                  {camera.name}
                </option>
              ))}
            </select>
            <button
              onClick={() => handleCameraChange(Number(selectedServerCamera))}
              className="rounded-r bg-blue-600 px-4 py-2 font-bold text-white hover:bg-blue-700"
            >
              적용
            </button>
          </div>
        </div>
        
        <div className="mb-4 grid grid-cols-2 gap-4">
            <button
                onClick={handleStart}
                className="rounded bg-black px-4 py-3 font-bold text-white hover:bg-gray-800"
            >
                START
            </button>
            <button
                onClick={handleLive}
                disabled={!selectedFilter}
                className="rounded bg-black px-4 py-3 font-bold text-white hover:bg-gray-800 disabled:cursor-not-allowed disabled:bg-gray-500"
            >
                LIVE
            </button>
        </div>

        <button
          onClick={handleReset}
          className="w-full rounded bg-red-600 px-4 py-3 font-bold text-white hover:bg-red-700"
        >
          RESET
        </button>

        {error && (
          <div className="mt-4 rounded-md bg-red-200 p-3 text-center text-sm text-red-800">
            {error}
          </div>
        )}
      </div>

      {/* The Modal component is no longer used as per the new_code, but keeping it for now */}
      {/* {isModalOpen && (
        <Modal
          title="필터 파일 확인"
          message="확인 되었습니다."
          onConfirm={applyFilter}
          onCancel={() => setIsModalOpen(false)}
        />
      )} */}
    </main>
  );
} 