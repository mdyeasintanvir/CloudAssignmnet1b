# Lab 5: Build Your DB Server and Interact With Your DB Using an App
### বাংলায় Step-by-Step Guide (AWS Academy, Vocareum)
**Md Yeasin Tanvir · J25045535** · সময় লাগবে ~৩০ মিনিট

> **নিয়ম (খুব জরুরি):**
> - এই lab-এ grader script **নাম আর setting মিলিয়ে নম্বর দেয়**। নিচে `এভাবে` লেখা মানগুলো হুবহু, একই বড়/ছোট হাতের অক্ষরে, space-সহ টাইপ করবেন।
> - Region সবসময় **N. Virginia (us-east-1)**।
> - VPC, subnet, NAT gateway, Web server আগে থেকেই বানানো আছে। **এগুলো নিজে বানাবেন না।**
> - একই জিনিস দুবার বানাবেন না। ভুল হলে পুরোনোটা মুছে তারপর নতুন বানাবেন।

### এক নজরে সব মান
| জিনিস | মান |
|---|---|
| Security group name | `DB Security Group` |
| SG description | `Permit access from Web Security Group` |
| Inbound rule | MySQL/Aurora (3306), Source = **Web Security Group** |
| DB subnet group name | `DB-Subnet-Group` |
| Subnet group description | `DB Subnet Group` |
| Subnet (AZ) | `10.0.1.0/24` (us-east-1a) + `10.0.3.0/24` (us-east-1b) |
| Engine | MySQL, template **Dev/Test**, **Multi-AZ DB instance** |
| DB instance identifier | `lab-db` |
| Master username | `main` |
| Master password | `lab-password` |
| Instance class | Burstable → **db.t3.micro** |
| Storage | General Purpose (SSD), **20** GiB |
| Initial database name | `lab` |

---

## ধাপ 0: Lab চালু করা
1. Vocareum lab পাতার উপরে **▶ Start Lab** চাপুন।
2. বাম দিকে **AWS** লেখার পাশের গোল চিহ্ন 🔴 থেকে 🟢 হওয়া পর্যন্ত অপেক্ষা করুন।
3. **AWS**-এ click করুন। নতুন tab-এ Console খুলবে। (Pop-up block হলে browser-এর উপরে **Allow pop-ups** দিন।)
4. Console-এর উপরে ডানে region **N. Virginia** আছে কিনা দেখে নিন।

---

## Task 1: DB Security Group বানানো
এই security group web server-কে database-এ ঢোকার অনুমতি দেবে।

1. Console-এর উপরের search box-এ **VPC** লিখে খুলুন।
2. বাম দিকের menu থেকে **Security groups** খুলুন।
3. **Create security group** চাপুন, তারপর লিখুন:
   - **Security group name:** `DB Security Group`
   - **Description:** `Permit access from Web Security Group`
   - **VPC:** আগে থেকে যে VPC বাছা আছে তার পাশের **X** চেপে মুছুন, তারপর list থেকে **Lab VPC** বাছুন।
4. **Inbound rules** অংশে **Add rule** চাপুন:
   - **Type:** `MySQL/Aurora` (port 3306 নিজে থেকে বসে যাবে)
   - **Source:** **Custom** রেখে পাশের ঘরে `sg` টাইপ করুন। যে list আসবে তার থেকে **Web Security Group** বাছুন।
5. নিচে **Create security group** চাপুন।

> ⚠️ Source-এ ভুল করে `0.0.0.0/0` বা নিজের IP দেবেন না। **Web Security Group**-ই দিতে হবে, না হলে নম্বর কাটবে।

---

## Task 2: DB Subnet Group বানানো
RDS কোন subnet-এ বসবে সেটা এখানে বলে দিতে হয়। দুটো আলাদা AZ লাগবে।

1. উপরের search box-এ **RDS** লিখে খুলুন।
2. বাম দিকের menu থেকে **Subnet groups** খুলুন। (Menu না দেখা গেলে উপরে বামে **☰** চাপুন।)
3. **Create DB subnet group** চাপুন, তারপর লিখুন:
   - **Name:** `DB-Subnet-Group`
   - **Description:** `DB Subnet Group`
   - **VPC:** **Lab VPC**
4. নিচে **Add subnets** অংশে যান:
   - **Availability Zones:** **us-east-1a** আর **us-east-1b** বাছুন।
   - **Subnets:** যে দুটো subnet-এর CIDR **10.0.1.0/24** আর **10.0.3.0/24**, শুধু সেই দুটো বাছুন। এ দুটো private subnet।
   - নিচে **Subnets selected** table-এ ঠিক এই দুটো দেখাচ্ছে কিনা মিলিয়ে নিন।
5. **Create** চাপুন।

> ⚠️ 10.0.0.0/24 বা 10.0.2.0/24 বাছবেন না। ও দুটো public subnet।

---

## Task 3: RDS Database বানানো (Multi-AZ MySQL)
1. RDS-এর বাম menu থেকে **Databases** খুলুন, তারপর **Create database** চাপুন।
   (উপরে **Switch to the new database creation flow** দেখলে সেটায় click করুন।)
2. **Creation method:** Standard create রাখুন।
3. **Engine options:** **MySQL** বাছুন।
4. **Templates:** **Dev/Test** বাছুন।
5. **Availability and durability:** **Multi-AZ DB instance** বাছুন।
   (**Multi-AZ DB Cluster** নয়। নামে "Instance" আছে এমনটা নেবেন।)
6. **Settings:**
   - **DB instance identifier:** `lab-db`
   - **Master username:** `main`
   - Credentials management **Self managed** রাখুন।
   - **Master password:** `lab-password`
   - **Confirm password:** `lab-password`
7. **Instance configuration:** **Burstable classes (includes t classes)** বাছুন, তারপর dropdown থেকে **db.t3.micro**।
8. **Storage:**
   - **Storage type:** General Purpose SSD (gp2 বা gp3, যেটা আছে)
   - **Allocated storage:** `20`
9. **Connectivity:**
   - **Virtual private cloud (VPC):** **Lab VPC**
   - **DB subnet group:** `db-subnet-group` নিজে থেকেই বসার কথা। না বসলে বেছে দিন। (AWS নামটা ছোট হাতের অক্ষরে দেখায়, এটা স্বাভাবিক।)
   - **Public access:** **No**
   - **Existing VPC security groups:** dropdown থেকে **DB Security Group** বাছুন, আর **default**-এর পাশের **X** চেপে সেটা সরিয়ে দিন।
10. **Monitoring:** খুলে **Enable Enhanced monitoring**-এর ✅ তুলে দিন।
    > এটা না তুললে শেষে **"not authorized to perform: iam:CreateRole"** error আসবে।
11. সবার নিচে **Additional configuration** খুলুন:
    - **Initial database name:** `lab`
    - **Enable automatic backups**-এর ✅ তুলে দিন।
    - **Enable encryption**-এর ✅ তুলে দিন।
12. **Create database** চাপুন।
    (একটা pop-up এলে, যেমন "add-ons" বা "suggested", **Close** চাপুন।)

### DB তৈরি হওয়া পর্যন্ত অপেক্ষা
13. Databases list থেকে **lab-db** লিংকে click করুন।
14. প্রায় **৪ থেকে ১০ মিনিট** লাগবে। Status **Creating** থেকে **Modifying** বা **Available** হওয়া পর্যন্ত অপেক্ষা করুন। মাঝে মাঝে page refresh করুন।
15. **Connectivity & security** tab-এ **Endpoint** কপি করে Notepad-এ রাখুন। দেখতে এরকম হবে:
    `lab-db.xxxxxxxx.us-east-1.rds.amazonaws.com`

---

## Task 4: Web App দিয়ে Database ব্যবহার করা
1. Vocareum lab পাতায় উপরে **ℹ AWS Details** চাপুন। সেখানে **WebServer**-এর IP address কপি করুন।
   (না পেলে: EC2 → Instances → **Web Server** → **Public IPv4 address**।)
2. Browser-এ নতুন tab খুলে IP-টা paste করে Enter চাপুন। যেমন `http://3.xx.xx.xx`
   > ⚠️ `https://` নয়, **`http://`** দিয়ে খুলবেন। না খুললে সামনে নিজে `http://` লিখে দিন।
3. EC2 instance-এর তথ্য দেখানো একটা page খুলবে। উপরে **RDS** লিংকে click করুন।
4. এই মানগুলো দিন:
   - **Endpoint:** Task 3-এ কপি করা endpoint (শুধু hostname দেবেন, সামনে `http://` বা শেষে `:3306` লাগবে না)
   - **Database:** `lab`
   - **Username:** `main`
   - **Password:** `lab-password`
   - তারপর **Submit** চাপুন।
5. কিছুক্ষণ পর একটা **Address Book** দেখাবে। এর মানে app RDS database-এ ডেটা রাখছে।
6. এবার app-টা পরীক্ষা করুন:
   - একটা contact **Add** করুন।
   - একটা contact **Edit** করুন।
   - একটা contact **Remove** করুন।

   এই ডেটা database-এ জমা হচ্ছে, আর নিজে থেকেই দ্বিতীয় AZ-এর standby-তে copy হচ্ছে।

---

## Submit আর Lab শেষ করা
1. Vocareum lab পাতার উপরে **Submit** চাপুন। জিজ্ঞেস করলে **Yes** দিন।
2. কয়েক মিনিট পর নম্বর দেখাবে। না দেখালে **Grades** চাপুন।
3. কোথাও নম্বর কাটলে **Submission Report** খুলে কারণ দেখুন, ঠিক করে আবার **Submit** দিন। শেষ submit-টাই গোনা হয়।
4. সব শেষে **End Lab → Yes** চাপুন, তারপর panel-এর **X** চেপে বন্ধ করুন।

---

## সমস্যা হলে যা করবেন
| সমস্যা | কারণ ও সমাধান |
|---|---|
| Create database চাপলে `iam:CreateRole` error | Enhanced monitoring চালু আছে। Monitoring-এ গিয়ে ✅ তুলে দিয়ে আবার চেষ্টা করুন। |
| Subnet group-এ AZ/subnet খুঁজে পাচ্ছেন না | VPC-তে **Lab VPC** বাছা হয়নি। আগে VPC ঠিক করুন। |
| DB Security Group dropdown-এ নেই | Task 1-এ SG বানানোর সময় VPC ভুল ছিল (default VPC)। SG মুছে Lab VPC-তে আবার বানান। |
| Web app-এ Submit দেওয়ার পর error বা ঘুরতেই থাকে | ১) DB এখনো **Available** হয়নি, অপেক্ষা করুন। ২) Endpoint ভুল কপি হয়েছে। ৩) DB Security Group-এর inbound source **Web Security Group** নয়। ৪) DB-র security group-এ **default** রয়ে গেছে, DB Security Group নেই। DB → **Modify** থেকে ঠিক করুন, তারপর **Apply immediately** দিন। |
| WebServer IP-তে page খুলছে না | `https://` না দিয়ে `http://` দিয়ে খুলুন। Lab-টা চালু আছে কিনা (🟢) দেখুন। |
| Grader "Multi-AZ" নম্বর দিচ্ছে না | Database → **Configuration** tab-এ Multi-AZ = **Yes** আছে কিনা দেখুন। না থাকলে **Modify → Multi-AZ DB instance → Apply immediately**। |
