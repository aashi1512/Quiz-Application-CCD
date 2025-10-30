from flask import Flask, request, jsonify
from flask_cors import CORS
import jwt
import datetime
import os
from functools import wraps
import psycopg2
from psycopg2.extras import RealDictCursor
import bcrypt

app = Flask(__name__)
CORS(app)

# Configuration
app.config['SECRET_KEY'] = os.getenv('JWT_SECRET', 'your-secret-key-change-in-production')
DB_CONFIG = {
    'host': os.getenv('DB_HOST', 'localhost'),
    'database': os.getenv('DB_NAME', 'quizdb'),
    'user': os.getenv('DB_USER', 'postgres'),
    'password': os.getenv('DB_PASSWORD', 'password')
}

# Database connection helper
def get_db_connection():
    return psycopg2.connect(**DB_CONFIG, cursor_factory=RealDictCursor)

# JWT decorator for protected routes
def token_required(f):
    @wraps(f)
    def decorated(*args, **kwargs):
        token = request.headers.get('Authorization')
        if not token:
            return jsonify({'message': 'Token is missing'}), 401
        try:
            token = token.split()[1] if ' ' in token else token
            data = jwt.decode(token, app.config['SECRET_KEY'], algorithms=['HS256'])
            current_user_id = data['user_id']
        except:
            return jsonify({'message': 'Token is invalid'}), 401
        return f(current_user_id, *args, **kwargs)
    return decorated

# Health check endpoint
@app.route('/health', methods=['GET'])
def health():
    return jsonify({'status': 'healthy'}), 200

# User Registration
@app.route('/api/register', methods=['POST'])
def register():
    data = request.get_json()
    username = data.get('username')
    email = data.get('email')
    password = data.get('password')
    
    if not all([username, email, password]):
        return jsonify({'message': 'Missing required fields'}), 400
    
    hashed_password = bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt())
    
    try:
        conn = get_db_connection()
        cur = conn.cursor()
        cur.execute(
            "INSERT INTO users (username, email, password_hash) VALUES (%s, %s, %s) RETURNING id",
            (username, email, hashed_password.decode('utf-8'))
        )
        user_id = cur.fetchone()['id']
        conn.commit()
        cur.close()
        conn.close()
        
        return jsonify({'message': 'User created successfully', 'user_id': user_id}), 201
    except psycopg2.IntegrityError:
        return jsonify({'message': 'User already exists'}), 409
    except Exception as e:
        return jsonify({'message': str(e)}), 500

# User Login
@app.route('/api/login', methods=['POST'])
def login():
    data = request.get_json()
    email = data.get('email')
    password = data.get('password')
    
    conn = get_db_connection()
    cur = conn.cursor()
    cur.execute("SELECT id, username, password_hash FROM users WHERE email = %s", (email,))
    user = cur.fetchone()
    cur.close()
    conn.close()
    
    if user and bcrypt.checkpw(password.encode('utf-8'), user['password_hash'].encode('utf-8')):
        token = jwt.encode({
            'user_id': user['id'],
            'exp': datetime.datetime.utcnow() + datetime.timedelta(hours=24)
        }, app.config['SECRET_KEY'], algorithm='HS256')
        
        return jsonify({
            'token': token,
            'username': user['username'],
            'user_id': user['id']
        }), 200
    
    return jsonify({'message': 'Invalid credentials'}), 401

# Get all quiz categories
@app.route('/api/categories', methods=['GET'])
def get_categories():
    conn = get_db_connection()
    cur = conn.cursor()
    cur.execute("SELECT id, name, description FROM categories ORDER BY name")
    categories = cur.fetchall()
    cur.close()
    conn.close()
    return jsonify(categories), 200

# Get questions for a category
@app.route('/api/quiz/<int:category_id>', methods=['GET'])
@token_required
def get_quiz(current_user_id, category_id):
    conn = get_db_connection()
    cur = conn.cursor()
    cur.execute(
        "SELECT id, question_text, option_a, option_b, option_c, option_d, correct_answer "
        "FROM questions WHERE category_id = %s ORDER BY RANDOM() LIMIT 10",
        (category_id,)
    )
    questions = cur.fetchall()
    cur.close()
    conn.close()
    
    # Remove correct_answer from response
    for q in questions:
        q.pop('correct_answer', None)
    
    return jsonify(questions), 200

# Submit quiz attempt
@app.route('/api/submit', methods=['POST'])
@token_required
def submit_quiz(current_user_id):
    data = request.get_json()
    category_id = data.get('category_id')
    answers = data.get('answers')  # [{question_id, user_answer, time_taken}]
    
    conn = get_db_connection()
    cur = conn.cursor()
    
    total_score = 0
    
    for answer in answers:
        question_id = answer['question_id']
        user_answer = answer['user_answer']
        time_taken = answer['time_taken']  # in seconds
        
        # Get correct answer
        cur.execute("SELECT correct_answer FROM questions WHERE id = %s", (question_id,))
        result = cur.fetchone()
        
        if result and result['correct_answer'] == user_answer:
            # Speed-based scoring: Base 100 points * (time remaining / 15)
            time_remaining = max(0, 15 - time_taken)
            points = int(100 * (time_remaining / 15)) + 50  # Base 50 points for correct
            total_score += points
    
    # Save attempt
    cur.execute(
        "INSERT INTO quiz_attempts (user_id, category_id, score, completed_at) VALUES (%s, %s, %s, NOW())",
        (current_user_id, category_id, total_score)
    )
    conn.commit()
    cur.close()
    conn.close()
    
    return jsonify({'score': total_score, 'message': 'Quiz submitted successfully'}), 200

# Get leaderboard
@app.route('/api/leaderboard', methods=['GET'])
def get_leaderboard():
    category_id = request.args.get('category_id', type=int)
    
    conn = get_db_connection()
    cur = conn.cursor()
    
    if category_id:
        query = """
            SELECT u.username, SUM(qa.score) as total_score, COUNT(qa.id) as attempts
            FROM users u
            JOIN quiz_attempts qa ON u.id = qa.user_id
            WHERE qa.category_id = %s
            GROUP BY u.id, u.username
            ORDER BY total_score DESC
            LIMIT 50
        """
        cur.execute(query, (category_id,))
    else:
        query = """
            SELECT u.username, SUM(qa.score) as total_score, COUNT(qa.id) as attempts
            FROM users u
            JOIN quiz_attempts qa ON u.id = qa.user_id
            GROUP BY u.id, u.username
            ORDER BY total_score DESC
            LIMIT 50
        """
        cur.execute(query)
    
    leaderboard = cur.fetchall()
    
    # Add rank
    for idx, entry in enumerate(leaderboard):
        entry['rank'] = idx + 1
    
    cur.close()
    conn.close()
    
    return jsonify(leaderboard), 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=int(os.getenv('PORT', 8080)), debug=False)