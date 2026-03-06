## Setup Instructions

Follow these steps to deploy the infrastructure after cloning the repository:

### 1. Initialize Terraform
First, download the AWS providers and initialize the module tree:
```bash
tofu init
```

### 2. Configure Secrets
Create a file named `terraform.tfvars` in the **root** folder. Add the database password here:
```hcl
for example: db_password = "password"
```
> **Note:** This file is ignored by Git via `.gitignore` to prevent credential leaks.


In CircleCI, add the following in the environment variable:
1. AWS_ACCESS_KEY_ID
2. AWS_DEFAULT_REGION
3. AWS_SECRET_ACCESS_KEY
4. TF_VAR_db_password
5. TF_VAR_db_username

### 3. Plan and Deploy
Review the plan to ensure all modules are connected, then apply the changes:
```bash
tofu plan
tofu apply
```

### 4. Access the Application
Once finished, copy the `alb_dns_name` output and paste it into your browser.

---

## Expectation

### Security Flaws

**1. No HTTPS/TLS — Unencrypted Traffic in Transit**

The ALB listener is configured on port 80 (HTTP) with no TLS termination. All traffic between clients and the load balancer is transmitted in plaintext.

An attacker on the same network path can perform a man-in-the-middle (MITM) attack. They can intercept session tokens, credentials, or API payloads in transit with no indication to the user.

**2. Open Security Group Ingress**

The database security group allows inbound PostgreSQL traffic (port 5432) from the entire Internet VPC CIDR (`10.0.0.0/16`) rather than a specific app-tier security group.

**3. Lack of Web Traffic Filtering**

The Application Load Balancer is open to the public internet without an AWS Web Application Firewall (WAF) to inspect incoming requests. This makes the infrastructure vulnerable to automated "bots" and common attacks like SQL Injection or DDoS, as there is no shield to block malicious traffic before it reaches the backend services.

---

### Design Trade-offs

**1. Cost**

A NAT Gateway provides high security for private instances to access the internet, but it incurs a high fixed monthly cost. A NAT Instance would be cheaper but lacks the automatic scaling of the Gateway.

**2. High Availability**

The Multi-AZ design ensures uptime if a data center fails but increases the management overhead of multiple subnets and route tables.

**3. Performance**

By using Aurora Serverless v2, the database automatically shrinks when not in use to minimize costs. While it scales up rapidly to handle the 5 AM story fetch, there is a minor "warm-up" delay (latency) as the system allocates more power to meet the sudden spike in demand.

---

### Scheduled Job Recommendation: Daily Hacker News Fetch at 5am GMT+8

Use **AWS EventBridge Scheduler** to trigger a **Lambda function** daily.

The Lambda is able to fetch stories from `https://hacker-news.firebaseio.com/v0/newstories.json` such as the story's details, and upload them into Aurora. 

Lambda is suitable for this since it's cost effective, requires no servers to maintain, and native VPC connectivity.

---

### LLM Usage

**1. Image Analysis**

We can use the LLM to analyse screenshots of the final UI to detect visual bugs like overlapping text or broken layouts that code-only tests often miss. Instead of relying on fragile CSS selectors, the LLM is able to scan and analyse elements such as buttons or icons or text in foreign languages, reducing errors when the underlying code changes.

**2. Reporting and Documentation**

The LLM is also able to process thousands of lines of raw test logs and server metrics to generate informative summary, highlighting root causes of failures rather than just listing errors.

---

### Additional Architecture Improvements

- **AWS Secrets Manager for DB credentials:** Replace `master_password` variable with a Secrets Manager secret and enable automatic 30-day rotation.
- **Single-AZ risk on subnets:** The Web and App subnets are both pinned to `ap-southeast-1a`. Adding subnets in `ap-southeast-1b` for each tier and placing the ALB across both would eliminate the single point of failure at the subnet level.
