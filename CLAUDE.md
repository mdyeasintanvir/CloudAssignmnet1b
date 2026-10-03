# COS20019 Cloud Computing — student context (read this first)

Student: Md Yeasin Tanvir · Swinburne ID **106201993** (INTI ID J25045535) · Tutorial shown as "Monday 10:30AM" (not confirmed by student).
Talk to the student in **Bangla** (they write Bangla/Banglish). They are not technical: give one small step at a time,
say exactly where to click, ask for a screenshot after each step, explain errors calmly.

## TOP PRIORITY: save AWS Learner Lab credit
- Budget: $50 total for **all** assignments (1B, 2, 3). ~**$11 already used** after 1B; **$13.4 used** after A2 build day (2026-10-02, End Lab done) (most of it from a NAT Gateway
  that a previous ChatGPT session created and left running).
- Never suggest anything costly without stating the cost first. Prefer:
  - **NAT instance** over NAT Gateway (NAT GW keeps billing after End Lab, ~$1.2/day).
  - t3.micro / db.t3.micro, min-size ASGs, single-AZ RDS, no Multi-AZ, backups 0.
  - Create always-on things (ALB, NAT GW, Elastic IPs) **last**, delete them as soon as marking is done.
  - Reuse existing resources (VPC, RDS, S3) instead of duplicates; duplicates also lose marks.
- **End Lab does NOT stop:** ALB, NAT Gateway, Elastic IPs/public IPv4, EBS/snapshot/RDS storage (RDS may keep running).
- The student also uses ChatGPT in parallel; it has given wrong info (wrong IP 35.153.228.229, deleted DB `photo-db`).
  Always verify real state with read-only CloudShell `describe` commands before acting. Before running anything that
  deletes or changes resources, explain it and get a yes.
- Audit command (read-only), paste in CloudShell:
  ```
  export AWS_PAGER=""
  aws ec2 describe-nat-gateways --filter Name=state,Values=available,pending --query 'NatGateways[].[NatGatewayId,VpcId]' --output table
  aws rds describe-db-instances --query 'DBInstances[].[DBInstanceIdentifier,DBInstanceStatus]' --output table
  aws ec2 describe-instances --query 'Reservations[].Instances[].[Tags[?Key==`Name`]|[0].Value,State.Name]' --output table
  aws ec2 describe-addresses --query 'Addresses[].[PublicIp,InstanceId]' --output table
  aws elbv2 describe-load-balancers --query 'LoadBalancers[].[LoadBalancerName,State.Code]' --output table
  ```

## Assignment 1B — DONE (report submitted-ready), current AWS state (us-east-1)
| Resource | Value |
|---|---|
| VPC | YTanvirVPC `vpc-0b276269b60f2e3f3`, 10.0.0.0/16, DNS hostnames on |
| Subnets | PublicSubnet1 10.0.1.0/24 (1a), PublicSubnet2 10.0.2.0/24 (1b) `subnet-041e48cadf794c973`, PrivateSubnet1 10.0.3.0/24 (1a), PrivateSubnet2 10.0.4.0/24 (1b) `subnet-0827b114a73517a60` |
| IGW | `igw-0d7be2a9567704e58` |
| Route tables | Public RT `rtb-063195b4a9a899c7e` (0.0.0.0/0→IGW); Private RT `rtb-00be7b9b9bf9c924a` (local only; a stray NAT route was removed 2026-10-02) |
| SGs | TestInstanceSG `sg-010bf92e683cfb23c` (all from 0.0.0.0/0); WebServerSG `sg-04c95e2290ce3a971` (HTTP+SSH any, ICMP from TestInstanceSG); DBServerSG `sg-00c90d6875594ac9d` (3306 from WebServerSG) |
| NACL | PublicSubnet2NACL `acl-0d6a325b4cf67a78a` on PublicSubnet2 only (see report Table IX/X) |
| S3 | `ytanvir-photoalbum-2026`, public read via bucket policy, photo1/2/3.jpg |
| RDS | `photodb` MySQL 8.4.7 db.t3.micro, subnet group `photo-db-subnet-group` (private only), DB `photoalbum`, table `photos`, user `admin` (password: ask the student, never store it in the repo) |
| EC2 | WebServer `i-01cc5ea28b989ceab` 10.0.2.57, **Elastic IP 44.217.73.92**; TestInstance `i-01d837294b03b356c` 10.0.4.88 (stopped) |
| URL | http://44.217.73.92/cos20019/photoalbum/album.php |
| Leftovers | Assignment 1A instance `i-0919f71ec864f60c3` (stopped) + its EIP 35.153.228.229 in the default VPC — 1A is graded; student chose NOT to delete (2026-10-02), both instances stopped to save credit |
| Deleted | NAT GW `nat-1aa8051c9741d4b85` and its 2 IPs; duplicate MTanvirVPC; old RDS `photo-db`; PublicServer1 |

- Report: IEEE two-column, 14 pages, `report/build_ieee.py` → PDF (report/ is git-ignored because screenshots show account info).
- If the site is down: Start Lab → EC2 start WebServer → RDS start photodb.
- Do not change 1B resources until 1B is marked (Assignment 2 builds on them).

## Assignment 2 — BUILT, REPORT v1 DONE, AWS TORN DOWN (only submission left) (started 2026-10-02; 1B not yet marked → don't break the 1B site)
Progress: audit done (no NAT GW/ALB; photodb available; WebServer running; 1A instance + TestInstance stopped). Lambda CreateThumbnail DONE (py3.12 arm64, LabRole, timeout 30s, zip uploaded, test event TestPNG on s3 test.png succeeded). resized-test.png verified. New SGs: ELBSG `sg-09961d2b0fee3cc41` (80 from 0.0.0.0/0), NATServerSG `sg-02648b9489c83ca38` (80+443 from WebServerSG), DevServerSG `sg-0165235f80df18417` (22,80,ICMP any). NAT instance DONE: NATServer `i-09fb44b46bfb199cd` t3.micro PublicSubnet1 `subnet-01ab3ffb57ef6d9a5` 10.0.1.240 (public IP changes on restart), SourceDestCheck=false, launched via CLI because console hides the deprecated AMI. Private RT route 0.0.0.0/0→NAT NOT yet added (deferred, 1B not marked; add before ASG). LabInstanceProfile attached to WebServer (2026-10-02). Student ID on site: "106201993 (INTI: J25045535)"; tutorial still unknown (placeholder Monday 10:30AM, must fix before AMI). A2 photoalbum installed on WebServer (03-dev-server-setup.sh ran OK, album shows 3 rows) at http://44.217.73.92/photoalbum/album.php. Upload tested OK: photo4.png -> S3 + RDS row + resized-photo4.png by Lambda. Cleanup TODO before report: duplicate "sunset" row for photo4.jpg (first try was a PNG renamed .jpg -> Lambda RGBA error), S3 objects photo4.jpg, test.png, resized-test.png. AMI PhotoAlbumAMI `ami-01493eaf73a478171` + launch template PhotoAlbumLT `lt-0ed7fc36533ff7df5` DONE (04 script). 05 script DONE: PrivateSubnetsNACL `acl-0fd72c14a44514f40` on both private subnets, private RT `rtb-00be7b9b9bf9c924a` 0.0.0.0/0->NAT, PhotoAlbumTG, PhotoAlbumALB (http://PhotoAlbumALB-129891186.us-east-1.elb.amazonaws.com/photoalbum/album.php), PhotoAlbumASG min2 max3 + RequestCountPerTarget30. Site via ELB verified working (targets i-009ad0e08c338090a, i-056f834ff1c53a7cc healthy). 06 script DONE: DBServerSG 3306 from WebServerSG+DevServerSG; Dev server now DevServerSG only; WebServerSG = 80 from ELBSG + ICMP from DevServerSG; S3 policy GetObject only with Referer http://photoalbumalb-129891186.../* or http://44.217.73.92/* (old policy in CloudShell ~/old-bucket-policy.json). Tests DONE: upload via ELB (grey.png -> resized-grey.png, proves NAT path), direct S3 URL AccessDenied, NACL before/after ping proof (rule 100 removed -> 0% loss, restored -> 100% loss; rules restored 2026-10-02). Note Dev server is in PublicSubnet2 whose 1B NACL only allows ICMP with 10.0.4.0/24 (so ping 8.8.8.8 fails, expected). ASG instances at that time: 10.0.3.244 (1a), 10.0.4.183 (1b). ASG self-heal test DONE (terminated i-056f834ff1c53a7cc -> replacement i-0c4340ec9a397bf1d in 1b). Cleanup DONE (photo4.jpg row deleted; S3 photo4.jpg, test.png, resized-test.png removed). phpMyAdmin screenshot DONE (5 rows). 1B site checked OK after all changes. Console screenshots DONE (VPC+ELB resource maps, ASG, AMI, route tables, NACL, S3 policy, LabRole). 07-pause-alb-asg.sh ran 2026-10-02 (ALB + ASG deleted; TG, LT, AMI, NAT, NACL, SGs kept). TO RESUME before 19 Oct: Start Lab -> 05 script -> 06 script (new ALB DNS into S3 policy) -> update report URL. REPORT v2 (IEEE two-column, A4, dedicated title page, rubric-ordered, 12 pages after student asked for 10-12 (9 full-width figs, image+caption kept together), 32 figs, 4 tables) built 2026-10-03 by report/a2/build_ieee_a2.py -> COS20019_Assignment2_IEEE.docx/.pdf (student said v1 was not IEEE). v1 (superseded): report/a2/build_report.py (git-ignored dir) -> COS20019_Assignment2_Report.docx/.pdf, 12 pages, IEEE one-column, 24 figs; screenshots came from student docx + chat images (in session temp, not in repo). When ALB is re-created: update ELB URL on title page + Section I (edit the docx, or re-upload screenshots and rebuild). COST PLAN: after screenshots delete ALB+ASG (ALB ~$0.80/day even after End Lab), recreate with 05 script 1-2 days before 19 Oct; rebuild AMI if tutorial time differs.

### Plan agreed
Spec: Assignment2_UG_v6.2 (HA Photo Album: IAM via existing **LabRole**, S3 bucket policy restricted by HTTP referer,
Lambda `CreateThumbnail` Python 3.12 arm64, custom AMI, launch template, ASG min 2 max 3 in private subnets with
target tracking 30 requests/target, ALB with health check `/photoalbum/album.php`, NAT in Public Subnet 1,
5 SGs least-privilege (ELBSG, WebServerSG, DBServerSG, NATServerSG, DevServerSG), PrivateSubnetsNACL blocking ICMP
to/from Dev server, report needs VPC + ELB resource maps and a section on how credit use was minimised).
Cost plan (estimate ~$8–12): reuse 1B VPC/RDS/S3, reuse 1B WebServer as Dev server, **NAT instance** (AMI
ami-00a36856283d67c39, source/dest check off) not NAT Gateway, t3.micro everywhere, build ALB last, End Lab between
sessions, tear everything down right after marking.

## TEARDOWN DONE 2026-10-03 (08-teardown-costly.sh): both EIPs released, NATServer/WebServer/TestInstance/1A instance terminated, RDS photodb deleted (no snapshot), PhotoAlbumAMI + snap-03738ac1f8a9bfbf6 deleted, private NAT route removed. Remaining (free): VPC/subnets/IGW/RTs, SGs, NACLs, S3 bucket (few photos), Lambda, launch template (points to deleted AMI), target group. 1B and A2 sites no longer exist (tutor only needs screenshots). The table below is now HISTORICAL.

## (historical) WHAT WAS OFF (2026-10-03) — student asked: remember this, turn back on only when they ask
| Item | State | How to turn back on |
|---|---|---|
| COS20019-PhotoAlbum (1A) `i-0919f71ec864f60c3` | stopped by us | `aws ec2 start-instances --instance-ids i-0919f71ec864f60c3` (only if student asks) |
| TestInstance (1B) `i-01d837294b03b356c` | stopped by us | `aws ec2 start-instances --instance-ids i-01d837294b03b356c` (only if needed) |
| PhotoAlbumALB + PhotoAlbumASG (+2 web servers) | DELETED by 07 script | Start Lab, then CloudShell: `curl -sL <raw>/assignment2/scripts/05-nacl-nat-route-alb-asg.sh \| bash` then `.../06-tighten-sg-s3-policy.sh \| bash` (06 puts the NEW ALB DNS in the S3 policy); new URL -> report title page + Section I |
| NATServer `i-09fb44b46bfb199cd`, WebServer/Dev `i-01cc5ea28b989ceab` | stopped by End Lab | Start Lab restarts them automatically (check with audit command; start manually if not) |
| Kept (cheap): AMI, LT, PhotoAlbumTG, SGs, NACL, Lambda, S3, RDS photodb, 2 EIPs | on | RDS may keep running after End Lab -> check credit next day ($13.4 on 2026-10-02; >$14.2 next day means RDS running) |
Raw base URL: https://raw.githubusercontent.com/mdyeasintanvir/CloudAssignmnet1b/claude/confident-rubin-32gcdv
TUTOR ANSWER (WhatsApp 2026-10-03): "Can delete boss. Everything. I just need the screenshot." -> no need to re-create ALB; report URL stays as the (deleted) ALB DNS. Teardown script ready: assignment2/scripts/08-teardown-costly.sh (EIPs, 4 instances, RDS, AMI+snapshot, NAT route; keeps free VPC/SG/S3/Lambda/LT/TG in case A3 needs them) — run ONLY after student says yes.

## Assignment 3 — not seen yet. Ask for the spec PDF, estimate cost before starting.

## Files in this repo
- `GUIDE_BN.md` — 1B step-by-step guide in Bangla
- `scripts/` — 1B user data, deploy script, SQL, bucket policy, CloudShell EC2/NACL scripts
- `photoalbum/` — provided 1B PHP source
- `docs/Assignment2_UG_v6.2.pdf` — Assignment 2 spec (full)
- `assignment2/photoalbum/` — provided A2 PHP source (8 files; edit only constants.php: set DB_PHOTO_TABLE_NAME='photos', 1B table columns already match)
- `assignment2/lambda/lambda-deployment-package-0.2.zip` — CreateThumbnail package (PNG only, writes resized-<name>)
