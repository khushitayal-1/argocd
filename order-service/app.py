from flask import Flask, jsonify
import requests
import random
import time
import os

app = Flask(__name__)

USER_SERVICE_URL = os.getenv("USER_SERVICE_URL", "http://user-service:5000")

@app.route("/orders")
def get_orders():
    time.sleep(random.uniform(0.2, 0.6))

    try:
        response = requests.get(f"{USER_SERVICE_URL}/users/1")
        user = response.json()
    except:
        user = {"error": "User service unavailable"}

    order = {
        "order_id": random.randint(1000, 9999),
        "item": "Laptop",
        "user": user
    }

    return jsonify(order)

@app.route("/health")
def health():
    return "OK"

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5001)