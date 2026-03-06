## Setup Instructions

Follow these steps to deploy the infrastructure after cloning the repository:

### 1. Initialize Terraform
First, download the AWS providers and initialize the module tree:
```bash
terraform init
```

### 2. Configure Secrets
Create a file named `terraform.tfvars` in the **root** folder. Add your database password here:
```hcl
for example: db_password = "password"
```
> **Note:** This file is ignored by Git via `.gitignore` to prevent credential leaks.

### 3. Plan and Deploy
Review the plan to ensure all modules are connected, then apply the changes:
```bash
terraform plan
terraform apply
```

### 4. Access the Application
Once finished, copy the `alb_dns_name` output and paste it into your browser. A **503 Service Unavailable** response confirms the network path is active.
