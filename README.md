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
# # Configure AWS provider
provider "aws" {
  region = "us-west-2"  # Replace with your desired region
}
```

##### Create S3 Bucket for images (e.g, my-image-bucket)
```
resource "aws_s3_bucket" "Created_Bucket_Name" {
  bucket = "Created_Bucket_Name"

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
  handler          = "lambda.handler"  # Replace with your function's handler
  runtime          = "python3.9"  # Adjust based on your function's runtime
```

##### Specify environment variables if needed
```
  environment {
    variables = {
      # key = "value"
    }
  }
  depends_on = [aws_iam_role_policy_attachment.attach_lambda_policy]
}
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
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:ListBucket",
        "s3:PutObject",
        "s3:CreateBucket",
        "s3:DeleteObject",
        "lambda:InvokeFunction",
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "*"
    }
  ]
}
EOF
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
resource "aws_iam_role_policy_attachment" "attach_lambda_policy" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}
```

#### S3 Object Lambda Access Point for watermarking
```
resource "aws_s3control_object_lambda_access_point" "object_lambda_access_point" {
  name = "watermarked-images"
  account_id = "YOUR_ACCOUNT_ID"  # Replace with your AWS account ID
  configuration {
    supporting_access_point = aws_s3_access_point.Created_Bucket_Name_access_point.arn
    transformation_configuration {
      actions = ["GetObject"]
      content_transformation {
        aws_lambda {
          function_arn = aws_lambda_function.watermark_lambda.arn
        }
      }
    }
  }
}
```
#### Upload an image to S3 bucket using local-exec provisioned
```
resource "null_resource" "upload_image" {
  provisioner "local-exec" {
    command = "aws s3 cp ./a_neon_frog.jpeg  s3://${aws_s3_bucket.Created_Bucket_Name.bucket}/a_neon_frog.jpeg"
  }
  depends_on = [aws_s3_bucket.Created_Bucket_Name]
}
```

### Important Note:
The provided policy grants extensive permissions. Ensure it aligns with your specific security requirements. Consider using the principle of least privilege and limiting permissions based on your use case.


#### Initialize Terraform
 ```
$ terraform init
```

#### Run Terraform
```
$ terraform apply
```
