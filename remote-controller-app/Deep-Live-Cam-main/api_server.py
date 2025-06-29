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

app = Flask(__name__)
CORS(app)

# --- Global State ---
SOURCE_FACE = None
FRAME_PROCESSORS = None
MOUTH_MASK_ENABLED = False

def initialize_processors():
    """Initialize the frame processors."""
    global FRAME_PROCESSORS
    g.source_path = "source.jpg" # Dummy
    g.target_path = "target.jpg" # Dummy
    g.output_path = "output.jpg" # Dummy
    
    processors = ['face_swapper']
    if MOUTH_MASK_ENABLED:
        processors.append('mouth_mask')
    
    g.frame_processors = processors
    FRAME_PROCESSORS = get_frame_processors_modules(g.frame_processors)
    for processor in FRAME_PROCESSORS:
        # Some processors might have pre-start actions
        if hasattr(processor, 'pre_start'):
            processor.pre_start()
    print("Frame processors initialized:", processors)

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

    face = get_one_face(img)
    if not face:
        return jsonify({'error': 'No face found in the source image'}), 400
    
    SOURCE_FACE = face
    MOUTH_MASK_ENABLED = request.form.get('mouth_mask') == 'true'
    
    # Initialize (or re-initialize) processors with the new settings
    initialize_processors()
    
    print("Source face and settings have been set.")
    return jsonify({'status': 'source_set'})

@app.route('/process_frame', methods=['POST'])
def process_frame():
    """Processes a single frame sent from the browser."""
    if SOURCE_FACE is None or FRAME_PROCESSORS is None:
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

    # Process the frame using the stored source face
    for processor in FRAME_PROCESSORS:
        target_frame = processor.process_frame(
            source_face=SOURCE_FACE,
            temp_frame=target_frame
        )

    # Encode the processed frame to JPEG and send it back
    _, img_encoded = cv2.imencode('.jpg', target_frame)
    return send_file(io.BytesIO(img_encoded), mimetype='image/jpeg')

if __name__ == '__main__':
    # Initialize processors at startup with a default state
    initialize_processors()
    # Using Gunicorn in Docker, this is for local testing
    app.run(host='0.0.0.0', port=8000) 