from flask import Flask, jsonify
import mysql.connector
import boto3
import os
import random
import socket
import json

app = Flask(__name__)

secrets_client = boto3.client(
    "secretsmanager",
    region_name="ap-southeast-2"
)

secret_response = secrets_client.get_secret_value(
    SecretId=os.getenv("DB_SECRET_ARN")
)

secret = json.loads(secret_response["SecretString"])
db_password = secret["password"]

db_config = {
    "host": os.getenv("DB_HOST"),
    "user": os.getenv("MYSQL_USER"),
    "password": db_password,
    "database": os.getenv("DB_NAME"),
    "port": int(os.getenv("DB_PORT", 3306))
}

JOKES = [
    "There are only 10 types of people: those who understand binary and those who don't.",
    "It works on my machine ¯\\_(ツ)_/¯",
    "99 little bugs in the code, 99 little bugs. Take one down, patch it around, 127 little bugs in the code.",
    "A SQL query walks into a bar, walks up to two tables and asks: 'Can I join you?'",
    "I would tell you a UDP joke, but you might not get it.",
    "How many programmers does it take to change a light bulb? None, that's a hardware problem.",
    "docker: 'It's not a bug, it's a container feature.'",
    "There's no place like 127.0.0.1.",
    "YAML: because your config file needed more ways to break on indentation.",
    "Kubernetes: making 'it worked on my laptop' someone else's problem since 2014.",
]

BACKGROUNDS = ["#028090", "#7209b7", "#f77f00", "#2a9d8f", "#e63946", "#3a0ca3"]


def get_connection():
    return mysql.connector.connect(**db_config)


def check_db_connection():
    connection = get_connection()
    cursor = connection.cursor()
    cursor.execute("SELECT VERSION()")
    version = cursor.fetchone()[0]
    cursor.close()
    connection.close()
    return version


def bump_visit_count():
    connection = get_connection()
    cursor = connection.cursor()
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS visits (
            id INT PRIMARY KEY AUTO_INCREMENT,
            hits INT NOT NULL DEFAULT 0
        )
    """)
    cursor.execute("SELECT COUNT(*) FROM visits")
    if cursor.fetchone()[0] == 0:
        cursor.execute("INSERT INTO visits (hits) VALUES (0)")
    cursor.execute("UPDATE visits SET hits = hits + 1")
    connection.commit()
    cursor.execute("SELECT hits FROM visits LIMIT 1")
    hits = cursor.fetchone()[0]
    cursor.close()
    connection.close()
    return hits


@app.route("/")
def home():
    joke = random.choice(JOKES)
    color = random.choice(BACKGROUNDS)
    hostname = socket.gethostname()
    try:
        version = check_db_connection()
        hits = bump_visit_count()
        return f"""
        <html>
            <head>
                <title>Cloud Security Lab</title>
                <style>
                    body {{
                        font-family: 'Trebuchet MS', Arial, sans-serif;
                        text-align: center;
                        padding: 60px 20px;
                        margin: 0;
                        min-height: 100vh;
                        color: white;
                        background: linear-gradient(-45deg, {color}, #0f2027, #203a43, #2c5364);
                        background-size: 400% 400%;
                        animation: gradientShift 12s ease infinite;
                    }}
                    @keyframes gradientShift {{
                        0% {{ background-position: 0% 50%; }}
                        50% {{ background-position: 100% 50%; }}
                        100% {{ background-position: 0% 50%; }}
                    }}
                    .card {{
                        max-width: 640px;
                        margin: 0 auto;
                        background: rgba(0, 0, 0, 0.35);
                        border-radius: 16px;
                        padding: 40px;
                        box-shadow: 0 8px 32px rgba(0, 0, 0, 0.4);
                        backdrop-filter: blur(4px);
                    }}
                    h1 {{ font-size: 2.2em; margin-bottom: 0.2em; }}
                    .badge {{
                        display: inline-block;
                        background: rgba(255, 255, 255, 0.15);
                        padding: 6px 16px;
                        border-radius: 999px;
                        font-size: 0.95em;
                        margin: 6px;
                    }}
                    .joke {{
                        font-style: italic;
                        font-size: 1.1em;
                        margin: 24px 0;
                        line-height: 1.5;
                    }}
                    a {{ color: #ffe66d; text-decoration: none; font-weight: bold; }}
                    a:hover {{ text-decoration: underline; }}
                    .hits {{ font-size: 2.5em; font-weight: bold; margin: 10px 0; }}
                </style>
            </head>
            <body>
                <div class="card">
                    <h1>&#128736;&#65039; Welcome to the DevOps Lab!</h1>
                    <p class="badge">&#9989; Connected to MySQL {version}</p>
                    <p class="badge">&#128421;&#65039; Served from {hostname}</p>
                    <div class="hits">&#128064; {hits} visits</div>
                    <p class="joke">&#128161; "{joke}"</p>
                    <p>
                        <a href="/health">Health</a> &nbsp;|&nbsp;
                        <a href="/db-test">DB Test</a> &nbsp;|&nbsp;
                        <a href="/api/joke">Random Joke (JSON)</a> &nbsp;|&nbsp;
                        <a href="/api/stats">Stats (JSON)</a>
                    </p>
                </div>
            </body>
        </html>
        """
    except Exception as e:
        return f"""
        <html>
            <head><title>DevOps Lab</title></head>
            <body style="font-family: Arial; text-align: center; padding: 50px; background: #1a1a2e; color: white;">
                <h1 style="color: #ff6b6b;">&#128165; Welcome to DevOps Lab!</h1>
                <p style="font-size: 20px; color: #ff6b6b;">Database Connection Failed &#10060;</p>
                <p>{str(e)}</p>
                <p><a href="/health" style="color:#ffe66d;">Check Health</a></p>
            </body>
        </html>
        """, 500


@app.route("/health")
def health():
    return jsonify({"status": "healthy"}), 200


@app.route("/db-test")
def db_test():
    try:
        version = check_db_connection()
        return jsonify({
            "status": "success",
            "message": "Database connection successful",
            "mysql_version": version
        }), 200
    except Exception as e:
        return jsonify({
            "status": "error",
            "message": str(e)
        }), 500


@app.route("/api/joke")
def api_joke():
    return jsonify({"joke": random.choice(JOKES)}), 200


@app.route("/api/stats")
def api_stats():
    try:
        hits = bump_visit_count()
        return jsonify({"total_visits": hits, "host": socket.gethostname()}), 200
    except Exception as e:
        return jsonify({"status": "error", "message": str(e)}), 500


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)
