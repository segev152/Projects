#!/bin/bash
set -e

echo "========================================"
echo " Starting AWS & EKS Deployment Pipeline "
echo "========================================"




# 1. AWS Authentication Check
echo ">>> Checking AWS Credentials..."
if ! aws sts get-caller-identity > /dev/null 2>&1; then
  echo "Error: AWS credentials not found or invalid."
  echo "Please run 'aws configure' in your terminal before running this script."
  exit 1
fi

REGION="eu-west-1"


BUCKET_NAME="segev-tfstate-project-9988"

echo ">>> Checking if S3 Backend Bucket exists ($BUCKET_NAME)..."
if aws s3api head-bucket --bucket "$BUCKET_NAME" 2>/dev/null; then
  echo "S3 bucket already exists and is ready."
else
  echo "Creating S3 bucket: $BUCKET_NAME..."
  aws s3api create-bucket \
    --bucket "$BUCKET_NAME" \
    --region "$REGION" \
    --create-bucket-configuration LocationConstraint="$REGION"
  echo "S3 Bucket created successfully."
fi

# 2. Terraform Infrastructure Deployment
echo ">>> Deploying Infrastructure with Terraform..."
terraform -chdir=Terraform init

# ==========================================
# 2.5 Security Scan (tfsec)
# ==========================================
echo ">>> Scanning Terraform code for security vulnerabilities..."
if ! tfsec ./Terraform; then
  echo "❌ SECURITY ALERT: tfsec found vulnerabilities in your infrastructure code!"
  echo "Please fix the issues above before deploying to production."
  exit 1
fi
echo "✅ Security scan passed successfully!"


terraform -chdir=Terraform apply -auto-approve

# 3. Kubeconfig Setup
CLUSTER="project-eks"
echo ">>> Updating Kubeconfig for cluster: $CLUSTER..."
aws eks update-kubeconfig --region $REGION --name $CLUSTER 
kubectl get nodes

# 4. Docker Build & Push to ECR
REPO="project_ecr"
echo ">>> Fetching ECR URI..."
URI=$(aws ecr describe-repositories --repository-names $REPO --region $REGION --query "repositories[0].repositoryUri" --output text)

echo ">>> Building and pushing Docker image..."
sudo docker build -t app.py:latest ./Flask
aws ecr get-login-password --region $REGION | sudo docker login --username AWS --password-stdin $URI
sudo docker tag app.py:latest $URI:latest
sudo docker push $URI:latest

# 5. Helm & Kubernetes Deployment
echo ">>> Deploying application with Helm..."
kubectl create namespace flask-app --dry-run=client -o yaml | kubectl apply -f -

echo ">>> Checking for local Helm chart..."
if [ ! -d "./flask-app" ]; then
  echo "Chart not found. Creating 'flask-app' chart..."
  helm create flask-app
fi

helm upgrade --install flask-app ./flask-app -n flask-app \
  --set image.repository=$URI \
  --set image.tag=latest \
  --set service.type=LoadBalancer \
  --set service.port=80

echo "========================================"
echo " Deployment Completed Successfully! 🎉  "
echo "========================================"