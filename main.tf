# Configure AWS provider
provider "aws" {
  region = "us-east-1"  # Replace with your desired region
}

# Create S3 Bucket for images (remove deprecated acl argument)
resource "aws_s3_bucket" "image_bucket" {
  bucket = "my-image-bucket"

  tags = {
    Name = "Image Bucket with Watermarking"
  }
}

# Define Lambda function (replace with your Lambda code zip)
resource "aws_lambda_function" "watermark_lambda" {
  filename         = "lambda_function.zip"  # Replace with your Lambda zip file
  function_name    = "image-watermarker"
  role             = aws_iam_role.lambda_role.arn  # Reference the IAM role
  handler          = "handler.main"  # Replace with your function's handler
  runtime          = "python3.9"  # Adjust based on your function's runtime

  # Specify environment variables if needed
  environment {
    variables = {
      # key = "value"
    }
  }
}

# Create IAM Role for Lambda function
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

# IAM Policy for Lambda to access S3 objects (reference external policy file)
resource "aws_iam_policy" "lambda_policy" {
  name = "lambda_policy"

  policy = file("iam_policy.json")  # Reference the policy JSON file
}

# Attach IAM policy to the Lambda role
resource "aws_iam_role_policy_attachment" "attach_lambda_policy" {
  role       = aws_iam_role.lambda_role.name  # Corrected to use `name` instead of `arn`
  policy_arn = aws_iam_policy.lambda_policy.arn
}

# S3 Object Lambda Access Point for watermarking (corrected syntax)
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
    }
  }
}
