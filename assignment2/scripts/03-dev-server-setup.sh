#!/bin/bash
# Assignment 2 – install the A2 Photo Album on the Dev server (the 1B WebServer).
# Run on the WebServer (EC2 Instance Connect):
#   curl -sL https://raw.githubusercontent.com/mdyeasintanvir/CloudAssignmnet1b/claude/confident-rubin-32gcdv/assignment2/scripts/03-dev-server-setup.sh | bash
# The 1B site in /var/www/html/cos20019/photoalbum is left untouched; DB endpoint, user,
# password, DB name and bucket are copied from its constants.php (password never printed).

STUDENT_NAME="Md Yeasin Tanvir"
STUDENT_ID="106201993 (INTI: J25045535)"
TUTORIAL_SESSION="Monday 10:30AM"

SRC=https://raw.githubusercontent.com/mdyeasintanvir/CloudAssignmnet1b/claude/confident-rubin-32gcdv/assignment2/photoalbum
OLD=/var/www/html/cos20019/photoalbum/constants.php
APP=/var/www/html/photoalbum

echo "== 1/6 PHP extensions needed by the AWS SDK"
PKG=$(command -v dnf || command -v yum)
sudo $PKG install -y -q php-xml php-mbstring unzip wget >/dev/null 2>&1 || echo "   (package install warning - continuing)"

echo "== 2/6 AWS SDK for PHP -> /var/www/html/aws"
if [ ! -f /var/www/html/aws/aws-autoloader.php ]; then
  wget -q -O /tmp/aws.zip https://docs.aws.amazon.com/aws-sdk-php/v3/download/aws.zip \
    && sudo unzip -q -o /tmp/aws.zip -d /var/www/html/aws && rm -f /tmp/aws.zip
fi
[ -f /var/www/html/aws/aws-autoloader.php ] && echo "   OK" || { echo "   FAILED: SDK not installed"; exit 1; }

echo "== 3/6 Photo Album source -> $APP"
sudo mkdir -p $APP/uploads
for f in album.php constants.php defaultstyle.css mydb.php photo.php photouploader.php photouploadtemplate.html utils.php; do
  sudo curl -sfL -o $APP/$f $SRC/$f || { echo "   FAILED to download $f"; exit 1; }
done
echo "   OK"

echo "== 4/6 constants.php (values copied from the 1B site)"
[ -f $OLD ] || { echo "   FAILED: $OLD not found"; exit 1; }
cat > /tmp/fill_constants.php <<'PHP'
<?php
require getenv('OLD');
$file = getenv('APP') . '/constants.php';
$t = file_get_contents($file);
$set = [
  'STUDENT_NAME' => getenv('SN'), 'STUDENT_ID' => getenv('SID'), 'TUTORIAL_SESSION' => getenv('TUT'),
  'BUCKET_NAME' => BUCKET_NAME, 'DB_NAME' => DB_NAME, 'DB_ENDPOINT' => DB_ENDPOINT,
  'DB_USERNAME' => DB_USERNAME, 'DB_PWD' => DB_PWD, 'DB_PHOTO_TABLE_NAME' => 'photos',
];
foreach ($set as $k => $v) {
  $t = preg_replace_callback("/define\('$k',\s*'[^']*'\);/",
         function ($m) use ($k, $v) { return "define('$k', " . var_export($v, true) . ");"; }, $t, 1, $n);
  if (!$n) { fwrite(STDERR, "   MISSING $k\n"); exit(1); }
}
file_put_contents($file, $t);
echo "   OK  bucket=" . BUCKET_NAME . "  db=" . DB_NAME . "@" . DB_ENDPOINT . "  table=photos\n";
PHP
sudo OLD=$OLD APP=$APP SN="$STUDENT_NAME" SID="$STUDENT_ID" TUT="$TUTORIAL_SESSION" php /tmp/fill_constants.php || exit 1
rm -f /tmp/fill_constants.php

echo "== 5/6 permissions, upload size, restart web server"
sudo chown -R apache:apache $APP
sudo chmod 640 $APP/constants.php
sudo chmod 775 $APP/uploads
sudo sed -i 's/^upload_max_filesize = .*/upload_max_filesize = 10M/; s/^post_max_size = .*/post_max_size = 12M/' /etc/php.ini
sudo systemctl restart php-fpm 2>/dev/null; sudo systemctl restart httpd

echo "== 6/6 test http://localhost/photoalbum/album.php"
sleep 2
OUT=$(curl -s http://localhost/photoalbum/album.php)
echo "$OUT" | grep -o "Student [a-zA-Z]*: [^<]*\|Tutorial session: [^<]*"
echo "   photo rows found: $(echo "$OUT" | grep -o "<img" | wc -l)"
echo "$OUT" | grep -i "error\|warning\|fatal" | head -5
echo "DONE"
