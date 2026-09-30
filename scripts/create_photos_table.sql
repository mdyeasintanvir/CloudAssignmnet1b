-- Run in phpMyAdmin -> select database "photoalbum" -> SQL tab -> Go
CREATE TABLE photos (
  title        VARCHAR(255) NOT NULL,
  description  VARCHAR(255),
  creationdate DATE,
  keywords     VARCHAR(255),
  reference    VARCHAR(255) NOT NULL
);

-- Example rows: change BUCKET and file names to match what you uploaded to S3
INSERT INTO photos (title, description, creationdate, keywords, reference) VALUES
('Photo One',   'My first photo',  '2026-09-01', 'nature, sky',   'https://BUCKET.s3.amazonaws.com/photo1.jpg'),
('Photo Two',   'My second photo', '2026-09-10', 'city, night',   'https://BUCKET.s3.amazonaws.com/photo2.jpg'),
('Photo Three', 'My third photo',  '2026-09-20', 'food, dinner',  'https://BUCKET.s3.amazonaws.com/photo3.jpg');

SELECT * FROM photos;
