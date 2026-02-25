from flask import Flask, jsonify
import random
import time

app = Flask(__name__)

users = [
    {"id": 1, "name": "Khushi"},
    {"id": 2, "name": "Aman"},
    {"id": 3, "name": "Riya"}
]

@app.route("/users")
def get_users():
    time.sleep(random.uniform(0.1, 0.5))
    return jsonify(users)

@app.route("/users/<int:user_id>")
def get_user(user_id):
    user = next((u for u in users if u["id"] == user_id), None)
    if user:
        return jsonify(user)
    return jsonify({"error": "User not found"}), 404

@app.route("/health")
def health():
    return "OK"

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)