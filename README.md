A streamlined, fully automated DevSecOps pipeline that provisions a secure AWS infrastructure using Terraform and deploys a containerized Flask application to an Amazon EKS cluster using Helm. This project implements a "Shift-Left" security approach by auditing code before deployment.

## 🔒 Key Security Features

* **IaC Scanning:** Automated `tfsec` static analysis that fails the pipeline if high-risk vulnerabilities are detected.

* **Network Isolation:** EKS Worker Nodes reside in private subnets; ingress to NodePorts is strictly restricted to the internal VPC (`10.0.0.0/16`).

* **Secure Remote Backend:** Terraform state is stored in an encrypted remote S3 bucket (`encrypt = true`).

* **Artifact Integrity:** ECR repository is configured with `IMMUTABLE` image tags to prevent malicious overwrites.




## 🚀 Execution Sequence


To deploy or destroy the infrastructure, run the scripts in this exact order:



### 1. Environment Setup

```bash


chmod +x setup.sh

./setup.sh

Purpose: Prepares the host machine by downloading and installing the tfsec binary to /usr/local/bin/.

2. Infrastructure & Application Deployment

Bash

chmod +x project.sh

./project.sh

Purpose: Validates credentials, runs the security scan, provisions all AWS resources (VPC, Subnets, ECR, EKS), builds the Docker image, pushes it to ECR, and deploys the Flask app via Helm.

3. Clean Teardown

Bash


chmod +x destroy.sh

./destroy.sh

Purpose: Uninstalls the Helm release, runs terraform destroy to tear down AWS infrastructure, and uses aws s3api to empty and completely remove the remote state S3 bucket to ensure zero lingering costs.
