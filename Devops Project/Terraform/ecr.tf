# -------------------- ECR --------------------
# tfsec:ignore:aws-ecr-repository-customer-key
resource "aws_ecr_repository" "project_ecr" {
  name                 = "project_ecr"
  image_tag_mutability = "IMMUTABLE"
  
  image_scanning_configuration {
    scan_on_push = true
  }
}