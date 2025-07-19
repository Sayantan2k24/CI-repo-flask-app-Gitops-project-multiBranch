import socket
from flask import Flask,jsonify

	
app = Flask(__name__)

@app.route("/health")
def health():
    return jsonify(
        status="up",
        server="v1.0",
        Maintainer="Sayantan"
    )

@app.route("/")
def home():
    return "<b> Welcome to my project!! </b> <br/><br/> This is v1.0 release"
   
if __name__ == "__main__":
    app.run(host="0.0.0.0", port=int("5000"), debug=True)
