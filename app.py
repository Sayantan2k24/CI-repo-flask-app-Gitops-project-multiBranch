from flask import Flask,jsonify

	
app = Flask(__name__)

@app.route("/health")
def health():
    return jsonify(
        status="up",
        server="v2.0"
    )

@app.route("/")
def home():
    return "<b> Welcome to my project!! </b> <br/><br/> This update is for the build #2 of release v2.0"
   
if __name__ == "__main__":
    app.run(host="0.0.0.0", port=int("5000"), debug=True)
