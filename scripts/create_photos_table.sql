-- Run in phpMyAdmin -> select database "photoalbum" -> SQL tab -> Go
CREATE TABLE photos (
  title        VARCHAR(255) NOT NULL,
  description  VARCHAR(255),
  creationdate DATE,
  keywords     VARCHAR(255),
  reference    VARCHAR(255) NOT NULL
);

INSERT INTO photos (title, description, creationdate, keywords, reference) VALUES
('Kangaroo',     'A kangaroo standing in the grass',  '2026-09-01', 'animal, kangaroo, australia', 'https://ytanvir-photoalbum-2026.s3.amazonaws.com/photo1.jpg'),
('Tower Bridge', 'Tower Bridge over the River Thames', '2026-09-10', 'bridge, london, landmark',    'https://ytanvir-photoalbum-2026.s3.amazonaws.com/photo2.jpg'),
('Butterfly',    'A butterfly resting on a flower',    '2026-09-20', 'nature, butterfly, flower',   'https://ytanvir-photoalbum-2026.s3.amazonaws.com/photo3.jpg');

SELECT * FROM photos;
