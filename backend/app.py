from flask import Flask, request, jsonify
import tensorflow as tf
import numpy as np
import os
import smtplib
from email.message import EmailMessage
from werkzeug.utils import secure_filename
import pickle
import sklearn
import random
import time


app = Flask(__name__)

otp_store = {}

EMAIL_ADDRESS = "kedaarkate@gmail.com"
EMAIL_PASSWORD = "rjwu whro dvmj zahd"
# Load Model
model = tf.keras.models.load_model("models/trained_plant_disease_model.keras")
model2 = pickle.load(open('models/model.pkl','rb'))
sc = pickle.load(open('models/standscaler.pkl','rb'))
mx = pickle.load(open('models/minmaxscaler.pkl','rb'))

# Load Class Labels (Ensure they match training order)
class_labels = ['Apple___Apple_scab', 'Apple___Black_rot', 'Apple___Cedar_apple_rust', 'Apple___healthy', 'Blueberry___healthy', 'Cherry_(including_sour)___Powdery_mildew', 'Cherry_(including_sour)___healthy', 'Corn_(maize)___Cercospora_leaf_spot Gray_leaf_spot', 'Corn_(maize)___Common_rust_', 'Corn_(maize)___Northern_Leaf_Blight', 'Corn_(maize)___healthy', 'Grape___Black_rot', 'Grape___Esca_(Black_Measles)', 'Grape___Leaf_blight_(Isariopsis_Leaf_Spot)', 'Grape___healthy', 'Orange___Haunglongbing_(Citrus_greening)', 'Peach___Bacterial_spot', 'Peach___healthy', 'Pepper,_bell___Bacterial_spot', 'Pepper,_bell___healthy', 'Potato___Early_blight', 'Potato___Late_blight', 'Potato___healthy', 'Raspberry___healthy', 'Soybean___healthy', 'Squash___Powdery_mildew', 'Strawberry___Leaf_scorch', 'Strawberry___healthy', 'Tomato___Bacterial_spot', 'Tomato___Early_blight', 'Tomato___Late_blight', 'Tomato___Leaf_Mold', 'Tomato___Septoria_leaf_spot', 'Tomato___Spider_mites Two-spotted_spider_mite', 'Tomato___Target_Spot', 'Tomato___Tomato_Yellow_Leaf_Curl_Virus', 'Tomato___Tomato_mosaic_virus', 'Tomato___healthy']

UPLOAD_FOLDER = "uploads"
os.makedirs(UPLOAD_FOLDER, exist_ok=True)
app.config["UPLOAD_FOLDER"] = UPLOAD_FOLDER


def generate_otp():
    return str(random.randint(100000, 999999))

def send_email(receiver_email, otp):
    """Send OTP via Gmail"""
    try:
        msg = EmailMessage()
        msg.set_content(f"Your OTP code is: {otp}. It will expire in 5 minutes.")

        msg["Subject"] = "Your OTP Code"
        msg["From"] = EMAIL_ADDRESS
        msg["To"] = receiver_email

        # Connect to Gmail SMTP
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
    """Generate OTP and send via email"""
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


@app.route('/api/verify-otp', methods=['POST'])
def verify_otp():
    """Verify OTP entered by user"""
    data = request.json
    email = data.get('email')
    user_otp = data.get('otp')

    if email not in otp_store:
        return jsonify({"error": "OTP not found. Request again."}), 400

    stored_otp = otp_store[email]["otp"]
    timestamp = otp_store[email]["timestamp"]

    if time.time() - timestamp > 300:  # OTP expires in 5 minutes
        del otp_store[email]
        return jsonify({"error": "OTP expired"}), 400

    if user_otp == stored_otp:
        del otp_store[email]
        return jsonify({"message": "OTP verified successfully", "status": "success"}), 200
    else:
        return jsonify({"error": "Invalid OTP"}), 400

def preprocess_image(file_path):
    """Preprocess image for model prediction."""
    img = tf.keras.preprocessing.image.load_img(file_path, target_size=(128, 128))
    img_array = tf.keras.preprocessing.image.img_to_array(img)
    img_array = np.expand_dims(img_array, axis=0)  # Expand dims to match model input
    img_array = img_array.astype("float32") / 255.0  # Normalize same as training
    print(f"Processed Image Shape: {img_array.shape}")  # Debug shape
    return img_array


@app.route('/api/predict', methods=['POST'])
def predict():
    if "image" not in request.files:
        return jsonify({"error": "No image file provided"}), 400

    file = request.files["image"]
    filename = secure_filename(file.filename)
    file_path = os.path.join(app.config["UPLOAD_FOLDER"], filename)
    file.save(file_path)

    try:
        # Preprocess image
        img_array = preprocess_image(file_path)

        # Predict
        raw_predictions = model.predict(img_array)

        # Ensure model already has softmax (avoid double softmax)
        probabilities = raw_predictions[0]  

        # Get highest probability class
        predicted_class_index = np.argmax(probabilities)
        predicted_label = class_labels[predicted_class_index]
        confidence = round(float(probabilities[predicted_class_index]) * 100, 2)
        print("Raw Predictions:", raw_predictions)
        print("Probabilities:", probabilities)
        os.remove(file_path)  # Cleanup image

        return jsonify({
            "prediction": predicted_label,
            "confidence": confidence
        })

    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/api/crop_recommend', methods=['POST'])
def crop_recommend():
    try:
        # Parse form data
        N = int(request.json['N'])
        P = int(request.json['P'])
        K = int(request.json['K'])
        temperature = float(request.json['temperature'])
        humidity = float(request.json['humidity'])
        ph = float(request.json['ph'])
        rainfall = float(request.json['rainfall'])

        # Convert input to numpy array
        feature_list = [N, P, K, temperature, humidity, ph, rainfall]
        print(feature_list)
        single_pred = np.array(feature_list).reshape(1, -1)

        # Transform features
        mx_features = mx.transform(single_pred)
        sc_mx_features = sc.transform(mx_features)

        # Predict crop
        prediction = model2.predict(sc_mx_features)[0]

        # Crop mapping dictionary
        crop_dict = {
            1: "Rice", 2: "Maize", 3: "Jute", 4: "Cotton", 5: "Coconut",
            6: "Papaya", 7: "Orange", 8: "Apple", 9: "Muskmelon", 10: "Watermelon",
            11: "Grapes", 12: "Mango", 13: "Banana", 14: "Pomegranate",
            15: "Lentil", 16: "Blackgram", 17: "Mungbean", 18: "Mothbeans",
            19: "Pigeonpeas", 20: "Kidneybeans", 21: "Chickpea", 22: "Coffee"
        }

        # Get crop name
        recommended_crop = crop_dict.get(prediction, "Unknown Crop")

        return jsonify({"recommended_crop": recommended_crop})

    except Exception as e:
        return jsonify({"error": str(e)}), 400

@app.route('/api/health', methods=['GET'])
def health_check():
    return jsonify({'status': 'API is running'})


if __name__ == '__main__':
    app.run(debug=True)
