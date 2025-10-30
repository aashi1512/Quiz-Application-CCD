// Update this with your backend URL after deployment
const API_URL = 'http://BACKEND_IP/api'; // Change BACKEND_IP to your actual backend IP

// View management
function showView(viewName) {
    // Hide all views
    document.querySelectorAll('.view').forEach(view => {
        view.classList.remove('active');
    });
    
    // Remove active class from all buttons
    document.querySelectorAll('.nav-btn').forEach(btn => {
        btn.classList.remove('active');
    });
    
    // Show selected view
    document.getElementById(`${viewName}-view`).classList.add('active');
    document.getElementById(`${viewName}-btn`).classList.add('active');
    
    // Load quizzes when list view is shown
    if (viewName === 'list') {
        loadQuizzes();
    }
}

// Load quizzes from backend
async function loadQuizzes() {
    const quizList = document.getElementById('quiz-list');
    quizList.innerHTML = '<p class="loading">Loading quizzes...</p>';
    
    try {
        const response = await fetch(`${API_URL}/quizzes`);
        
        if (!response.ok) {
            throw new Error(`HTTP error! status: ${response.status}`);
        }
        
        const data = await response.json();
        const quizzes = data.quizzes || [];
        
        if (quizzes.length === 0) {
            quizList.innerHTML = '<p class="empty-state">No quizzes yet. Create your first one!</p>';
            return;
        }
        
        // Display quizzes
        quizList.innerHTML = quizzes.map(quiz => `
            <div class="quiz-card" onclick="viewQuiz(${quiz.id})">
                <h3>${escapeHtml(quiz.title)}</h3>
                <p>${escapeHtml(quiz.description || 'No description provided')}</p>
                <div class="quiz-footer">
                    <span class="quiz-date">Created: ${formatDate(quiz.created_at)}</span>
                    <button class="start-btn" onclick="event.stopPropagation(); startQuiz(${quiz.id})">
                        Start Quiz →
                    </button>
                </div>
            </div>
        `).join('');
        
    } catch (error) {
        console.error('Error loading quizzes:', error);
        quizList.innerHTML = `
            <p class="error-state">
                ❌ Failed to load quizzes<br>
                <small>Make sure backend is running at ${API_URL}</small><br>
                <small>Error: ${error.message}</small>
            </p>
        `;
    }
}

// Create new quiz
async function createQuiz(event) {
    event.preventDefault();
    
    const title = document.getElementById('title').value.trim();
    const description = document.getElementById('description').value.trim();
    const submitBtn = event.target.querySelector('.submit-btn');
    const message = document.getElementById('form-message');
    
    // Disable button and show loading
    submitBtn.disabled = true;
    submitBtn.textContent = 'Creating...';
    message.className = 'message';
    message.style.display = 'none';
    
    try {
        const response = await fetch(`${API_URL}/quizzes`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({ title, description })
        });
        
        if (!response.ok) {
            throw new Error(`HTTP error! status: ${response.status}`);
        }
        
        const data = await response.json();
        
        // Success
        message.textContent = '✅ Quiz created successfully!';
        message.className = 'message success';
        
        // Reset form
        document.getElementById('quiz-form').reset();
        
        // Switch to list view after 1.5 seconds
        setTimeout(() => {
            showView('list');
        }, 1500);
        
    } catch (error) {
        console.error('Error creating quiz:', error);
        message.textContent = `❌ Failed to create quiz: ${error.message}`;
        message.className = 'message error';
    } finally {
        submitBtn.disabled = false;
        submitBtn.textContent = 'Create Quiz';
    }
}

// View quiz details
function viewQuiz(quizId) {
    alert(`Quiz ${quizId} details - Feature coming soon!`);
}

// Start quiz
function startQuiz(quizId) {
    alert(`Starting quiz ${quizId} - Feature coming soon!`);
}

// Helper: Escape HTML to prevent XSS
function escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
}

// Helper: Format date
function formatDate(dateString) {
    if (!dateString) return 'Unknown';
    const date = new Date(dateString);
    return date.toLocaleDateString('en-US', { 
        year: 'numeric', 
        month: 'short', 
        day: 'numeric' 
    });
}

// Load quizzes on page load
window.addEventListener('DOMContentLoaded', () => {
    loadQuizzes();
});