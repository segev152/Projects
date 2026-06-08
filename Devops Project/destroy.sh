#!/bin/bash

echo "========================================"
echo " Destroying AWS & EKS Infrastructure    "
echo "========================================"

REGION="eu-west-1"
CLUSTER="project-eks"
REPO="project_ecr"

########################################
# 1. Uninstall Helm (Deletes Load Balancer)
########################################
echo ">>> Connecting to EKS Cluster..."
aws eks update-kubeconfig --region $REGION --name $CLUSTER 2>/dev/null || echo "Could not connect to EKS, continuing..."

echo ">>> Uninstalling Helm Releases (Cleaning up Load Balancers)..."
helm uninstall flask-app -n flask-app 2>/dev/null
kubectl delete svc --all -n flask-app 2>/dev/null

echo ">>> Waiting 180 seconds for AWS Load Balancer to be fully deleted..."
sleep 180

########################################
# 2. Empty ECR
########################################
echo ">>> Emptying ECR Repository..."
# Terraform לא יכול למחוק ECR שיש בו אימג'ים, אז אנחנו מרוקנים אותו קודם
aws ecr batch-delete-image \
    --repository-name $REPO \
    --region $REGION \
    --image-ids "$(aws ecr list-images --repository-name $REPO --region $REGION --query 'imageIds[*]' --output json)" 2>/dev/null || true

########################################
# 3. Terraform Destroy
########################################
echo ">>> Destroying Terraform Infrastructure..."
terraform -chdir=Terraform destroy -auto-approve

BUCKET_NAME="segev-tfstate-project-9988"
echo ">>> Emptying and deleting S3 state bucket ($BUCKET_NAME)..."

aws s3 rm s3://$BUCKET_NAME --recursive 2>/dev/null || true

aws s3api delete-bucket \
    --bucket $BUCKET_NAME \
    --region $REGION 2>/dev/null || true

echo ">>> S3 Bucket deleted successfully."

echo "========================================"
echo " Cleanup Completed Successfully! 🗑️     "
echo "========================================"