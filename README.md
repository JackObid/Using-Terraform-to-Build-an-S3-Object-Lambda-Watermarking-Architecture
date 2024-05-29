# Using-Terraform-to-Build-an-S3-Object-Lambda-Watermarking-Architecture
Using Terraform to Build an S3 Object Lambda Watermarking Architecture

## Guide outlines how to leverage Terraform to create an AWS architecture utilizing S3 Object Lambda for dynamic image watermarking upon retrieval

### Pre-Requisites:

Terraform installed and configured: https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli
AWS provider configured for Terraform: https://registry.terraform.io/providers/hashicorp/aws/latest/docs
Basic understanding of Terraform configurations
IAM User Permissions:

The Terraform IAM user needs specific permissions to create and manage the resources. These permissions allow Terraform to interact with AWS services on your behalf. Here's a list of required permissions:

#### For Resource Creation:

```
s3:CreateBucket
s3:PutObject (to upload the Lambda function code to S3)
s3:ListBucket
s3:CreateAccessPoint
s3:CreateAccessPointForObjectLambda
s3-object-lambda:WriteGetObjectResponse
lambda:CreateFunction
lambda:InvokeFunction (to test the Lambda function during deployment)
iam:AttachRolePolicy
iam:CreateRole
iam:PutRolePolicy
```
For Resource Deletion (Optional, but recommended for clean-up):
```
s3:DeleteBucket
s3:DeleteAccessPoint
s3:DeleteAccessPointForObjectLambda
lambda:DeleteFunction
iam:DeleteRole
```
### Steps
#### Define Terraform Configuration File:
Create a new file (e.g., main.tf) to house your Terraform configuration.

##### Provider Block:
Start with the provider block specifying the AWS provider and region:
```
# Configure AWS provider
provider "aws" {
  region = "us-east-1"  # Replace with your desired region
}
```

#### Create S3 Bucket for images (e.g, my-image-bucket)
```
resource "aws_s3_bucket" "image_bucket" {
  bucket = "my-image-bucket"

  tags = {
    Name = "Image Bucket with Watermarking"
  }
}
```
