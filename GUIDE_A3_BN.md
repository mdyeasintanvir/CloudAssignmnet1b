# Assignment 3 — ধাপে ধাপে গাইড (বাংলায়)

Spec: `Assignment3_UG_v5.0` — **Serverless/Event-driven Architectural Design Report**

## আগে জেনে রাখো (সবচেয়ে গুরুত্বপূর্ণ)
- এটা **শুধু একটা ডিজাইন রিপোর্ট**। AWS-এ কিছু বানাতে হবে না → **Learner Lab credit খরচ $0**। Lab চালু করারও দরকার নেই।
- **গ্রুপ কাজ**: ৩–৪ জন। Canvas → People → *Assignment 3 – Groups* এ গ্রুপ বানাও, screenshot টিউটরকে পাঠাও **Week 10 শেষ হওয়ার আগে**।
- জমা: **একটা PDF, সর্বোচ্চ ১৫ পেজ, IEEE Conference style** (১ বা ২ কলাম)। গ্রুপের **একজন** জমা দেবে।
- Deadline: **Week 12-এর সোমবার সকাল ৯টা (AEST)**। Late/extension **নেই**।
- Week 12-এ **সবার presentation/interview** — প্রত্যেকে ৩ মিনিট পর্যন্ত; রিপোর্ট আর ডায়াগ্রাম দেখিয়ে প্রশ্নের উত্তর দিতে হবে।
- রিপোর্টে **কে কোন কাজ করেছে** তার একটা টেবিল থাকতে হবে।

## ধাপের তালিকা
| # | কাজ | কে |
|---|---|---|
| 1 | গ্রুপ বানানো + টিউটরকে screenshot | সবাই |
| 2 | কাজ ভাগ করা (নিচের টেবিল) | সবাই |
| 3 | আর্কিটেকচার ঠিক করা (নিচে প্রস্তাব আছে) | সবাই মিলে |
| 4 | draw.io-তে আর্কিটেকচার ডায়াগ্রাম | সদস্য A |
| 5 | দুটো UML collaboration diagram (Upload, Processing) | সদস্য B |
| 6 | প্রতিটা সার্ভিসের বর্ণনা + কেন ব্যবহার | সদস্য C |
| 7 | Design rationale + alternatives তুলনা | সদস্য C/D |
| 8 | AWS Pricing Calculator দিয়ে খরচের হিসাব (fixed + variable) | সদস্য D |
| 9 | IEEE টেমপ্লেটে সব জোড়া লাগানো, ≤15 পেজ, references | একজন editor |
| 10 | Presentation প্র্যাকটিস (সবাই সব অংশ বুঝবে) | সবাই |

## প্রস্তাবিত আর্কিটেকচার (Serverless + Event-driven)
**EC2 নেই** → requirement 3 (t3.micro 80% → 50–60%) প্রযোজ্য নয়; রিপোর্টে এটা স্পষ্ট লিখবে।
(যদি কেউ জিজ্ঞেস করে: EC2 থাকলে 6 × 80% / 55% ≈ 8.7 → **৯টা** instance লাগত, আর প্রতি ৬ মাসে দ্বিগুণ হলে ৩ বছরে ~৬৪ গুণ — এজন্যই serverless ভালো।)

| স্তর | সার্ভিস | কাজ / কেন |
|---|---|---|
| DNS | **Route 53** | ডোমেইন → CloudFront; latency-based routing, health check |
| Global speed (req 6) | **CloudFront** (+ **AWS WAF**) | সারা বিশ্বের edge location-এ ছবি/ভিডিও/ওয়েবসাইট cache → বিদেশে response দ্রুত; WAF আক্রমণ আটকায় |
| Frontend | **S3 static website** (CloudFront OAC দিয়ে, bucket public না) | HTML/JS/CSS — কোনো সার্ভার লাগে না |
| Login | **Cognito** User Pool | ইউজার sign-up/login, JWT token |
| API | **API Gateway** (REST/HTTP) | সব request-এর দরজা; throttling, Cognito authorizer |
| Business logic | **Lambda** (API functions) | photo list, metadata save, upload-এর জন্য **pre-signed URL** দেওয়া |
| Database (req 5) | **DynamoDB** (on-demand) | RDS-এর বদলে; টেবিল সহজ (id, title, description, date, keywords, s3 keys), auto-scale, সস্তা, Global Tables দিয়ে multi-region সম্ভব |
| Media storage (req 1) | **S3** — `uploads` bucket আর `processed` bucket | আসল ফাইল আর বানানো ভার্সন আলাদা রাখা (লুপ এড়াতে) |
| Event trigger (req 8a) | **S3 Event → Amazon EventBridge** (বা **SNS** topic) | আপলোড হলেই event; **fan-out** করে একাধিক queue-তে পাঠায় |
| Decoupling (req 8d) | **SQS** queues: `ThumbnailQueue`, `MobileResizeQueue`, `VideoTranscodeQueue`, (ভবিষ্যতে) `AITaggingQueue` — প্রতিটার একটা **DLQ** | কাজ queue-তে জমা থাকে, worker নিজের গতিতে টানে (pull) → অ্যাপ overload হয় না |
| Workers (req 8c) | ছবি: **Lambda** (Pillow) — thumbnail, low-res; ভিডিও: **AWS Elemental MediaConvert** (বা ভারী কাজে **ECS Fargate** worker); AI tags: **Rekognition** | প্রতিটা কাজ তার উপযুক্ত প্ল্যাটফর্মে; নতুন কাজ = নতুন queue + worker, বাকিগুলো অপরিবর্তিত (req 8b, 7) |
| Monitoring | **CloudWatch** (logs, alarms on queue depth/DLQ), **X-Ray** | সমস্যা ধরা, autoscaling-এর সংকেত |
| Security | **IAM roles** (least privilege), **KMS** (S3/DynamoDB encryption), HTTPS সব জায়গায় | |

> নোট: *Elastic Transcoder* AWS বন্ধ করে দিয়েছে — ভিডিওর জন্য **MediaConvert** লেখো।

## UML Collaboration Diagram — মেসেজের ক্রম
**Use case 1: Media Upload**
1. User → CloudFront: ওয়েবসাইট লোড
2. User → Cognito: login → JWT token
3. User → API Gateway: `POST /upload-url` (token, file name, type)
4. API Gateway → Lambda(GetUploadUrl): request
5. Lambda → S3: pre-signed PUT URL তৈরি
6. Lambda → DynamoDB: `PutItem` (photoId, title, status = "PROCESSING")
7. Lambda → User: pre-signed URL ফেরত
8. User → S3 `uploads` bucket: সরাসরি ফাইল PUT
9. S3 → EventBridge: `Object Created` event (পরের use case শুরু)

**Use case 2: Media Processing**
1. EventBridge → rule অনুযায়ী ছবি হলে `ThumbnailQueue` + `MobileResizeQueue` (+ `AITaggingQueue`), ভিডিও হলে `VideoTranscodeQueue`-তে message (bucket, key, type)
2. Worker Lambda ← SQS: message poll করে
3. Worker → S3 `uploads`: আসল ফাইল GET
4. Worker: resize / transcode (ভিডিও হলে MediaConvert job)
5. Worker → S3 `processed`: নতুন ভার্সন PUT
6. Worker → DynamoDB: `UpdateItem` (thumbnailKey, mobileKey, status = "READY")
7. Worker → SQS: message delete (ব্যর্থ হলে কয়েকবার retry → DLQ → CloudWatch alarm)
8. User → CloudFront → S3 `processed`: পরে album দেখলে নতুন ভার্সন cache থেকে আসে

## Design Rationale — যা অবশ্যই তুলনা করতে হবে
| বিষয় | বিকল্প | আমাদের পছন্দ + কারণ |
|---|---|---|
| Compute | VM (EC2) vs Container (ECS/EKS) vs Serverless (Lambda) | Lambda: শূন্য server admin (req 1), নিজে নিজে scale (req 2), শুধু ব্যবহার অনুযায়ী টাকা; ভারী ভিডিও কাজে Fargate/MediaConvert (Lambda-র 15 মিনিট সীমা) |
| Database | SQL (RDS/Aurora) vs NoSQL (DynamoDB) | DynamoDB: টেবিল সহজ, join লাগে না, সস্তা, ms-level দ্রুত |
| Caching | CloudFront vs ElastiCache vs DAX | CloudFront (media/global), দরকার হলে DAX |
| Messaging | Push (SNS) vs Pull (SQS) | দুটোই: SNS/EventBridge দিয়ে fan-out (push), SQS দিয়ে worker নিজের গতিতে (pull) |
| Tiers | 2-tier vs 3-tier | Presentation (S3+CloudFront) / Logic (API GW+Lambda) / Data (DynamoDB+S3) |

প্রতিটা criteria আলাদা heading-এ: **Performance & Scalability, Reliability** (multi-AZ managed services, DLQ, retries, S3 11-nines), **Security** (Cognito, IAM, OAC, WAF, KMS, pre-signed URL সময়-সীমিত), **Cost**।
যেখানে পারো **সংখ্যা দিয়ে** তুলনা করো (যেমন EC2 ৯টা ২৪/৭ বনাম Lambda per-request খরচ)।

## Cost Estimate (গ্রুপের জন্য বাধ্যতামূলক)
- https://calculator.aws/ এ গিয়ে region **Asia Pacific (Sydney)** নিয়ে প্রতিটা সার্ভিস যোগ করো।
- একটা **assumption** লেখো, যেমন: মাসে ১০ লাখ page view, ১ লাখ upload (৯০% ছবি ২ MB, ১০% ভিডিও ৫০ MB), ৫০০ GB storage, ২ TB CloudFront transfer।
- টেবিল দুই ভাগে: **Fixed** (Route 53 hosted zone, WAF web ACL ইত্যাদি) আর **Variable** (Lambda, API GW, DynamoDB, S3, CloudFront, SQS, MediaConvert, Rekognition)।
- প্রতি ৬ মাসে দ্বিগুণ হলে ১, ২, ৩ বছরে খরচ কত — একটা ছোট টেবিল দাও।
- Calculator-এর share link রিপোর্টের appendix/reference-এ দাও।

## রিপোর্টের কাঠামো (IEEE, ≤15 পেজ)
1. Title, group members + Student ID
2. Abstract
3. Introduction (business scenario সংক্ষেপে)
4. Assumptions
5. Architecture Overview + **আর্কিটেকচার ডায়াগ্রাম** (VPC লাগলে কোন সার্ভিস ভেতরে/বাইরে ঠিকভাবে দেখাও; আমাদের ডিজাইনে প্রায় সব managed service VPC-র বাইরে)
6. Service Descriptions (প্রতিটা সার্ভিস: কাজ + কেন)
7. How each requirement (1–8) is met — একটা টেবিল
8. Decoupling ব্যাখ্যা
9. UML Collaboration Diagrams (Upload, Processing)
10. Design Rationale + Alternatives (উপরের টেবিল)
11. Cost Estimate
12. Conclusion
13. Task allocation table
14. References (AWS docs, whitepaper, icon সূত্র — না দিলে নম্বর কাটবে)

## টুল
- ডায়াগ্রাম: https://www.draw.io/?splash=0&libs=aws4 (AWS আইকন আছে)
- UML: draw.io (UML শেপ) বা PlantUML
- IEEE টেমপ্লেট: Overleaf "IEEE Conference Template" বা Word IEEE template
