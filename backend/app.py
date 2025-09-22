# from flask import Flask, request, jsonify, send_from_directory
# import tensorflow as tf
# import numpy as np
# import os
# import smtplib
# from email.message import EmailMessage
# from werkzeug.utils import secure_filename
# import pickle
# import sklearn
# import random
# import time
# from io import BytesIO
# # add these near your other imports
# from PIL import Image
# import io




# app = Flask(__name__, static_folder='static')

# otp_store = {}

# EMAIL_ADDRESS = "kedaarkate@gmail.com"
# EMAIL_PASSWORD = "mbjr vwxl mmes gmln"
# # Load Model
# model = tf.keras.models.load_model("models/trained_plant_disease_model.keras")
# model2 = pickle.load(open('models/model.pkl', 'rb'))
# sc = pickle.load(open('models/standscaler.pkl', 'rb'))
# mx = pickle.load(open('models/minmaxscaler.pkl', 'rb'))

# try:
#     PLANT_MODEL_PATH = "models/plant_disease_model.keras"
#     plant_disease_model = tf.keras.models.load_model(PLANT_MODEL_PATH)
# except Exception:
#     PLANT_MODEL_PATH = "models/trained_plant_disease_model.keras"
#     plant_disease_model = tf.keras.models.load_model(PLANT_MODEL_PATH)

# # Two class lists you showed in your code. We'll pick based on model output length.
# CLASS_NAMES_WEB = [
#     'Apple___Apple_scab', 'Apple___Black_rot', 'Apple___Cedar_apple_rust', 'Apple___healthy',
#     'Blueberry___healthy', 'Cherry_(including_sour)___Powdery_mildew', 'Cherry_(including_sour)___healthy',
#     'Corn_(maize)___Cercospora_leaf_spot Gray_leaf_spot', 'Corn_(maize)___Common_rust_',
#     'Corn_(maize)___Northern_Leaf_Blight', 'Corn_(maize)___healthy', 'Grape___Black_rot',
#     'Grape___Esca_(Black_Measles)', 'Grape___Leaf_blight_(Isariopsis_Leaf_Spot)', 'Grape___healthy',
#     'Hibiscus_Curly_Leaves', 'Hibiscus_Healthy', 'Hibiscus_Yellowish_leaves', 'Mango_Anthracnose',
#     'Mango_Bacterial_Canker', 'Mango_Die_Black', 'Mango_Healthy',
#     'Orange___Haunglongbing_(Citrus_greening)', 'Peach___Bacterial_spot', 'Peach___healthy',
#     'Peepal_Bacterial_Leaf_Spot', 'Peepal_Healthy', 'Peepal_Yellowish_leaf',
#     'Pepper,_bell___Bacterial_spot', 'Pepper,_bell___healthy', 'Potato___Early_blight',
#     'Potato___Late_blight', 'Potato___healthy', 'Raspberry___healthy',
#     'Soybean___healthy', 'Squash___Powdery_mildew', 'Strawberry___Leaf_scorch',
#     'Strawberry___healthy', 'Tomato___Bacterial_spot', 'Tomato___Early_blight',
#     'Tomato___Late_blight', 'Tomato___Leaf_Mold', 'Tomato___Septoria_leaf_spot',
#     'Tomato___Spider_mites Two-spotted_spider_mite', 'Tomato___Target_Spot',
#     'Tomato___Tomato_Yellow_Leaf_Curl_Virus', 'Tomato___Tomato_mosaic_virus', 'Tomato___healthy'
# ]

# CLASS_NAMES_OLD = [
#     'Apple___Apple_scab', 'Apple___Black_rot', 'Apple___Cedar_apple_rust', 'Apple___healthy', 'Blueberry___healthy',
#     'Cherry_(including_sour)___Powdery_mildew', 'Cherry_(including_sour)___healthy',
#     'Corn_(maize)___Cercospora_leaf_spot Gray_leaf_spot', 'Corn_(maize)___Common_rust_',
#     'Corn_(maize)___Northern_Leaf_Blight', 'Corn_(maize)___healthy', 'Grape___Black_rot',
#     'Grape___Esca_(Black_Measles)', 'Grape___Leaf_blight_(Isariopsis_Leaf_Spot)', 'Grape___healthy',
#     'Orange___Haunglongbing_(Citrus_greening)', 'Peach___Bacterial_spot', 'Peach___healthy',
#     'Pepper,_bell___Bacterial_spot', 'Pepper,_bell___healthy', 'Potato___Early_blight',
#     'Potato___Late_blight', 'Potato___healthy', 'Raspberry___healthy', 'Soybean___healthy',
#     'Squash___Powdery_mildew', 'Strawberry___Leaf_scorch', 'Strawberry___healthy',
#     'Tomato___Bacterial_spot', 'Tomato___Early_blight', 'Tomato___Late_blight',
#     'Tomato___Leaf_Mold', 'Tomato___Septoria_leaf_spot',
#     'Tomato___Spider_mites Two-spotted_spider_mite', 'Tomato___Target_Spot',
#     'Tomato___Tomato_Yellow_Leaf_Curl_Virus', 'Tomato___Tomato_mosaic_virus', 'Tomato___healthy'
# ]

# # Choose the class list that matches the model output size
# _output_classes = plant_disease_model.output_shape[-1]
# if _output_classes == len(CLASS_NAMES_WEB):
#     CLASS_NAMES = CLASS_NAMES_WEB
# else:
#     CLASS_NAMES = CLASS_NAMES_OLD

# # ------------- PREPROCESSING -------------
# def preprocess_image_bytes(image_bytes):
#     """Preprocess image for model prediction: RGB -> 128x128 -> float32/255.0 -> [1, H, W, C]."""
#     img = Image.open(io.BytesIO(image_bytes)).convert('RGB')
#     img = img.resize((128, 128))
#     arr = np.array(img, dtype=np.float32) / 255.0
#     return np.expand_dims(arr, axis=0)

# # ------------- PREDICT CORE -------------
# def _predict_from_bytes(image_bytes):
#     x = preprocess_image_bytes(image_bytes)
#     preds = plant_disease_model.predict(x, verbose=0)[0]
#     idx = int(np.argmax(preds))
#     label = CLASS_NAMES[idx] if idx < len(CLASS_NAMES) else f"class_{idx}"
#     conf = round(float(preds[idx]) * 100.0, 2)
#     # top-5
#     top5_idx = np.argsort(preds)[-5:][::-1]
#     top5 = [
#         {"label": CLASS_NAMES[i] if i < len(CLASS_NAMES) else f"class_{i}",
#          "confidence": round(float(preds[i]) * 100.0, 2)}
#         for i in top5_idx
#     ]
#     return label, conf, top5

# # ------------- ENDPOINT (web-style) -------------
# @app.route('/predict-disease', methods=['POST'])
# def predict_disease():
#     if 'image' not in request.files:
#         return jsonify({'error': 'No image uploaded'}), 400
#     image_file = request.files['image']
#     image_bytes = image_file.read()

#     try:
#         label, conf, top5 = _predict_from_bytes(image_bytes)
#         return jsonify({
#             'predicted_disease': label,
#             'confidence': conf,
#             'top5': top5
#         }), 200
#     except Exception as e:
#         return jsonify({'error': str(e)}), 500

# # ------------- ENDPOINT (your existing /api/predict kept compatible) -------------
# @app.route('/api/predict', methods=['POST'])
# def api_predict():
#     if "image" not in request.files:
#         return jsonify({"error": "No image file provided"}), 400

#     image_file = request.files["image"]
#     image_bytes = image_file.read()

#     try:
#         label, conf, top5 = _predict_from_bytes(image_bytes)
#         # keep your old key "prediction" AND add "predicted_disease" to be friendly
#         return jsonify({
#             "prediction": label,
#             "predicted_disease": label,
#             "confidence": conf,
#             "top5": top5
#         }), 200
#     except Exception as e:
#         return jsonify({"error": str(e)}), 500

# # Load Class Labels (Ensure they match training order)
# # class_labels = ['Apple___Apple_scab', 'Apple___Black_rot', 'Apple___Cedar_apple_rust', 'Apple___healthy', 'Blueberry___healthy', 
# #                 'Cherry_(including_sour)___Powdery_mildew', 'Cherry_(including_sour)___healthy', 'Corn_(maize)___Cercospora_leaf_spot Gray_leaf_spot', 
# #                 'Corn_(maize)___Common_rust_', 'Corn_(maize)___Northern_Leaf_Blight', 'Corn_(maize)___healthy', 'Grape___Black_rot', 
# #                 'Grape___Esca_(Black_Measles)', 'Grape___Leaf_blight_(Isariopsis_Leaf_Spot)', 'Grape___healthy', 'Orange___Haunglongbing_(Citrus_greening)', 
# #                 'Peach___Bacterial_spot', 'Peach___healthy', 'Pepper,_bell___Bacterial_spot', 'Pepper,_bell___healthy', 'Potato___Early_blight', 
# #                 'Potato___Late_blight', 'Potato___healthy', 'Raspberry___healthy', 'Soybean___healthy', 'Squash___Powdery_mildew', 
# #                 'Strawberry___Leaf_scorch', 'Strawberry___healthy', 'Tomato___Bacterial_spot', 'Tomato___Early_blight', 'Tomato___Late_blight', 
# #                 'Tomato___Leaf_Mold', 'Tomato___Septoria_leaf_spot', 'Tomato___Spider_mites Two-spotted_spider_mite', 'Tomato___Target_Spot', 
# #                 'Tomato___Tomato_Yellow_Leaf_Curl_Virus', 'Tomato___Tomato_mosaic_virus', 'Tomato___healthy']

# UPLOAD_FOLDER = "uploads"
# os.makedirs(UPLOAD_FOLDER, exist_ok=True)
# app.config["UPLOAD_FOLDER"] = UPLOAD_FOLDER

# QR_CODES_DIR = "static/qr_codes"  # Folder where QR code images are stored


# @app.route('/api/get_qr_code', methods=['GET'])
# def get_qr_code():
#     """Return a QR code image along with its associated URL."""
#     try:
#         # Ensure the QR code directory exists
#         if not os.path.exists(QR_CODES_DIR):
#             return jsonify({"error": "QR code directory does not exist"}), 404
        
#         # List all the files in the QR code directory
#         qr_files = os.listdir(QR_CODES_DIR)

#         if not qr_files:
#             return jsonify({"error": "No QR codes found"}), 404
        
#         # Randomly choose a QR code file
#         selected_qr_file = random.choice(qr_files)
        
#         # Generate a URL for this QR code - this could be based on the filename
#         # or could be a fixed URL for your control interface
#         control_url = f"http://192.168.150.119:5000/control-panel"
        
#         # Set the URL in the response header so it can be retrieved by the client
#         response = send_from_directory(QR_CODES_DIR, selected_qr_file, as_attachment=False)
#         response.headers['X-QR-URL'] = control_url
        
#         return response

#     except Exception as e:
#         return jsonify({"error": str(e)}), 500

# # Alternative implementation that returns JSON with both URL and image path
# @app.route('/api/get_qr_code_with_url', methods=['GET'])
# def get_qr_code_with_url():
#     """Return both a QR code image path and its associated URL."""
#     try:
#         # Ensure the QR code directory exists
#         if not os.path.exists(QR_CODES_DIR):
#             return jsonify({"error": "QR code directory does not exist"}), 404
        
#         # List all the files in the QR code directory
#         qr_files = os.listdir(QR_CODES_DIR)

#         if not qr_files:
#             return jsonify({"error": "No QR codes found"}), 404
        
#         # Randomly choose a QR code file
#         selected_qr_file = random.choice(qr_files)
        
#         # Generate a URL for this QR code
#         control_url = f"http://192.168.150.119:5000/control-panel"
        
#         # Return both the image path and URL in a JSON response
#         return jsonify({
#             "image_path": f"/static/qr_codes/{selected_qr_file}",
#             "url": control_url
#         })

#     except Exception as e:
#         return jsonify({"error": str(e)}), 500

# def generate_otp():
#     return str(random.randint(100000, 999999))


# def send_email(receiver_email, otp):
#     """Send OTP via Gmail"""
#     try:
#         msg = EmailMessage()
#         msg.set_content(f"Your OTP code is: {otp}. It will expire in 5 minutes.")

#         msg["Subject"] = "Your OTP Code"
#         msg["From"] = EMAIL_ADDRESS
#         msg["To"] = receiver_email

#         # Connect to Gmail SMTP
#         with smtplib.SMTP_SSL("smtp.gmail.com", 465) as server:
#             server.login(EMAIL_ADDRESS, EMAIL_PASSWORD)
#             server.send_message(msg)
        
#         print(f"✅ OTP sent to {receiver_email}: {otp}")
#         return True

#     except Exception as e:
#         print(f"❌ Error sending OTP: {e}")
#         return False


# @app.route('/api/send-otp', methods=['POST'])
# def send_otp():
#     """Generate OTP and send via email"""
#     data = request.json
#     email = data.get('email')

#     if not email:
#         return jsonify({"error": "Email is required"}), 400

#     otp = generate_otp()
#     otp_store[email] = {"otp": otp, "timestamp": time.time()}

#     if send_email(email, otp):
#         return jsonify({"message": "OTP sent successfully"}), 200
#     else:
#         return jsonify({"error": "Failed to send OTP"}), 500


# TEST_OTP = "123456"  # Use this in your Flutter integration test

# @app.route('/api/verify-otp', methods=['POST'])
# def verify_otp():
#     """Verify OTP entered by user"""
#     data = request.json
#     email = data.get('email')
#     user_otp = data.get('otp')

#     # Allow universal test OTP to bypass normal logic
#     if user_otp == TEST_OTP:
#         if email in otp_store:
#             del otp_store[email]  # Clean up if stored
#         return jsonify({
#             "message": "Test OTP verified successfully",
#             "status": "success"
#         }), 200

#     if email not in otp_store:
#         return jsonify({"error": "OTP not found. Request again."}), 400

#     stored_otp = otp_store[email]["otp"]
#     timestamp = otp_store[email]["timestamp"]

#     if time.time() - timestamp > 300:  # OTP expires in 5 minutes
#         del otp_store[email]
#         return jsonify({"error": "OTP expired"}), 400

#     if user_otp == stored_otp:
#         del otp_store[email]
#         return jsonify({"message": "OTP verified successfully", "status": "success"}), 200
#     else:
#         return jsonify({"error": "Invalid OTP"}), 400


# def preprocess_image(file_path):
#     """Preprocess image for model prediction."""
#     img = tf.keras.preprocessing.image.load_img(file_path, target_size=(128, 128))
#     img_array = tf.keras.preprocessing.image.img_to_array(img)
#     img_array = np.expand_dims(img_array, axis=0)  # Expand dims to match model input
#     img_array = img_array.astype("float32") / 255.0  # Normalize same as training
#     print(f"Processed Image Shape: {img_array.shape}")  # Debug shape
#     return img_array


# @app.route('/api/predict', methods=['POST'])
# def predict():
#     if "image" not in request.files:
#         return jsonify({"error": "No image file provided"}), 400

#     file = request.files["image"]
#     filename = secure_filename(file.filename)
#     file_path = os.path.join(app.config["UPLOAD_FOLDER"], filename)
#     file.save(file_path)

#     try:
#         # Preprocess image
#         img_array = preprocess_image(file_path)

#         # Predict
#         raw_predictions = model.predict(img_array)

#         # Ensure model already has softmax (avoid double softmax)
#         probabilities = raw_predictions[0]  

#         # Get highest probability class
#         predicted_class_index = np.argmax(probabilities)
#         predicted_label = class_labels[predicted_class_index]
#         confidence = round(float(probabilities[predicted_class_index]) * 100, 2)
#         print("Raw Predictions:", raw_predictions)
#         print("Probabilities:", probabilities)
#         os.remove(file_path)  # Cleanup image

#         return jsonify({
#             "prediction": predicted_label,
#             "confidence": confidence
#         })

#     except Exception as e:
#         return jsonify({"error": str(e)}), 500


# @app.route('/api/crop_recommend', methods=['POST'])
# def crop_recommend():
#     try:
#         # Parse form data
#         N = int(request.json['N'])
#         P = int(request.json['P'])
#         K = int(request.json['K'])
#         temperature = float(request.json['temperature'])
#         humidity = float(request.json['humidity'])
#         ph = float(request.json['ph'])
#         rainfall = float(request.json['rainfall'])

#         # Convert input to numpy array
#         feature_list = [N, P, K, temperature, humidity, ph, rainfall]
#         print(feature_list)
#         single_pred = np.array(feature_list).reshape(1, -1)

#         # Transform features
#         mx_features = mx.transform(single_pred)
#         sc_mx_features = sc.transform(mx_features)

#         # Predict crop
#         prediction = model2.predict(sc_mx_features)[0]

#         # Crop mapping dictionary
#         crop_dict = {
#             1: "Rice", 2: "Maize", 3: "Jute", 4: "Cotton", 5: "Coconut",
#             6: "Papaya", 7: "Orange", 8: "Apple", 9: "Muskmelon", 10: "Watermelon",
#             11: "Grapes", 12: "Mango", 13: "Banana", 14: "Pomegranate",
#             15: "Lentil", 16: "Blackgram", 17: "Mungbean", 18: "Mothbeans",
#             19: "Pigeonpeas", 20: "Kidneybeans", 21: "Chickpea", 22: "Coffee"
#         }

#         # Get crop name
#         recommended_crop = crop_dict.get(prediction, "Unknown Crop")

#         return jsonify({"recommended_crop": recommended_crop})

#     except Exception as e:
#         return jsonify({"error": str(e)}), 400


# @app.route('/api/health', methods=['GET'])
# def health_check():
#     return jsonify({'status': 'API is running'})


# if __name__ == '__main__':
#     app.run(host='0.0.0.0',port=5000,debug=True)

from flask import Flask, request, jsonify
import os, io, re, time, random, pickle
import numpy as np
import tensorflow as tf
from PIL import Image
from email.message import EmailMessage
import smtplib
import joblib

# -----------------------
# Flask
# -----------------------
app = Flask(__name__, static_folder='static')

# =========================
# Auth / OTP setup (unchanged)
# =========================
otp_store = {}
EMAIL_ADDRESS = "kedaarkate@gmail.com"
EMAIL_PASSWORD = "mbjr vwxl mmes gmln"

# =========================
# Load disease model (only this one)
# =========================
PLANT_MODEL_PATH = "models/plant_disease_model.keras"
plant_disease_model = tf.keras.models.load_model(PLANT_MODEL_PATH)

# Map your indices to model filenames
_RISK_MODEL_FILES = {
    0: "ExtraTrees_LB.joblib",   # Leaf Blast
    1: "ExtraTrees_NB.joblib",   # Neck Blast
    2: "LinearReg_GD.joblib",    # Glume Discoloration
    3: "ExtraTrees_SR.joblib",   # Sheath Rot
    4: "BayesRi_SB.joblib",      # Sheath Blight
    5: "LinearReg_BS.joblib",    # Brown Spot
}

RISK_MODELS = {}
for idx, fname in _RISK_MODEL_FILES.items():
    path = os.path.join("models", fname) if not os.path.isabs(fname) else fname
    if not os.path.exists(path):
        print(f"[WARN] Risk model file not found: {path}")
        continue
    try:
        RISK_MODELS[idx] = joblib.load(path)
        print(f"[INIT] Loaded risk model {idx}: {fname}")
    except Exception as e:
        print(f"[ERR ] Failed to load {fname}: {e}")

# =========================
# Risk scoring endpoint
# =========================
@app.route('/risk/add', methods=['POST'])
def risk_add():
    """
    Expects JSON:
    {
      "values": [stage, maxTemp, minTemp, relH1, relH2, rainfall, rainyDays,
                 sunHours, windSpeed, soilPh, nitrogen, potassium, salinity],
      "disease": <int 0..5>
    }
    Returns: { "prediction": <float> }
    """
    try:
        data = request.get_json(force=True, silent=False) or {}
        values = data.get('values')
        disease = data.get('disease')

        if not isinstance(values, list) or len(values) != 13:
            return jsonify({"error": "Expected 13 numeric values in 'values'"}), 400
        if not isinstance(disease, int) or disease not in RISK_MODELS:
            return jsonify({"error": "Unknown or unloaded disease index"}), 400

        X = np.array(values, dtype=float).reshape(1, -1)

        # NOTE:
        # If you trained with a scaler/encoder, you should have saved a Pipeline and load it here.
        # These joblib files should encapsulate any preprocessing.
        model = RISK_MODELS[disease]
        y_pred = model.predict(X)
        pred = float(y_pred[0])

        return jsonify({"prediction": pred}), 200

    except Exception as e:
        return jsonify({"error": str(e)}), 500

# ---- helpers to align preprocessing with training ----
def _model_has_rescaling(m):
    """Return True if the Keras model already contains a Rescaling layer."""
    try:
        for layer in m.layers:
            name = getattr(layer, "__class__", type("x", (), {})).__name__
            if name == "Rescaling":
                return True
    except Exception:
        pass
    return False

def _infer_target_size(m):
    """Infer (W,H) from model.input_shape; fallback to (128,128)."""
    ishape = getattr(m, "input_shape", None)
    # expected (None, H, W, C)
    if isinstance(ishape, (list, tuple)) and len(ishape) >= 4:
        H, W = ishape[1], ishape[2]
        if isinstance(H, int) and isinstance(W, int):
            return (W, H)  # PIL expects (width, height)
    return (128, 128)

_HAS_RESCALING = _model_has_rescaling(plant_disease_model)
_TARGET_SIZE = _infer_target_size(plant_disease_model)

print(f"[INIT] input_shape={plant_disease_model.input_shape}  output_shape={plant_disease_model.output_shape}")
print(f"[INIT] has_rescaling={_HAS_RESCALING}  target_size={_TARGET_SIZE}")

# =========================
# Class names
# Try to load from JSON saved during training; else fallback to your list.
# =========================

CLASS_NAMES = [
    'Apple___Apple_scab', 'Apple___Black_rot', 'Apple___Cedar_apple_rust', 'Apple___healthy',
    'Blueberry___healthy', 'Cherry_(including_sour)___Powdery_mildew', 'Cherry_(including_sour)___healthy',
    'Corn_(maize)___Cercospora_leaf_spot Gray_leaf_spot', 'Corn_(maize)___Common_rust_',
    'Corn_(maize)___Northern_Leaf_Blight', 'Corn_(maize)___healthy', 'Grape___Black_rot',
    'Grape___Esca_(Black_Measles)', 'Grape___Leaf_blight_(Isariopsis_Leaf_Spot)', 'Grape___healthy',
    'Orange___Haunglongbing_(Citrus_greening)', 'Peach___Bacterial_spot', 'Peach___healthy',
    'Pepper,_bell___Bacterial_spot', 'Pepper,_bell___healthy', 'Potato___Early_blight',
    'Potato___Late_blight', 'Potato___healthy', 'Raspberry___healthy',
    'Soybean___healthy', 'Squash___Powdery_mildew', 'Strawberry___Leaf_scorch',
    'Strawberry___healthy', 'Tomato___Bacterial_spot', 'Tomato___Early_blight',
    'Tomato___Late_blight', 'Tomato___Leaf_Mold', 'Tomato___Septoria_leaf_spot',
    'Tomato___Spider_mites Two-spotted_spider_mite', 'Tomato___Target_Spot',
    'Tomato___Tomato_Yellow_Leaf_Curl_Virus', 'Tomato___Tomato_mosaic_virus', 'Tomato___healthy'
]
print(f"[INIT] Loaded {len(CLASS_NAMES)} class names from fallback list")

# Validate count
_output_classes = plant_disease_model.output_shape[-1]
assert _output_classes == len(CLASS_NAMES), \
    f"Model outputs {_output_classes} classes but CLASS_NAMES has {len(CLASS_NAMES)}. Label order/length mismatch."

# =========================
# Pretty formatter for labels
# =========================
def prettify_label(label: str) -> str:
    if not label:
        return label
    parts = label.split('___')
    crop = parts[0]
    disease = parts[1] if len(parts) > 1 else ''

    def clean(s: str) -> str:
        s = s.replace('_', ' ')
        s = re.sub(r'\s+', ' ', s)
        s = s.strip(' _-')
        s = s.replace(' ,', ',')
        s = s.replace('( ', '(').replace(' )', ')')
        return s

    crop = clean(crop)
    disease = clean(disease)
    if crop:
        crop = crop[:1].upper() + crop[1:]
    if disease:
        disease = disease.lower()
    return f"{crop} {disease}".strip()

# =========================
# Image preprocessing matching training
# =========================
def preprocess_image_bytes(image_bytes: bytes) -> np.ndarray:
    img = Image.open(io.BytesIO(image_bytes)).convert('RGB').resize(_TARGET_SIZE)
    arr = np.array(img, dtype=np.float32)
    # Only divide if the model DOES NOT already rescale
    if not _HAS_RESCALING:
        arr = arr / 255.0
    return np.expand_dims(arr, axis=0)  # (1, H, W, 3)

def _predict_from_bytes(image_bytes: bytes):
    x = preprocess_image_bytes(image_bytes)
    preds = plant_disease_model.predict(x, verbose=0)[0]

    idx = int(np.argmax(preds))
    label = CLASS_NAMES[idx] if idx < len(CLASS_NAMES) else f"class_{idx}"
    conf = round(float(preds[idx]) * 100.0, 2)

    # optional debug
    try:
        mx, mn = float(np.max(preds)), float(np.min(preds))
        print(f"[PRED] argmax={idx} max={mx:.4f} min={mn:.4f}")
        print(f"[PRED] top5 idx:", np.argsort(preds)[-5:][::-1])
    except Exception:
        pass

    top5_idx = np.argsort(preds)[-5:][::-1]
    top5 = [
        {"label": CLASS_NAMES[i] if i < len(CLASS_NAMES) else f"class_{i}",
         "confidence": round(float(preds[i]) * 100.0, 2)}
        for i in top5_idx
    ]
    return label, conf, top5

# =========================
# Prediction endpoints
# =========================
@app.route('/predict-disease', methods=['POST'])
def predict_disease():
    if 'image' not in request.files:
        return jsonify({'error': 'No image uploaded'}), 400
    image_file = request.files['image']
    image_bytes = image_file.read()
    try:
        label, conf, top5 = _predict_from_bytes(image_bytes)
        pretty = prettify_label(label)
        top5_pretty = [{'label': prettify_label(t['label']), 'confidence': t['confidence']} for t in top5]
        return jsonify({
            'predicted_disease': pretty,
            'raw_label': label,
            'confidence': conf,
            'top5': top5_pretty
        }), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/predict', methods=['POST'])
def api_predict():
    if "image" not in request.files:
        return jsonify({"error": "No image file provided"}), 400
    image_file = request.files["image"]
    image_bytes = image_file.read()
    try:
        label, conf, top5 = _predict_from_bytes(image_bytes)
        pretty = prettify_label(label)
        top5_pretty = [{'label': prettify_label(t['label']), 'confidence': t['confidence']} for t in top5]
        return jsonify({
            "prediction": pretty,
            "predicted_disease": pretty,
            "raw_label": label,
            "confidence": conf,
            "top5": top5_pretty
        }), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

# =========================
# Crop recommendation (unchanged)
# =========================
model2 = pickle.load(open('models/model.pkl', 'rb'))
sc = pickle.load(open('models/standscaler.pkl', 'rb'))
mx = pickle.load(open('models/minmaxscaler.pkl', 'rb'))

@app.route('/api/crop_recommend', methods=['POST'])
def crop_recommend():
    try:
        N = int(request.json['N'])
        P = int(request.json['P'])
        K = int(request.json['K'])
        temperature = float(request.json['temperature'])
        humidity = float(request.json['humidity'])
        ph = float(request.json['ph'])
        rainfall = float(request.json['rainfall'])
        feature_list = [N, P, K, temperature, humidity, ph, rainfall]
        single_pred = np.array(feature_list).reshape(1, -1)
        mx_features = mx.transform(single_pred)
        sc_mx_features = sc.transform(mx_features)
        prediction = model2.predict(sc_mx_features)[0]
        crop_dict = {
            1: "Rice", 2: "Maize", 3: "Jute", 4: "Cotton", 5: "Coconut",
            6: "Papaya", 7: "Orange", 8: "Apple", 9: "Muskmelon", 10: "Watermelon",
            11: "Grapes", 12: "Mango", 13: "Banana", 14: "Pomegranate",
            15: "Lentil", 16: "Blackgram", 17: "Mungbean", 18: "Mothbeans",
            19: "Pigeonpeas", 20: "Kidneybeans", 21: "Chickpea", 22: "Coffee"
        }
        recommended_crop = crop_dict.get(prediction, "Unknown Crop")
        return jsonify({"recommended_crop": recommended_crop})
    except Exception as e:
        return jsonify({"error": str(e)}), 400

# =========================
# OTP endpoints (unchanged)
# =========================
def generate_otp():
    return str(random.randint(100000, 999999))

def send_email(receiver_email, otp):
    try:
        msg = EmailMessage()
        msg.set_content(f"Your OTP code is: {otp}. It will expire in 5 minutes.")
        msg["Subject"] = "Your OTP Code"
        msg["From"] = EMAIL_ADDRESS
        msg["To"] = receiver_email
        with smtplib.SMTP_SSL("smtp.gmail.com", 465) as server:
            server.login(EMAIL_ADDRESS, EMAIL_PASSWORD)
            server.send_message(msg)
        print(f"✅ OTP sent to {receiver_email}: {otp}")
        return True
    except Exception as e:
        print(f"❌ Error sending OTP: {e}")
        return False

@app.route('/api/send-otp', methods=['POST'])
def send_otp():
    data = request.json
    email = data.get('email')
    if not email:
        return jsonify({"error": "Email is required"}), 400
    otp = generate_otp()
    otp_store[email] = {"otp": otp, "timestamp": time.time()}
    if send_email(email, otp):
        return jsonify({"message": "OTP sent successfully"}), 200
    else:
        return jsonify({"error": "Failed to send OTP"}), 500

TEST_OTP = "123456"

@app.route('/api/verify-otp', methods=['POST'])
def verify_otp():
    data = request.json
    email = data.get('email')
    user_otp = data.get('otp')
    if user_otp == TEST_OTP:
        if email in otp_store:
            del otp_store[email]
        return jsonify({"message": "Test OTP verified successfully", "status": "success"}), 200
    if email not in otp_store:
        return jsonify({"error": "OTP not found. Request again."}), 400
    stored_otp = otp_store[email]["otp"]
    timestamp = otp_store[email]["timestamp"]
    if time.time() - timestamp > 300:
        del otp_store[email]
        return jsonify({"error": "OTP expired"}), 400
    if user_otp == stored_otp:
        del otp_store[email]
        return jsonify({"message": "OTP verified successfully", "status": "success"}), 200
    else:
        return jsonify({"error": "Invalid OTP"}), 400

# =========================
# Health
# =========================
@app.route('/api/health', methods=['GET'])
def health_check():
    return jsonify({'status': 'API is running'})

if __name__ == '__main__':
    # For Android emulator: call http://10.0.2.2:5000 from the Flutter app
    app.run(host='0.0.0.0', port=5000, debug=True)
