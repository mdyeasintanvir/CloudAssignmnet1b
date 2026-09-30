# COS20019 Assignment 1B: বাংলায় Step-by-Step Guide (AWS Learner Lab)

> **নিয়ম:** 📸 চিহ্ন দেওয়া জায়গায় screenshot নেবেন। Screenshot-গুলো আমাকে পাঠাবেন, সেগুলো দিয়ে report বানাব।
> প্রতিটা screenshot-এ **উপরে ডান কোণার AWS username/student ID দেখা যেতে হবে** (assignment-এর rule)। তাই পুরো browser window-এর screenshot নেবেন।
> Region সবসময় **N. Virginia (us-east-1)**।
> 💰 **NAT Gateway কখনো বানাবেন না।** এটা দামি, আর বানালে "unnecessary service"-এর জন্য নম্বর কাটবে।

নিচের জায়গায় নিজের তথ্য বসান। উদাহরণ ধরা হয়েছে নাম **Md Yeasin Tanvir**:

| জিনিস | মান |
|---|---|
| VPC নাম | `MTanvirVPC` (নামের প্রথম অক্ষর + LastName + VPC) |
| S3 bucket | `mtanvir-photoalbum-<studentid>` (ছোট হাতের অক্ষরে, কোনো space নয়) |
| DB name | `photoalbum` |
| DB user / pass | `admin` / নিজে একটা password দিন (মনে রাখবেন) |

---

## ধাপ 0: Lab চালু করা
1. Canvas থেকে Learner Lab খুলে **Start Lab** চাপুন। বাম দিকের গোল চিহ্ন সবুজ হলে **AWS** লেখায় click করুন।
2. Lab পাতায় **AWS Details** চেপে **Download PEM** করুন (`labsuser.pem`)। ধাপ 10-এ লাগবে।

## ধাপ 1: VPC
1. **VPC** service খুলে **Your VPCs**, তারপর **Create VPC**।
2. **VPC only** বাছুন। Name: `MTanvirVPC`, IPv4 CIDR: `10.0.0.0/16`। তারপর **Create VPC**।
3. নতুন VPC select করে **Actions → Edit VPC settings**। **Enable DNS hostnames** ✅ দিয়ে Save করুন।
📸 **SS-1:** VPC list, আপনার VPC আর CIDR যেন দেখা যায়।

## ধাপ 2: চারটা Subnet
**Subnets → Create subnet**। VPC হিসেবে আপনার VPC বাছুন, তারপর **Add new subnet** চেপে চারটাই একসাথে বানান:

| Name | AZ | CIDR |
|---|---|---|
| Public Subnet 1 | us-east-1a | 10.0.1.0/24 |
| Private Subnet 1 | us-east-1a | 10.0.3.0/24 |
| Public Subnet 2 | us-east-1b | 10.0.2.0/24 |
| Private Subnet 2 | us-east-1b | 10.0.4.0/24 |

এরপর **Public Subnet 1** select করে **Actions → Edit subnet settings**। **Enable auto-assign public IPv4 address** ✅ দিয়ে Save করুন। **Public Subnet 2**-এর জন্যও একই কাজ করুন।
📸 **SS-2:** Subnet list (নাম, CIDR আর AZ দেখা যায় এমন)।

## ধাপ 3: Internet Gateway
**Internet gateways → Create**। Name: `MTanvirIGW`, তারপর Create। এরপর **Actions → Attach to VPC**, আপনার VPC বাছুন।
📸 **SS-3:** IGW যেখানে "Attached" দেখায়।

## ধাপ 4: Route Tables
1. **Route tables → Create route table**। Name: `PublicRT`, VPC: আপনার VPC।
   - **Routes → Edit routes → Add route**: Destination `0.0.0.0/0`, Target **Internet Gateway** (আপনারটা)। Save করুন।
   - **Subnet associations → Edit**: ✅ Public Subnet 1 আর ✅ Public Subnet 2। Save করুন।
2. আবার **Create route table**। Name: `PrivateRT`, VPC: আপনার VPC। কোনো route যোগ করবেন না, শুধু local route থাকবে।
   - **Subnet associations**: ✅ Private Subnet 1 আর ✅ Private Subnet 2।
📸 **SS-4:** PublicRT-এর Routes tab। 📸 **SS-5:** PublicRT-এর Subnet associations। 📸 **SS-6:** PrivateRT-এর Routes আর Associations।

## ধাপ 5: Security Groups (এই ক্রমেই বানাবেন)
**VPC → Security groups → Create security group**। প্রতিটায় VPC হিসেবে আপনার VPC দেবেন। Outbound rule যেমন আছে তেমন থাকবে।

| SG name | Inbound rules |
|---|---|
| `TestInstanceSG` | Type **All traffic**, Source **Anywhere-IPv4** (0.0.0.0/0) |
| `WebServerSG` | **HTTP** from Anywhere-IPv4; **SSH** from Anywhere-IPv4; **All ICMP - IPv4** with Source = **TestInstanceSG** (source box-এ "sg" লিখলে list থেকে বাছা যাবে) |
| `DBServerSG` | **MySQL/Aurora** (3306), Source = **WebServerSG** |

📸 **SS-7, SS-8, SS-9:** প্রতিটা SG-র Inbound rules tab।

## ধাপ 6: S3 Bucket আর ছবি
1. **S3 → Create bucket**। Name: `mtanvir-photoalbum-<id>`, Region us-east-1।
   **Block all public access**-এর ✅ তুলে দিন, নিচের acknowledge box-এ ✅ দিন। তারপর Create।
2. Bucket খুলে **Upload** চাপুন। ৩–৪টা ছোট `.jpg` ছবি দিন। **File-এর নামে space রাখবেন না** (যেমন `photo1.jpg`)।
3. **Permissions → Bucket policy → Edit**। `scripts/s3-bucket-policy.json` file-এর লেখা paste করুন, আর `BUCKET`-এর জায়গায় আপনার bucket-এর নাম দিন। Save করুন।
   ⚠️ আলাদা আলাদা object-কে public করবেন না (এতে নম্বর কাটবে)। শুধু এই policy দিলেই হবে।
4. যেকোনো একটা ছবি খুলে **Object URL** copy করুন। নতুন browser tab-এ খুললে ছবি দেখা গেলে কাজ ঠিক হয়েছে।
📸 **SS-10:** Bucket-এর objects list। 📸 **SS-11:** Bucket policy। 📸 **SS-12:** Browser-এ Object URL-এ ছবি খোলা।

## ধাপ 7: RDS (সময় লাগে, তাই আগে চালু করে দিন)
1. **RDS → Subnet groups → Create DB subnet group**। Name: `photo-db-subnet-group`, VPC: আপনার VPC। AZ হিসেবে **us-east-1a** আর **us-east-1b**, subnet হিসেবে **10.0.3.0/24** আর **10.0.4.0/24** (দুটোই private)। Create করুন।
2. **Databases → Create database** খুলে নিচের মতো দিন:
   - **Standard create**, Engine **MySQL**, Version **8.4.7** (না থাকলে সবচেয়ে কাছের 8.4.x)
   - Template: **Free tier**
   - DB instance identifier: `photo-db`; Master username: `admin`; Credentials management: **Self managed**; Password: নিজে একটা দিন
   - Instance class: **db.t3.micro** (বা db.t4g.micro); Storage 20 GB; **Enable storage autoscaling ❌**
   - Connectivity: **Don't connect to an EC2**; VPC: আপনার VPC; Subnet group: `photo-db-subnet-group`
   - **Public access: No**
   - VPC security group: **Choose existing → DBServerSG** (**default**-টা ✖ দিয়ে সরিয়ে দিন)
   - Availability Zone: **us-east-1a** (তাহলে DB Private Subnet 1-এ বসবে, diagram-এর মতো)
   - **Additional configuration → Initial database name: `photoalbum`**
   - Enhanced monitoring থাকলে ❌ দিন
3. **Create database** চাপুন। ~১০ মিনিট লাগবে, এর মধ্যে পরের ধাপগুলো করতে থাকুন।
📸 **SS-13:** DB-র **Connectivity & security** tab (endpoint, VPC, subnet group, Public access = No, DBServerSG দেখা যায় এমন)। Endpoint-টা copy করে রাখুন।

## ধাপ 8: Web Server EC2
**EC2 → Launch instance**:
- Name: `WebServer`; AMI: **Amazon Linux 2023**; Instance type: **t3.micro**; Key pair: **vockey**
- **Network settings → Edit**: VPC আপনারটা, Subnet **Public Subnet 2**, Auto-assign public IP **Enable**, **Select existing SG → WebServerSG**
- **Advanced details → User data**: `scripts/webserver-userdata.sh` file-এর পুরো লেখা paste করুন
- **Launch** চাপুন।

## ধাপ 9: Elastic IP
**EC2 → Elastic IPs → Allocate Elastic IP address → Allocate**। তারপর **Actions → Associate**: Instance হিসেবে `WebServer` বাছুন, তারপর Associate।
📸 **SS-14:** EIP যেখানে WebServer-এর সাথে associated দেখায়। 📸 **SS-15:** WebServer instance-এর details (subnet = Public Subnet 2, public IP = EIP)।

## ধাপ 10: Test Instance
**Launch instance**:
- Name: `TestInstance`; AMI: Amazon Linux 2023; Type: **t3.micro**; Key pair: **vockey**
- Network: আপনার VPC, Subnet **Private Subnet 2**, Auto-assign public IP **Disable**, SG **TestInstanceSG**
- Launch করুন। এর **Private IPv4** (10.0.4.x) লিখে রাখুন।
📸 **SS-16:** Instances list (দুটো instance, আর তাদের subnet/IP দেখা যায় এমন)।

## ধাপ 11: Network ACL (৩ নম্বর, খুব জরুরি)
**VPC → Network ACLs → Create network ACL**। Name: `PublicSubnet2NACL`, VPC: আপনার VPC।

**Inbound rules → Edit → Add new rule:**

| Rule # | Type | Port | Source | Allow |
|---|---|---|---|---|
| 100 | SSH | 22 | 0.0.0.0/0 | Allow |
| 110 | HTTP | 80 | 0.0.0.0/0 | Allow |
| 120 | All ICMP - IPv4 | All | **10.0.4.0/24** | Allow |
| 130 | Custom TCP | 1024-65535 | 0.0.0.0/0 | Allow |

**Outbound rules → Edit:**

| Rule # | Type | Port | Destination | Allow |
|---|---|---|---|---|
| 100 | Custom TCP | 1024-65535 | 0.0.0.0/0 | Allow |
| 110 | MySQL/Aurora | 3306 | 10.0.3.0/24 | Allow |
| 120 | MySQL/Aurora | 3306 | 10.0.4.0/24 | Allow |
| 130 | All ICMP - IPv4 | All | 10.0.4.0/24 | Allow |
| 140 | SSH | 22 | 10.0.4.0/24 | Allow |
| 150 | HTTP | 80 | 0.0.0.0/0 | Allow |
| 160 | HTTPS | 443 | 0.0.0.0/0 | Allow |

(কেন দরকার: NACL stateless, তাই reply-র জন্য 1024-65535 খোলা লাগে। 3306 খোলা হয়েছে RDS-এর জন্য, 22 আর ICMP bastion থেকে Test instance-এর জন্য, আর 80/443 package update-এর জন্য।)

**Subnet associations → Edit** → শুধু ✅ **Public Subnet 2**।
📸 **SS-17:** Inbound rules। 📸 **SS-18:** Outbound rules। 📸 **SS-19:** Subnet associations।

## ধাপ 12: Website deploy করা
1. RDS "Available" হওয়া পর্যন্ত অপেক্ষা করুন।
2. **EC2 → WebServer select → Connect → EC2 Instance Connect → Connect**। Browser-এ একটা terminal খুলবে।
3. `scripts/deploy-photoalbum.sh` খুলে উপরের ৯টা মান (নাম, ID, tutorial, bucket, RDS endpoint, DB pass ইত্যাদি) নিজের তথ্য দিয়ে বদলান। তারপর **পুরো script** copy করে terminal-এ paste করে Enter দিন।
4. শেষে `DONE` দেখালে কাজ ঠিক হয়েছে।

## ধাপ 13: phpMyAdmin দিয়ে table বানানো
1. Browser-এ `http://<ELASTIC-IP>/phpmyadmin/` খুলে `admin` আর password দিয়ে login করুন।
2. বাম দিক থেকে **photoalbum** database-এ click করে **SQL** tab খুলুন। `scripts/create_photos_table.sql` file-এর লেখা paste করুন।
   `BUCKET` আর ছবির নামগুলো আপনার S3-এর ছবির সাথে মিলিয়ে দিন (ধাপ 6-এর Object URL), তারপর **Go** চাপুন।
📸 **SS-20:** `photos` table-এর **Structure** tab (৫টা column)। 📸 **SS-21:** **Browse** tab (সব data record)।

## ধাপ 14: Website test
Browser-এ খুলুন: `http://<ELASTIC-IP>/cos20019/photoalbum/album.php`
📸 **SS-22:** Page-এ নাম, ID, ছবি আর metadata সব দেখা যাচ্ছে।

## ধাপ 15: Test Instance-এ SSH আর Ping
WebServer-এর Instance Connect terminal-এ লিখুন:
```bash
nano labsuser.pem        # labsuser.pem file-এর পুরো লেখা paste করুন, তারপর Ctrl+O, Enter, Ctrl+X
chmod 400 labsuser.pem
hostname -I              # WebServer-এর private IP (10.0.2.x) দেখাবে, লিখে রাখুন
ssh -i labsuser.pem ec2-user@<TEST-PRIVATE-IP>     # "yes" লিখুন
```
এখন Test instance-এর ভেতরে আছেন। লিখুন:
```bash
hostname -I              # 10.0.4.x দেখাবে
ping -c 5 <WEBSERVER-PRIVATE-IP 10.0.2.x>
```
📸 **SS-23:** Terminal-এ SSH login আর ping-এর reply (0% packet loss)। Browser-এর উপরের অংশ যেন screenshot-এ আসে।

## ধাপ 16: শেষ কাজ (নম্বর আর dollar বাঁচানোর জন্য)
- **TestInstance → Instance state → Stop** করুন (assignment বলছে test instance চালু রাখার দরকার নেই)।
- কোনো অতিরিক্ত EC2, EIP, bucket বা NAT থাকলে মুছে দিন। দুটো VPC থাকলে ভুলটা মুছে দিন (default VPC যেমন আছে থাকুক)।
- কাজ শেষে Learner Lab-এ **End Lab** চাপুন। EIP থাকায় URL বদলাবে না।

সব screenshot (SS-1 থেকে SS-23) আমাকে পাঠান। কোথাও কোনো সমস্যা হয়ে থাকলে সেটাও লিখে দেবেন, report-এর "Problems faced" অংশে লাগবে। তারপর IEEE PDF বানিয়ে দেব।
