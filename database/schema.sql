-- Users table
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Quiz categories table
CREATE TABLE IF NOT EXISTS categories (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Questions table
CREATE TABLE IF NOT EXISTS questions (
    id SERIAL PRIMARY KEY,
    category_id INTEGER REFERENCES categories(id) ON DELETE CASCADE,
    question_text TEXT NOT NULL,
    option_a VARCHAR(255) NOT NULL,
    option_b VARCHAR(255) NOT NULL,
    option_c VARCHAR(255) NOT NULL,
    option_d VARCHAR(255) NOT NULL,
    correct_answer CHAR(1) NOT NULL CHECK (correct_answer IN ('A', 'B', 'C', 'D')),
    difficulty VARCHAR(20) DEFAULT 'medium',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Quiz attempts table
CREATE TABLE IF NOT EXISTS quiz_attempts (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    category_id INTEGER REFERENCES categories(id) ON DELETE CASCADE,
    score INTEGER NOT NULL,
    completed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Indexes for performance
CREATE INDEX idx_questions_category ON questions(category_id);
CREATE INDEX idx_attempts_user ON quiz_attempts(user_id);
CREATE INDEX idx_attempts_category ON quiz_attempts(category_id);
CREATE INDEX idx_attempts_score ON quiz_attempts(score DESC);

-- Sample data: Insert categories
INSERT INTO categories (name, description) VALUES
('Technology', 'Questions about computers, programming, and modern technology'),
('Science', 'Questions about physics, chemistry, biology, and general science'),
('History', 'Questions about world history and historical events'),
('Sports', 'Questions about sports, athletes, and sporting events'),
('Entertainment', 'Questions about movies, music, and pop culture');

-- Sample questions for Technology category
INSERT INTO questions (category_id, question_text, option_a, option_b, option_c, option_d, correct_answer, difficulty) VALUES
(1, 'What does CPU stand for?', 'Central Processing Unit', 'Computer Personal Unit', 'Central Program Utility', 'Central Processor Update', 'A', 'easy'),
(1, 'Which programming language is known as the "language of the web"?', 'Python', 'JavaScript', 'Java', 'C++', 'B', 'easy'),
(1, 'What year was the first iPhone released?', '2005', '2006', '2007', '2008', 'C', 'medium'),
(1, 'What does HTML stand for?', 'Hyper Text Markup Language', 'High Tech Modern Language', 'Home Tool Markup Language', 'Hyperlinks and Text Markup Language', 'A', 'easy'),
(1, 'Who is the founder of Microsoft?', 'Steve Jobs', 'Bill Gates', 'Mark Zuckerberg', 'Elon Musk', 'B', 'easy'),
(1, 'What is the main function of RAM?', 'Permanent storage', 'Temporary storage', 'Processing data', 'Networking', 'B', 'medium'),
(1, 'Which company developed the Android operating system?', 'Apple', 'Microsoft', 'Google', 'Samsung', 'C', 'easy'),
(1, 'What does SQL stand for?', 'Structured Query Language', 'Simple Question Language', 'Structured Question Logic', 'Simple Query Logic', 'A', 'easy'),
(1, 'What is the binary number system base?', '2', '8', '10', '16', 'A', 'medium'),
(1, 'Which of these is NOT a programming paradigm?', 'Object-Oriented', 'Functional', 'Procedural', 'Sequential', 'D', 'hard');

-- Sample questions for Science category
INSERT INTO questions (category_id, question_text, option_a, option_b, option_c, option_d, correct_answer, difficulty) VALUES
(2, 'What is the chemical symbol for water?', 'H2O', 'O2', 'CO2', 'HO2', 'A', 'easy'),
(2, 'What planet is known as the Red Planet?', 'Venus', 'Mars', 'Jupiter', 'Mercury', 'B', 'easy'),
(2, 'What is the speed of light?', '300,000 km/s', '150,000 km/s', '500,000 km/s', '1,000,000 km/s', 'A', 'medium'),
(2, 'How many bones are in the human body?', '206', '208', '210', '204', 'A', 'medium'),
(2, 'What gas do plants absorb from the atmosphere?', 'Oxygen', 'Nitrogen', 'Carbon Dioxide', 'Hydrogen', 'C', 'easy'),
(2, 'What is the center of an atom called?', 'Electron', 'Proton', 'Nucleus', 'Neutron', 'C', 'easy'),
(2, 'What is the largest organ in the human body?', 'Heart', 'Brain', 'Liver', 'Skin', 'D', 'medium'),
(2, 'What is the boiling point of water at sea level?', '100°C', '90°C', '110°C', '120°C', 'A', 'easy'),
(2, 'What is the study of plants called?', 'Zoology', 'Botany', 'Biology', 'Ecology', 'B', 'easy'),
(2, 'How many elements are in the periodic table?', '108', '118', '128', '98', 'B', 'hard');

-- Sample questions for History category
INSERT INTO questions (category_id, question_text, option_a, option_b, option_c, option_d, correct_answer, difficulty) VALUES
(3, 'In which year did World War II end?', '1943', '1944', '1945', '1946', 'C', 'medium'),
(3, 'Who was the first President of the United States?', 'Thomas Jefferson', 'George Washington', 'John Adams', 'Benjamin Franklin', 'B', 'easy'),
(3, 'What ancient wonder was located in Egypt?', 'Hanging Gardens', 'Colossus of Rhodes', 'Great Pyramid', 'Temple of Artemis', 'C', 'easy'),
(3, 'When did India gain independence?', '1945', '1947', '1950', '1952', 'B', 'medium'),
(3, 'Who painted the Mona Lisa?', 'Michelangelo', 'Leonardo da Vinci', 'Raphael', 'Donatello', 'B', 'easy'),
(3, 'What year did the Berlin Wall fall?', '1987', '1988', '1989', '1990', 'C', 'medium'),
(3, 'Who was the first man on the moon?', 'Buzz Aldrin', 'Neil Armstrong', 'Yuri Gagarin', 'John Glenn', 'B', 'easy'),
(3, 'In which country did the Renaissance begin?', 'France', 'Spain', 'Italy', 'England', 'C', 'medium'),
(3, 'What was the name of the ship that brought the Pilgrims to America?', 'Santa Maria', 'Mayflower', 'Discovery', 'Endeavour', 'B', 'easy'),
(3, 'Who was the last Tsar of Russia?', 'Nicholas I', 'Alexander III', 'Nicholas II', 'Peter III', 'C', 'hard');