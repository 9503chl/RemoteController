import os
import cv2
import platform
from flask import Flask, jsonify
from flask_cors import CORS

app = Flask(__name__)
CORS(app)

CURRENT_CAMERA_INDEX = 0

def get_available_cameras():
    """Returns a list of available camera names and indices."""
    if platform.system() == "Windows":
        try:
            camera_indices = []
            camera_names = []
            
            # Try first 10 camera indices
            for i in range(10):
                cap = cv2.VideoCapture(i)
                if cap.isOpened():
                    camera_indices.append(i)
                    camera_names.append(f"Camera {i}")
                    cap.release()
            
            if not camera_names:
                return [], ["No cameras found"]
            
            return camera_indices, camera_names
            
        except Exception as e:
            print(f"Error detecting cameras: {str(e)}")
            return [], ["No cameras found"]
    else:
        # Unix-like systems (Linux/Mac) camera detection
        camera_indices = []
        camera_names = []

        if platform.system() == "Darwin":  # macOS specific handling
            # Try to open the default FaceTime camera first
            cap = cv2.VideoCapture(0)
            if cap.isOpened():
                camera_indices.append(0)
                camera_names.append("FaceTime Camera")
                cap.release()

            # On macOS, additional cameras typically use indices 1 and 2
            for i in [1, 2]:
                cap = cv2.VideoCapture(i)
                if cap.isOpened():
                    camera_indices.append(i)
                    camera_names.append(f"Camera {i}")
                    cap.release()
        else:
            # Linux camera detection - test first 10 indices
            for i in range(10):
                cap = cv2.VideoCapture(i)
                if cap.isOpened():
                    camera_indices.append(i)
                    camera_names.append(f"Camera {i}")
                    cap.release()

        if not camera_names:
            return [], ["No cameras found"]

        return camera_indices, camera_names

@app.route('/get_cameras', methods=['GET'])
def get_cameras():
    """Returns the list of available cameras."""
    try:
        camera_indices, camera_names = get_available_cameras()
        cameras = []
        for idx, name in zip(camera_indices, camera_names):
            cameras.append({
                "index": idx,
                "name": name,
                "is_current": idx == CURRENT_CAMERA_INDEX
            })
        
        print(f"Available cameras: {cameras}")
        return jsonify({
            "status": "success",
            "cameras": cameras,
            "current_camera": CURRENT_CAMERA_INDEX
        })
    except Exception as e:
        print(f"Error getting cameras: {e}")
        return jsonify({"error": "Failed to get camera list"}), 500

@app.route('/set_camera', methods=['POST'])
def set_camera():
    """Sets the current camera index."""
    global CURRENT_CAMERA_INDEX
    
    from flask import request
    data = request.get_json()
    if not data or 'camera_index' not in data:
        return jsonify({"error": "Camera index not provided"}), 400
    
    camera_index = data['camera_index']
    
    try:
        # Validate camera index by trying to open it
        cap = cv2.VideoCapture(camera_index)
        if not cap.isOpened():
            cap.release()
            return jsonify({"error": f"Camera {camera_index} is not available"}), 400
        cap.release()
        
        CURRENT_CAMERA_INDEX = camera_index
        print(f"Camera set to index: {camera_index}")
        return jsonify({
            "status": "camera_set",
            "camera_index": camera_index
        })
        
    except Exception as e:
        print(f"Error setting camera: {e}")
        return jsonify({"error": "Failed to set camera"}), 500

@app.route('/login', methods=['POST'])
def login():
    """Simple login endpoint for testing."""
    from flask import request
    data = request.get_json()
    # For testing, accept any PIN
    return jsonify({"status": "login_success"})

@app.route('/check_filter', methods=['POST'])
def check_filter():
    """Simple filter check endpoint."""
    from flask import request
    data = request.get_json()
    if not data or 'filter_name' not in data:
        return jsonify({"error": "Filter name not provided"}), 400
    
    filter_name = data['filter_name']
    print(f"Filter check requested: {filter_name}")
    return jsonify({"status": "filter_exists", "path": f"media/{filter_name}.jpg"})

@app.route('/set_filter', methods=['POST'])
def set_filter():
    """Simple filter set endpoint."""
    from flask import request
    data = request.get_json()
    if not data or 'filter_name' not in data:
        return jsonify({"error": "Filter name not provided"}), 400
        
    filter_name = data['filter_name']
    print(f"Filter set: {filter_name}")
    return jsonify({"status": "filter_set", "filter": filter_name})

@app.route('/start', methods=['POST'])
def start_processing():
    """Simple start endpoint."""
    print("START command received.")
    return jsonify({"status": "started"})

@app.route('/live', methods=['POST'])
def live_processing():
    """Simple live endpoint."""
    print("LIVE command received.")
    return jsonify({"status": "live_mode_toggled"})

@app.route('/reset', methods=['POST'])
def reset_server():
    """Simple reset endpoint."""
    print("RESET command received.")
    return jsonify({"status": "resetting"})

@app.route('/test', methods=['GET'])
def test():
    """Simple test endpoint."""
    return jsonify({"status": "Server is running", "message": "Camera server test"})

if __name__ == '__main__':
    print("Starting simple camera server...")
    app.run(host='0.0.0.0', port=8000, debug=True) 