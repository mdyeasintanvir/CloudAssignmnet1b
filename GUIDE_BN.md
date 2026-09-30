# COS20019 Assignment 1B: বাংলায় Step-by-Step Guide (AWS Learner Lab)
**Md Yeasin Tanvir · J25045535**

> **নিয়ম:**
> - 📸 চিহ্ন দেওয়া জায়গায় screenshot নেবেন। **পুরো browser window-এর** screenshot নেবেন, যাতে উপরে ডান কোণার AWS username দেখা যায় (assignment-এর rule)।
> - Region সবসময় **N. Virginia (us-east-1)**।
> - 💰 **NAT Gateway কখনো বানাবেন না।** একই জিনিস দুবার বানাবেন না। দুটোতেই নম্বর কাটে, আর dollar-ও খরচ হয়।

### আপনার নামগুলো (এগুলোই ব্যবহার করবেন)
| জিনিস | মান |
|---|---|
| VPC | `MTanvirVPC` |
| Internet Gateway | `MTanvirIGW` |
| S3 bucket | `mtanvir-photoalbum-j25045535` |
| ছবির file-এর নাম | `photo1.jpg`, `photo2.jpg`, `photo3.jpg` |
| RDS identifier | `photo-db` |
| DB name | `photoalbum` |
| DB username | `admin` |
| DB password | নিজে একটা দিন, যেমন `Tanvir12345` (লিখে রাখবেন) |

---

## ধাপ 0: Lab চালু করা
1. **AWS Academy Canvas → Modules → "Launch AWS Academy Learner Lab"**-এ click করুন।
   (লিংকটা lock থাকলে আগে "Learn how to effectively use..." খুলে দেখুন, তারপর **Module Knowledge Check**-এ ৭০+ নম্বর পান।)
2. উপরে **Start Lab** চাপুন। বাম দিকের **AWS** লেখার পাশের গোল চিহ্ন 🟢 হলে **AWS**-এ click করুন। Console খুলবে।
3. Lab পাতায় **AWS Details → Download PEM** চেপে `labsuser.pem` নামিয়ে রাখুন (ধাপ 15-এ লাগবে)।
4. Console-এর উপরে ডান দিকে region **N. Virginia** আছে কিনা দেখে নিন।

## ধাপ 1: VPC
1. উপরের search box-এ **VPC** লিখে খুলুন, তারপর **Your VPCs → Create VPC**।
2. **VPC only** বাছুন। Name tag: `MTanvirVPC`, IPv4 CIDR: `10.0.0.0/16`, তারপর **Create VPC**।
3. VPC select করে **Actions → Edit VPC settings → Enable DNS hostnames ✅ → Save**।

📸 **SS-1:** VPC list, যেখানে MTanvirVPC আর 10.0.0.0/16 দেখা যায়।

## ধাপ 2: চারটা Subnet
**Subnets → Create subnet**। VPC ID-তে `MTanvirVPC` বাছুন। প্রথমটা লিখে **Add new subnet** চেপে বাকিগুলো যোগ করুন, তারপর **Create subnet**:

| Subnet name | Availability Zone | IPv4 subnet CIDR |
|---|---|---|
| Public Subnet 1 | us-east-1a | 10.0.1.0/24 |
| Public Subnet 2 | us-east-1b | 10.0.2.0/24 |
| Private Subnet 1 | us-east-1a | 10.0.3.0/24 |
| Private Subnet 2 | us-east-1b | 10.0.4.0/24 |

এরপর **Public Subnet 1** select করে **Actions → Edit subnet settings → Enable auto-assign public IPv4 address ✅ → Save**। **Public Subnet 2**-এর জন্যও একই কাজ করুন।

📸 **SS-2:** Subnet list (৪টা subnet, CIDR আর AZ দেখা যায় এমন)।

## ধাপ 3: Internet Gateway
**Internet gateways → Create internet gateway**। Name: `MTanvirIGW`, তারপর Create।
তারপর **Actions → Attach to VPC → MTanvirVPC → Attach**।

📸 **SS-3:** IGW, যেখানে State = **Attached**।

## ধাপ 4: Route Tables
**A. Public route table**
1. **Route tables → Create route table**। Name: `PublicRT`, VPC: `MTanvirVPC`, তারপর Create।
2. **Routes tab → Edit routes → Add route**: Destination `0.0.0.0/0`, Target **Internet Gateway → MTanvirIGW**, তারপর Save।
3. **Subnet associations tab → Edit subnet associations**: ✅ Public Subnet 1, ✅ Public Subnet 2, তারপর Save।

**B. Private route table**
1. **Create route table**। Name: `PrivateRT`, VPC: `MTanvirVPC`, তারপর Create। (কোনো route যোগ করবেন না।)
2. **Subnet associations → Edit**: ✅ Private Subnet 1, ✅ Private Subnet 2, তারপর Save।

📸 **SS-4:** PublicRT → Routes। 📸 **SS-5:** PublicRT → Subnet associations। 📸 **SS-6:** PrivateRT → Routes আর Subnet associations।

## ধাপ 5: Security Groups (এই ক্রমেই বানাবেন)
**VPC → Security groups → Create security group**। প্রতিটায় VPC হিসেবে `MTanvirVPC` দেবেন। Outbound rules যেমন আছে তেমন থাকবে।

**1. `TestInstanceSG`** (Description: Test instance SG)
- Inbound: Type **All traffic**, Source **Anywhere-IPv4**

**2. `WebServerSG`** (Description: Web server SG)
- Inbound: **HTTP**, Source **Anywhere-IPv4**
- Inbound: **SSH**, Source **Anywhere-IPv4**
- Inbound: **All ICMP - IPv4**, Source: **Custom** বাছুন, box-এ `sg` লিখে list থেকে **TestInstanceSG** বাছুন

**3. `DBServerSG`** (Description: Database SG)
- Inbound: **MYSQL/Aurora** (3306), Source: Custom → **WebServerSG**

📸 **SS-7, SS-8, SS-9:** তিনটা SG-র Inbound rules tab।

## ধাপ 6: S3 Bucket আর ছবি
1. **S3 → Create bucket**। Bucket name: `mtanvir-photoalbum-j25045535`।
2. **Block all public access**-এর ✅ তুলে দিন, নিচের **"I acknowledge..."** box-এ ✅ দিন। তারপর **Create bucket**।
3. Bucket খুলে **Upload → Add files**। ৩টা ছোট ছবি দিন, নাম হবে **`photo1.jpg`, `photo2.jpg`, `photo3.jpg`** (upload-এর আগে computer-এ rename করে নিন)। তারপর **Upload**।
4. **Permissions tab → Bucket policy → Edit**। `scripts/s3-bucket-policy.json` file-এর পুরো লেখা paste করে **Save changes**।
   ⚠️ আলাদা আলাদা ছবিকে public করবেন না। শুধু এই policy দিলেই হবে।
5. `photo1.jpg`-এ click করে **Object URL** নতুন tab-এ খুলুন। ছবি দেখা গেলে কাজ ঠিক হয়েছে।

📸 **SS-10:** Objects list। 📸 **SS-11:** Bucket policy। 📸 **SS-12:** Browser-এ Object URL দিয়ে খোলা ছবি।

## ধাপ 7: RDS Database (~১০ মিনিট লাগে, তাই আগে চালু করে দিন)
**A. Subnet group**
**RDS → Subnet groups → Create DB subnet group**:
- Name `photo-db-subnet-group`, Description `private subnets`, VPC `MTanvirVPC`
- Availability Zones: **us-east-1a**, **us-east-1b**
- Subnets: **10.0.3.0/24**, **10.0.4.0/24**, তারপর Create

**B. Database**
**RDS → Databases → Create database**:
- **Standard create** → Engine **MySQL** → Engine version **MySQL 8.4.7** (না থাকলে সবচেয়ে কাছের 8.4.x)
- Templates: **Free tier**
- DB instance identifier: `photo-db`; Master username: `admin`; Credentials management: **Self managed**; Master password: আপনার password (দুবার)
- Instance class: **db.t3.micro** (বা db.t4g.micro)
- Storage: 20 GB; **Additional storage configuration → Enable storage autoscaling ❌**
- Connectivity: **Don't connect to an EC2 compute resource**; VPC: `MTanvirVPC`; DB subnet group: `photo-db-subnet-group`
- **Public access: No**
- VPC security group: **Choose existing → DBServerSG** (**default**-এর পাশে ✖ দিয়ে সরিয়ে দিন)
- Availability Zone: **us-east-1a**
- Monitoring: **Enhanced monitoring ❌**
- **Additional configuration → Initial database name: `photoalbum`**
- **Create database** চাপুন।

(অপেক্ষা না করে ধাপ 8-এ চলে যান।)

## ধাপ 8: Web Server EC2
**EC2 → Instances → Launch instances**:
- Name: `WebServer`
- AMI: **Amazon Linux 2023 AMI**
- Instance type: **t3.micro**
- Key pair: **vockey**
- **Network settings → Edit**:
  - VPC: `MTanvirVPC`, Subnet: **Public Subnet 2**, Auto-assign public IP: **Enable**
  - Firewall: **Select existing security group → WebServerSG**
- **Advanced details** → নিচে **User data** box-এ `scripts/webserver-userdata.sh`-এর পুরো লেখা paste করুন
- **Launch instance** চাপুন।

## ধাপ 9: Elastic IP
**EC2 → Elastic IPs → Allocate Elastic IP address → Allocate**।
তারপর নতুন IP select করে **Actions → Associate Elastic IP address → Instance: WebServer → Associate**।
**এই IP-টা লিখে রাখুন। এটাই আপনার website-এর address।**

📸 **SS-13:** Elastic IP, যেখানে WebServer-এর সাথে associated দেখায়।

## ধাপ 10: Test Instance
**Launch instances**:
- Name: `TestInstance`; AMI: **Amazon Linux 2023**; Type: **t3.micro**; Key pair: **vockey**
- Network → Edit: VPC `MTanvirVPC`, Subnet **Private Subnet 2**, Auto-assign public IP **Disable**, SG **TestInstanceSG**
- Launch করুন। Instance-এর **Private IPv4 address** (10.0.4.x) লিখে রাখুন।

📸 **SS-14:** Instances list (দুটো instance Running)। 📸 **SS-15:** WebServer-এর Details (Subnet = Public Subnet 2, Public IP = Elastic IP)। 📸 **SS-16:** TestInstance-এর Details (Subnet = Private Subnet 2)।

## ধাপ 11: Network ACL (৩ নম্বর)
**VPC → Network ACLs → Create network ACL**। Name: `PublicSubnet2NACL`, VPC: `MTanvirVPC`, তারপর Create।
Select করে **Inbound rules → Edit inbound rules → Add new rule**:

| Rule number | Type | Port range | Source | Allow/Deny |
|---|---|---|---|---|
| 100 | SSH (22) | 22 | 0.0.0.0/0 | Allow |
| 110 | HTTP (80) | 80 | 0.0.0.0/0 | Allow |
| 120 | All ICMP - IPv4 | All | **10.0.4.0/24** | Allow |
| 130 | Custom TCP | 1024-65535 | 0.0.0.0/0 | Allow |

**Outbound rules → Edit outbound rules**:

| Rule number | Type | Port range | Destination | Allow/Deny |
|---|---|---|---|---|
| 100 | Custom TCP | 1024-65535 | 0.0.0.0/0 | Allow |
| 110 | MySQL/Aurora | 3306 | 10.0.3.0/24 | Allow |
| 120 | MySQL/Aurora | 3306 | 10.0.4.0/24 | Allow |
| 130 | All ICMP - IPv4 | All | 10.0.4.0/24 | Allow |
| 140 | SSH (22) | 22 | 10.0.4.0/24 | Allow |
| 150 | HTTP (80) | 80 | 0.0.0.0/0 | Allow |
| 160 | HTTPS (443) | 443 | 0.0.0.0/0 | Allow |

**Subnet associations → Edit subnet associations** → শুধু ✅ **Public Subnet 2**, তারপর Save।

📸 **SS-17:** Inbound rules। 📸 **SS-18:** Outbound rules। 📸 **SS-19:** Subnet associations।

## ধাপ 12: Website deploy করা
1. **RDS → Databases → photo-db**-এর Status **Available** হওয়া পর্যন্ত অপেক্ষা করুন।
   📸 **SS-20:** photo-db → **Connectivity & security** tab (Endpoint, VPC, Subnet group, Public access = No, DBServerSG দেখা যায় এমন)।
   **Endpoint**-টা copy করে রাখুন।
2. `scripts/deploy-photoalbum.sh` খুলে শুধু এই ৩টা লাইন বদলান:
   - `TUTORIAL_SESSION="..."`: আপনার tutorial-এর দিন আর সময়
   - `RDS_ENDPOINT="..."`: উপরে copy করা endpoint
   - `DB_PASSWORD="..."`: RDS-এর password
3. **EC2 → WebServer select → Connect → EC2 Instance Connect tab → Connect**। নতুন tab-এ একটা কালো terminal খুলবে।
4. পুরো script copy করে terminal-এ paste করুন (right-click → Paste বা Ctrl+Shift+V), তারপর Enter দিন। শেষে **`DONE`** দেখাবে।

## ধাপ 13: phpMyAdmin দিয়ে table বানানো
1. Browser-এ `http://<ELASTIC-IP>/phpmyadmin/` খুলুন। Username `admin` আর আপনার password দিয়ে **Log in** করুন।
2. বাম দিকে **photoalbum**-এ click করে উপরের **SQL** tab খুলুন।
3. `scripts/create_photos_table.sql`-এর পুরো লেখা paste করে **Go** চাপুন।

📸 **SS-21:** `photos` table → **Structure** tab (৫টা column)। 📸 **SS-22:** **Browse** tab (৩টা record)।

## ধাপ 14: Website test
Browser-এ `http://<ELASTIC-IP>/cos20019/photoalbum/album.php` খুলুন।
নাম, ID, tutorial, ৩টা ছবি আর তাদের তথ্য দেখা গেলে ✅।

📸 **SS-23:** album.php page (উপরে address bar যেন দেখা যায়)।

## ধাপ 15: Test Instance-এ SSH আর Ping
1. Computer-এ `labsuser.pem` Notepad দিয়ে খুলে **সব লেখা copy করুন** (`-----BEGIN` থেকে `END...-----` পর্যন্ত)।
2. WebServer-এর Instance Connect terminal-এ একটা একটা করে লিখুন:
```bash
nano labsuser.pem
```
   এখন paste করুন, তারপর **Ctrl+O → Enter → Ctrl+X**।
```bash
chmod 400 labsuser.pem
hostname -I
```
   (এটা WebServer-এর private IP, 10.0.2.x। লিখে রাখুন।)
```bash
ssh -i labsuser.pem ec2-user@10.0.4.x
```
   (`10.0.4.x`-এর জায়গায় TestInstance-এর আসল IP দিন। প্রশ্ন এলে `yes` লিখুন।)
3. এখন আপনি TestInstance-এর ভেতরে। লিখুন:
```bash
hostname -I
ping -c 5 10.0.2.x
```
   (`10.0.2.x`-এর জায়গায় WebServer-এর private IP দিন।)

📸 **SS-24:** Terminal-এ SSH login আর ping-এর reply (**0% packet loss**)।

## ধাপ 16: শেষ কাজ
- **TestInstance → Instance state → Stop**।
- EC2, VPC, RDS আর Elastic IP-এর list দেখে নিন, দুবার বানানো কিছু থাকলে মুছে দিন। (Default VPC যেমন আছে থাকুক।)
- **WebServer, RDS, S3 আর Elastic IP মুছবেন না।** Tutor-কে website দেখতে হবে।
- Learner Lab-এ **End Lab** চাপুন। (পরে Start Lab চাপলে সব আবার চালু হবে, Elastic IP বদলাবে না।)

---
**সব screenshot (SS-1 থেকে SS-24) আর Elastic IP আমাকে পাঠান। কোনো সমস্যা হয়ে থাকলে সেটাও লিখবেন। তারপর IEEE PDF report বানিয়ে দেব।**
