Setup Instructions (For Collaborators)
If you have just cloned this repository, follow these steps to deploy:

Initialize Terraform: Downloads the AWS provider and prepares modules.

Bash
terraform init
Configure Secrets: - Create a file named terraform.tfvars in the root directory.

Add your database password (this file is ignored by Git for security):

Terraform
db_password = "YourSecurePassword123!"
Plan and Deploy:

Bash
terraform plan
terraform apply
Access the Application: Copy the alb_dns_name from the terminal output into your browser. A 503 Service Unavailable message confirms the network path is active.
