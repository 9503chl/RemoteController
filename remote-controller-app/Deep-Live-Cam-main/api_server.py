import os
import cv2
import numpy as np
import io
from flask import Flask, request, jsonify, send_file
from flask_cors import CORS
from werkzeug.utils import secure_filename
import modules.globals as g
from modules.face_analyser import get_one_face
from modules.processors.frame.core import get_frame_processors_modules
from PIL import Image
import threading
import sys
import glob
import platform

# Windows용 웹캠 이름 가져오기
try:
    from pygrabber.dshow_graph import FilterGraph
    FILTERGRAPH_AVAILABLE = True
except ImportError:
    FILTERGRAPH_AVAILABLE = False
    print("Warning: pygrabber not available. Camera names will be generic.")

app = Flask(__name__)
CORS(app)

# --- Global State ---
SOURCE_FACE = None
FRAME_PROCESSORS = None
MOUTH_MASK_ENABLED = False
CURRENT_FILTER = None
CURRENT_CAMERA_INDEX = 0

def get_pin_from_file():
    """Reads the PIN from the password.txt file."""
    try:
        with open("password.txt", "r") as f:
            return f.read().strip()
    except FileNotFoundError:
        print("INFO: password.txt not found. Using default PIN '1234'.")
        return "1234"

PIN_CODE = get_pin_from_file()

def find_filter_path(filter_name):
    """Searches for a filter in the media directory, first as .png, then as .jpg."""
    secure_name = secure_filename(filter_name)
    
    # 1. Check for .png
    png_path = os.path.join('media', f"{secure_name}.png")
    if os.path.exists(png_path):
        return png_path
        
    # 2. Check for .jpg
    jpg_path = os.path.join('media', f"{secure_name}.jpg")
    if os.path.exists(jpg_path):
        return jpg_path
        
    return None

def initialize_processors():
    """Initialize the frame processors."""
    global FRAME_PROCESSORS
    # g.source_path = "source.jpg" # Dummy
    # g.target_path = "target.jpg" # Dummy
    # g.output_path = "output.jpg" # Dummy
    
    # processors = ['face_swapper']
    # if MOUTH_MASK_ENABLED:
    #     processors.append('mouth_mask')
    
    # g.frame_processors = processors
    # FRAME_PROCESSORS = get_frame_processors_modules(g.frame_processors)
    # for processor in FRAME_PROCESSORS:
    #     # Some processors might have pre-start actions
    #     if hasattr(processor, 'pre_start'):
    #         processor.pre_start()
    print("Frame processors initialization skipped.")

@app.route('/login', methods=['POST'])
def login():
    """Authenticate the user with a PIN."""
    try:
        data = request.get_json()
        if not data or 'pin' not in data:
            return jsonify({"error": "PIN not provided"}), 400
        
        if PIN_CODE is None:
            # This should not happen with the fallback, but as a safeguard:
            return jsonify({"error": "Server PIN not configured properly"}), 500

        if data['pin'] == PIN_CODE:
            return jsonify({"status": "login_success"})
        else:
            return jsonify({"error": "Invalid PIN"}), 403
    except Exception as e:
        import traceback
        print("[ERROR] Unhandled exception in /login route:")
        traceback.print_exc()
        return jsonify({"error": "An unexpected server error occurred.", "details": str(e)}), 500

@app.route('/check_filter', methods=['POST'])
def check_filter():
    """Checks if a filter file exists."""
    data = request.get_json()
    if not data or 'filter_name' not in data:
        return jsonify({"error": "Filter name not provided"}), 400
    
    filter_name = data['filter_name']
    found_path = find_filter_path(filter_name)
    
    if not found_path:
        return jsonify({"error": f"Filter '{filter_name}' not found"}), 404
    
    print(f"Filter '{found_path}' confirmed.")
    return jsonify({"status": "filter_exists", "path": found_path})

@app.route('/set_filter', methods=['POST'])
def set_filter():
    """Sets the filter to be applied."""
    global CURRENT_FILTER
    data = request.get_json()
    if not data or 'filter_name' not in data:
        return jsonify({"error": "Filter name not provided"}), 400
        
    filter_name = data['filter_name']
    found_path = find_filter_path(filter_name)
    
    if not found_path:
        return jsonify({"error": f"Cannot set filter: '{filter_name}' not found"}), 404

    CURRENT_FILTER = found_path
    # Example of setting it globally for other parts of the app to use
    g.source_path = CURRENT_FILTER
    
    print(f"Filter set to: {CURRENT_FILTER}")
    return jsonify({"status": "filter_set", "filter": CURRENT_FILTER})

@app.route('/start', methods=['POST'])
def start_processing():
    """
    Loads the selected filter image, finds a face, 
    and prepares the face swapping processor.
    """
    global SOURCE_FACE
    if CURRENT_FILTER is None:
        print("Start failed: No filter set.")
        return jsonify({"error": "필터를 먼저 설정해야 합니다."}), 400
        
    try:
        # Load the image from the path stored in CURRENT_FILTER
        img = cv2.imread(CURRENT_FILTER)
        if img is None:
            return jsonify({'error': '필터 이미지 파일을 불러올 수 없습니다.'}), 400
        
        # Get one face from the loaded image
        face = get_one_face(img)
        if not face:
            return jsonify({'error': '필터 이미지에서 얼굴을 찾을 수 없습니다.'}), 400
        
        # Set the global source face and initialize processors for face swapping
        SOURCE_FACE = face
        # Assuming mouth_mask is not needed for this controller version
        initialize_processors() 
        
        print(f"START successful. Source face set from: {CURRENT_FILTER}")
        return jsonify({"status": "started"})
        
    except Exception as e:
        print(f"Error during start processing: {e}")
        return jsonify({"error": "필터 준비 중 오류가 발생했습니다."}), 500

@app.route('/live', methods=['POST'])
def live_processing():
    """Placeholder to toggle a live mode."""
    print("LIVE command received.")
    # Add your live mode logic here
    return jsonify({"status": "live_mode_toggled"})

@app.route('/reset', methods=['POST'])
def reset_server():
    """Resets the application."""
    print("RESET command received. The server will attempt to restart.")
    
    # This is a simple way to trigger a restart. 
    # Note: This will not work correctly with some server runners like Gunicorn's default worker type.
    # It's generally better to manage the process from outside (e.g., Docker, systemd).
    def restart():
        # Wait a moment to send the response before restarting
        threading.Timer(1.0, lambda: os.execv(sys.executable, ['python'] + sys.argv)).start()

    restart()
    return jsonify({"status": "resetting"})

@app.route('/list_cameras', methods=['GET'])
def list_cameras():
    """
    사용 가능한 카메라 목록을 반환합니다.
    """
    cameras = []
    
    try:
        import cv2
        import platform
        
        system = platform.system()
        print(f"시스템: {system}")
        
        # Windows에서 실제 웹캠 이름 가져오기
        camera_names = {}
        if system == "Windows" and FILTERGRAPH_AVAILABLE:
            try:
                graph = FilterGraph()
                devices = graph.get_input_devices()
                for i, device_name in enumerate(devices):
                    camera_names[i] = device_name
                print(f"Windows 웹캠 감지: {camera_names}")
            except Exception as e:
                print(f"Windows 웹캠 이름 가져오기 실패: {e}")
        
        # OpenCV로 사용 가능한 카메라 감지
        for i in range(5):  # 최대 5개까지 확인
            cap = cv2.VideoCapture(i)
            if cap.isOpened():
                # 실제로 프레임을 읽을 수 있는지 확인
                ret, frame = cap.read()
                if not ret or frame is None:
                    cap.release()
                    continue
                
                # 해상도 확인
                width = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
                height = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))
                fps = cap.get(cv2.CAP_PROP_FPS)
                
                # 실제 웹캠 이름 사용
                if i in camera_names:
                    camera_name = camera_names[i]
                else:
                    # 기본 이름 생성
                    if system == "Windows":
                        camera_name = f"Camera {i}"
                    elif system == "Darwin":  # macOS
                        camera_name = f"FaceTime HD Camera" if i == 0 else f"Camera {i}"
                    else:  # Linux
                        camera_name = f"/dev/video{i}"
                
                cameras.append({
                    'index': i,
                    'name': camera_name,
                    'width': width,
                    'height': height,
                    'fps': int(fps) if fps > 0 else 30
                })
                
                print(f"카메라 {i}: {camera_name} - {width}x{height}@{fps}fps")
                cap.release()
        
        print(f"총 {len(cameras)}개의 웹캠 감지됨")
        return jsonify({'cameras': cameras})
        
    except Exception as e:
        print(f"카메라 목록 가져오기 오류: {e}")
        return jsonify({'cameras': []})

@app.route('/set_camera', methods=['POST'])
def set_camera():
    """
    Sets the active camera device by index, validating if it can be opened.
    """
    global CURRENT_CAMERA_INDEX
    data = request.get_json()
    if not data or 'camera_index' not in data:
        return jsonify({"error": "Camera index not provided"}), 400

    try:
        new_index = int(data['camera_index'])
        
        # 실제로 카메라를 열 수 있는지 확인
        cap = cv2.VideoCapture(new_index)
        if not cap.isOpened():
            cap.release()
            print(f"Failed to open camera at index: {new_index}")
            return jsonify({"error": f"인덱스 {new_index}의 카메라를 열 수 없습니다."}), 404
            
        cap.release() # 확인 후 바로 해제
        
        CURRENT_CAMERA_INDEX = new_index
        print(f"Camera index set to: {CURRENT_CAMERA_INDEX}")
        return jsonify({"status": "camera_set", "current_camera": CURRENT_CAMERA_INDEX})
        
    except (ValueError, TypeError):
        return jsonify({"error": "Invalid camera index provided. It must be a number."}), 400
    except Exception as e:
        print(f"카메라 설정 오류: {e}")
        return jsonify({"error": "카메라 설정 중 오류가 발생했습니다."}), 500

@app.route('/debug_devices', methods=['GET'])
def debug_devices():
    """For debugging: lists contents of /dev to see if video devices are present."""
    try:
        if platform.system() == "Linux":
            devices = os.listdir('/dev')
            return jsonify({'devices': devices})
        else:
            return jsonify({'message': f'Not on Linux, system is {platform.system()}'})
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/set_source', methods=['POST'])
def set_source():
    """Sets the source face to be used for swapping."""
    global SOURCE_FACE, MOUTH_MASK_ENABLED
    
    source_face_file = request.files.get('source_face')
    if not source_face_file:
        return jsonify({"error": "No source face image provided"}), 400

    try:
        image = Image.open(source_face_file.stream).convert("RGB")
        img = np.array(image)
        img = cv2.cvtColor(img, cv2.COLOR_RGB2BGR)
    except Exception as e:
        print(f"Error processing source image: {e}")
        return jsonify({"error": "Invalid or corrupt image file"}), 400
        
    if img is None:
        return jsonify({"error": "Failed to decode image"}), 400

    # face = get_one_face(img) # This line is commented out as get_one_face is no longer imported
    # if not face:
    #     return jsonify({'error': 'No face found in the source image'}), 400
    
    # SOURCE_FACE = face
    # MOUTH_MASK_ENABLED = request.form.get('mouth_mask') == 'true'
    
    # # Initialize (or re-initialize) processors with the new settings
    # initialize_processors()
    
    print("Source face and settings have been set.")
    return jsonify({'status': 'source_set'})

@app.route('/process_frame', methods=['POST'])
def process_frame():
    """Processes a single frame sent from the browser."""
    if SOURCE_FACE is None: # or FRAME_PROCESSORS is None:
        return jsonify({'error': 'Source face not set or processors not initialized'}), 400

    frame_file = request.files.get('frame')
    if not frame_file:
        return jsonify({'error': 'No frame data provided'}), 400
    
    try:
        image = Image.open(frame_file.stream).convert("RGB")
        target_frame = np.array(image)
        target_frame = cv2.cvtColor(target_frame, cv2.COLOR_RGB2BGR)
    except Exception as e:
        print(f"Error processing video frame: {e}")
        return jsonify({'error': 'Could not decode frame'}), 400

    if target_frame is None:
        return jsonify({'error': 'Could not decode frame'}), 400

    # If a filter is set, you might apply it here as an overlay, for example
    if CURRENT_FILTER:
        try:
            filter_img = cv2.imread(CURRENT_FILTER, cv2.IMREAD_UNCHANGED)
            # This is a placeholder for actual filter application logic
            # For example, resizing and overlaying the filter
        except Exception as e:
            print(f"Could not apply filter: {e}")

    # # Process the frame using the stored source face
    # for processor in FRAME_PROCESSORS:
    #     target_frame = processor.process_frame(
    #         source_face=SOURCE_FACE,
    #         temp_frame=target_frame
    #     )

    # Encode the processed frame to JPEG and send it back
    _, img_encoded = cv2.imencode('.jpg', target_frame)
    return send_file(io.BytesIO(img_encoded), mimetype='image/jpeg')

if __name__ == '__main__':
    # Initialize processors at startup with a default state
    initialize_processors()
    # Using Gunicorn in Docker, this is for local testing
    app.run(host='0.0.0.0', port=8080) 