#!/bin/bash
# Deploys the Photo Album app + configures phpMyAdmin on the Web server.
# 1) Fill in the 9 values below (no spaces in BUCKET/DB names).
# 2) SSH into the Web server and paste this WHOLE script into the terminal.

STUDENT_NAME="Md Yeasin Tanvir"
STUDENT_ID="12345678"
TUTORIAL_SESSION="Monday 10:30AM"
BUCKET_NAME="your-bucket-name"
RDS_ENDPOINT="xxxx.xxxxxxxx.us-east-1.rds.amazonaws.com"
DB_NAME="photoalbum"
DB_USERNAME="admin"
DB_PASSWORD="YourPassword123"
REGION="us-east-1"

APP=/var/www/html/cos20019/photoalbum
sudo mkdir -p $APP
sudo chown -R ec2-user:apache /var/www/html

cat > $APP/constants.php <<EOF
<?php
// Constants for the Photo Album website (see original file for comments)
define('STUDENT_NAME', '$STUDENT_NAME');
define('STUDENT_ID', '$STUDENT_ID');
define('TUTORIAL_SESSION', '$TUTORIAL_SESSION');

define('BUCKET_NAME', '$BUCKET_NAME');
define('REGION', '$REGION');
define('S3_BASE_URL','https://'.BUCKET_NAME.'.s3.amazonaws.com/');

define('DB_NAME', '$DB_NAME');
define('DB_ENDPOINT', '$RDS_ENDPOINT');
define('DB_USERNAME', '$DB_USERNAME');
define('DB_PWD', '$DB_PASSWORD');

define('DB_PHOTO_TABLE_NAME', 'photos');
define('DB_PHOTO_TITLE_COL_NAME', 'title');
define('DB_PHOTO_DESCRIPTION_COL_NAME', 'description');
define('DB_PHOTO_CREATIONDATE_COL_NAME', 'creationdate');
define('DB_PHOTO_KEYWORDS_COL_NAME', 'keywords');
define('DB_PHOTO_S3REFERENCE_COL_NAME', 'reference');
?>
EOF
cat > $APP/album.php <<'PHOTOALBUM_EOF'
<?php
/**
* 	Showing all photos in DB
*
*	@author Swinburne University of Technology
*/
ini_set('display_errors', 1);
require 'mydb.php';
require_once 'constants.php';
?>

<!DOCTYPE html>
<html>
	<head>
		<link rel="stylesheet" href="defaultstyle.css">
		<title>Photo Album</title>
	</head>
	<body>
		<h4>Student name: <?php echo STUDENT_NAME; ?></h4>
		<h4>Student ID: <?php echo STUDENT_ID; ?></h4>
		<h4>Tutorial session: <?php echo TUTORIAL_SESSION; ?></h4><br/>
		<h3>Uploaded photos:</h3>
		<table id="photo_table" border = "1">
		  <tr>
			<th>Photo</th>
			<th>Name</th> 
			<th>Description</th>
			<th>Creation date</th>
			<th>Keywords</th>
		  </tr>
		<?php 
		$my_db = new MyDB();
		$photos = $my_db->getAllPhotos();
		foreach ($photos as $photo) {
			echo "<tr><td><img class = 'photo_cell' src='".$photo->getS3Reference()."' /></td><td>".$photo->getName()."<td>".$photo->getDescription()."</td><td>".$photo->getCreationDate()."</td><td>".$photo->getKeywords()."</td></tr>";
		}
		?>
		</table>
	</body>
</html>
PHOTOALBUM_EOF
cat > $APP/mydb.php <<'PHOTOALBUM_EOF'
<?php
/**
* 	Interacting with MySQL DB in RDS
*
*	@author Swinburne University of Technology
*/
require 'photo.php';
require_once 'constants.php';

class MyDB 
{
	private $dbh; 
	
	// Constructor, establish a connection to the database in RDS
	public function __construct() {
		try {
			$dsn = "mysql:host=".DB_ENDPOINT.";dbname=".DB_NAME;
			$this->dbh = new PDO ( $dsn, DB_USERNAME, DB_PWD );
			$this->dbh->setAttribute ( PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION );
		} catch ( PDOException $e ) {
			error_log($e);
			echo $e;
		}
	}
	
	// Retrieve all records stored in the database table DB_PHOTO_TABLE_NAME. Return an array of Photo objects
	public function getAllPhotos() {
		$photos = array ();
		try {
			$stm = $this->dbh->query ( 'SELECT * FROM ' . DB_PHOTO_TABLE_NAME );
			foreach ( $stm as $row ) {
				array_push ( $photos, new Photo ( $row [DB_PHOTO_TITLE_COL_NAME], 
												$row [DB_PHOTO_DESCRIPTION_COL_NAME],
												$row [DB_PHOTO_CREATIONDATE_COL_NAME],
												$row [DB_PHOTO_KEYWORDS_COL_NAME],
												$row [DB_PHOTO_S3REFERENCE_COL_NAME]) );
			}
			return $photos;
		} catch ( PDOException $e ) {
			error_log($e);
			echo $e;
		}
	}
}
?>
PHOTOALBUM_EOF
cat > $APP/photo.php <<'PHOTOALBUM_EOF'
<?php
/**
* 	Photo class
*
*	@author Swinburne University of Technology
*/
class Photo 
{
	
	private $name;
	private $description;
	private $creation_date;
	private $s3_reference;
	private $keywords;
	
	public function __construct($name, $description, $creation_date, $keywords, $s3_reference) {
		$this->name = $name;
		$this->description = $description;
		$this->creation_date = $creation_date;
		$this->keywords = $keywords;
		$this->s3_reference = $s3_reference;
	}
	
	public function getName() {
		return $this->name;
	}
	
	public function setName($value) {
		$this->name = $value;
	}
	
	public function getDescription() {
		return $this->description;
	}
	
	public function setDescription($value) {
		$this->description = $value;
	}
	
	public function getCreationDate() {
		return $this->creation_date;
	}
	
	public function setCreationDate($value) {
		$this->creation_date = $value;
	}
	
	public function getS3Reference() {
		return $this->s3_reference;
	}
	
	public function setS3Reference($value) {
		$this->s3_reference = $value;
	}
	
	public function getKeywords() {
		return $this->keywords;
	}
	
	public function setKeywords($value) {
		$this->keywords = $value;
	}
}
?>
PHOTOALBUM_EOF
cat > $APP/defaultstyle.css <<'PHOTOALBUM_EOF'
@CHARSET "ISO-8859-1";

.form_border {
	border-style: solid;
	border-width: 1px;
	width: 600px;
	padding: 10px;
	
}

.form_border .form_border_child{
	border-style: solid;
	border-width: 1px;
	padding: 10px;
}

#error_msg {
	color: red;
	display: none;
}

#success_msg {
	color: blue;
	display: none;
}

.photo_cell {
	max-width: 150px; 
	max-height: 150px;
}
PHOTOALBUM_EOF

# phpMyAdmin: point it at the RDS endpoint (step 2 of the phpMyAdmin PDF)
PMA=/var/www/html/phpmyadmin/config.inc.php
if [ -f $PMA ]; then
  sudo sed -i "s/\$cfg\['Servers'\]\[\$i\]\['host'\] = '.*';/\$cfg['Servers'][\$i]['host'] = '$RDS_ENDPOINT';/" $PMA
  SECRET=$(openssl rand -hex 16)
  sudo sed -i "s/\$cfg\['blowfish_secret'\] = '.*';/\$cfg['blowfish_secret'] = '$SECRET';/" $PMA
  grep -E "blowfish_secret|'host'" $PMA
else
  echo "phpMyAdmin not found - check that user data ran (see GUIDE)."
fi

sudo chown -R ec2-user:apache /var/www/html
sudo systemctl restart php-fpm httpd
echo "DONE. Open: http://<ELASTIC-IP>/cos20019/photoalbum/album.php"
