# Using-Terraform-to-Build-an-S3-Object-Lambda-Watermarking-Architecture
Using Terraform to Build an S3 Object Lambda Watermarking Architecture

## Guide outlines how to leverage Terraform to create an AWS architecture utilizing S3 Object Lambda for dynamic image watermarking upon retrieval

### Pre-Requisites:
- Terraform installed and configured: https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli
- AWS provider configured for Terraform: https://registry.terraform.io/providers/hashicorp/aws/latest/docs
- Basic understanding of Terraform configurations

#### IAM User Permissions:
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
#### For Resource Deletion (Optional, but recommended for clean-up):
```
s3:DeleteBucket
s3:DeleteAccessPoint
s3:DeleteAccessPointForObjectLambda
lambda:DeleteFunction
iam:DeleteRole
```

### STEPS: 
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

##### Create S3 Bucket for images (e.g, my-image-bucket)
```
resource "aws_s3_bucket" "image_bucket" {
  bucket = "my-image-bucket"

  tags = {
    Name = "Image Bucket with Watermarking"
  }
}
```

##### Define Lambda function (Download a TrueType font that the Lambda function will use to add a watermark to an image. Copy and paste the following commands. Also replace with the right name for the Lambda_function zip)
```
resource "aws_lambda_function" "watermark_lambda" {
  filename         = "lambda_function.zip"  # Replace with your Lambda zip file
  function_name    = "image-watermarker"
  role             = aws_iam_role.lambda_role.arn  # Reference the IAM role
  handler          = "handler.main"  # Replace with your function's handler
  runtime          = "python3.9"  # Adjust based on your function's runtime
```

##### Specify environment variables if needed
```
  environment {
    variables = {
      # key = "value"
    }
  }
}
```

##### Create an IAM role for the Lambda function with necessary permissions
```
resource "aws_iam_role" "lambda_role" {
  name = "lambda_role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}
```

##### IAM Policy for Lambda to access S3 objects (reference the external policy file that you create like the attached that contains the correct permissions required for the Lambda function to interact with S3)
```
resource "aws_iam_policy" "lambda_policy" {
  name = "lambda_policy"
  policy = file("iam_policy.json")  # Reference the policy JSON file
}
```

#### Attach IAM policy to the Lambda role
```
resource "aws_iam_role_policy_attachment" "attach_lambda_policy" {
  role       = aws_iam_role.lambda_role.name  # Corrected to use `name` instead of `arn`
  policy_arn = aws_iam_policy.lambda_policy.arn
}
```

#### Attach a policy to the IAM role granting S3 Object Lambda Access Point function for watermarking 
```
resource "aws_s3control_object_lambda_access_point" "object_lambda_access_point" {
  name = "watermarked-images"
  account_id = "YOUR_AWS_ACCOUNT_ID"  # Replace with your AWS account ID
  configuration {
    supporting_access_point = aws_s3_bucket.image_bucket.bucket  # Reference the supporting S3 bucket
    transformation_configuration {
      actions = ["GetObject"]  # Specify the actions that trigger the Lambda function
      content_transformation {
        aws_lambda {
          function_arn = aws_lambda_function.watermark_lambda.arn
        }
      }
  ```

### Important Note:
The provided policy grants extensive permissions. Ensure it aligns with your specific security requirements. Consider using the principle of least privilege and limiting permissions based on your use case.
