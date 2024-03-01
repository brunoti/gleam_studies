-- Create Articles table
CREATE TABLE articles (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    title VARCHAR(100),
    content TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create Comments table
CREATE TABLE comments (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    article_id INT,
    comment TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (article_id) REFERENCES articles(id)
);

-- Insert two demo articles
INSERT INTO articles (title, content) VALUES
('First Article', '# First Article\nThis is the first demo article.'),
('Second Article', '# Second Article\nThis is the second demo article.');

-- Insert five comments for each article
INSERT INTO comments (article_id, comment) VALUES
(1, 'Great article!'),
(1, 'Very informative.'),
(1, 'Thanks for sharing.'),
(1, 'Interesting read.'),
(1, 'Looking forward to more articles like this.'),
(2, 'Excellent article!'),
(2, 'Well written.'),
(2, 'Very helpful.'),
(2, 'Good job.'),
(2, 'Keep up the good work.');
