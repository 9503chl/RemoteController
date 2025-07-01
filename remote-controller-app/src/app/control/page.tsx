"use client";

import { useState, useEffect } from "react";

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
  const [filterName, setFilterName] = useState("");
  const [statusMessage, setStatusMessage] = useState("");
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [isStarted, setIsStarted] = useState(false);
  const [cameras, setCameras] = useState<Array<{ index: number; name: string; is_current: boolean }>>([]);
  const [currentCamera, setCurrentCamera] = useState<number>(0);
  
  const API_BASE_URL = "http://127.0.0.1:8000";

  const showStatus = (message: string, duration = 3000) => {
    setStatusMessage(message);
    setTimeout(() => setStatusMessage(""), duration);
  };

  const handleApiCall = async (endpoint: string, options: RequestInit = {}, successMessage?: string) => {
    try {
      const response = await fetch(`${API_BASE_URL}/${endpoint}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        ...options,
      });
      const data = await response.json();
      if (response.ok) {
        showStatus(successMessage || data.status);
        return data;
      } else {
        showStatus(`Error: ${data.error || 'Unknown error'}`);
        return null;
      }
    } catch (err) {
      showStatus("Error: Failed to connect to server.");
      console.error(err);
      return null;
    }
  };

  const checkFilter = async () => {
    if (!filterName) {
      showStatus("필터 명을 입력해주세요.");
      return;
    }
    const data = await handleApiCall(
      'check_filter', 
      { body: JSON.stringify({ filter_name: filterName }) } as RequestInit,
      "필터 파일 확인 완료."
    );
    if(data && data.status === 'filter_exists') {
      setIsModalOpen(true);
    }
  };
  
  const applyFilter = async () => {
    const data = await handleApiCall(
        'set_filter',
        { body: JSON.stringify({ filter_name: filterName }) } as RequestInit,
        `필터 적용됨: ${filterName}`
    );
    if (data) {
        setIsStarted(false); // Reset start status when a new filter is applied
    }
    setIsModalOpen(false);
  };

  const handleStart = async () => {
    const data = await handleApiCall('start', {}, '프로그램 시작됨.');
    if (data && data.status === 'started') {
        setIsStarted(true);
    }
  };

  const handleReset = async () => {
      await handleApiCall('reset', {}, '프로그램 재시작 중...');
      setIsStarted(false); // Also reset on reset
  }

  const fetchCameras = async () => {
    try {
      const response = await fetch(`${API_BASE_URL}/get_cameras`);
      const data = await response.json();
      if (response.ok && data.cameras) {
        setCameras(data.cameras);
        setCurrentCamera(data.current_camera);
      } else {
        showStatus("카메라 목록을 가져올 수 없습니다.");
      }
    } catch (err) {
      showStatus("카메라 목록 가져오기 실패.");
      console.error(err);
    }
  };

  const handleCameraChange = async (cameraIndex: number) => {
    const data = await handleApiCall(
      'set_camera',
      { body: JSON.stringify({ camera_index: cameraIndex }) } as RequestInit,
      `카메라 변경됨: ${cameras.find(c => c.index === cameraIndex)?.name || cameraIndex}`
    );
    if (data) {
      setCurrentCamera(cameraIndex);
      // Update cameras list to reflect current selection
      setCameras(cameras.map(camera => ({ 
        ...camera, 
        is_current: camera.index === cameraIndex 
      })));
    }
  };

  useEffect(() => {
    fetchCameras();
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
              value={filterName}
              onChange={(e) => setFilterName(e.target.value)}
              className="focus:shadow-outline flex-grow appearance-none rounded-l border px-3 py-2 leading-tight text-gray-700 shadow focus:outline-none"
              placeholder="확장자 제외하고 입력"
            />
            <button
              onClick={checkFilter}
              className="rounded-r bg-gray-600 px-4 py-2 font-bold text-white hover:bg-gray-700"
            >
              확인
            </button>
          </div>
        </div>

        <div className="mb-4">
          <label htmlFor="cameraSelect" className="mb-2 block text-sm font-bold text-gray-700">
            카메라 선택
          </label>
          <div className="flex">
            <select
              id="cameraSelect"
              value={currentCamera}
              onChange={(e) => handleCameraChange(Number(e.target.value))}
              className="focus:shadow-outline flex-grow appearance-none rounded-l border px-3 py-2 leading-tight text-gray-700 shadow focus:outline-none"
            >
              {cameras.length > 0 ? (
                cameras.map((camera) => (
                  <option key={camera.index} value={camera.index}>
                    {camera.name}
                  </option>
                ))
              ) : (
                <option value="">카메라를 찾는 중...</option>
              )}
            </select>
            <button
              onClick={fetchCameras}
              className="rounded-r bg-blue-600 px-4 py-2 font-bold text-white hover:bg-blue-700"
            >
              새로고침
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
                onClick={() => handleApiCall('live', {}, '라이브 모드.')}
                disabled={!isStarted}
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

        {statusMessage && (
          <div className="mt-4 rounded-md bg-gray-200 p-3 text-center text-sm text-gray-800">
            {statusMessage}
          </div>
        )}
      </div>

      {isModalOpen && (
        <Modal
          title="필터 파일 확인"
          message="확인 되었습니다."
          onConfirm={applyFilter}
          onCancel={() => setIsModalOpen(false)}
        />
      )}
    </main>
  );
} 