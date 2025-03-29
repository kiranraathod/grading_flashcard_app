-- Insert a test user (password: password123)
INSERT INTO users (id, email, password_hash) 
VALUES ('00000000-0000-0000-0000-000000000001', 'test@example.com', '$2b$12$X9MK2M6Ux1cQfQe2RxBYzuQz9GIvIqnCz1MZ8hoFChgwjZpZpVOei');

-- Update profile for test user
UPDATE profiles 
SET 
    display_name = 'Test User',
    level = 1,
    xp = 25,
    max_xp = 100
WHERE id = '00000000-0000-0000-0000-000000000001';

-- Insert a basic flashcard set
INSERT INTO flashcard_sets (id, title, description, is_draft, is_public, user_id) 
VALUES ('00000000-0000-0000-0000-000000000002', 'Basic Concepts', 'A set of basic concept flashcards', FALSE, TRUE, '00000000-0000-0000-0000-000000000001');

-- Insert some flashcards
INSERT INTO flashcards (set_id, question, answer, hint, position) VALUES
('00000000-0000-0000-0000-000000000002', 'What is the capital of France?', 'Paris', 'City of Light', 0),
('00000000-0000-0000-0000-000000000002', 'What is the formula for the area of a circle?', 'A = πr²', 'Uses the radius and pi', 1),
('00000000-0000-0000-0000-000000000002', 'Who wrote "Romeo and Juliet"?', 'William Shakespeare', 'Famous English playwright', 2);
