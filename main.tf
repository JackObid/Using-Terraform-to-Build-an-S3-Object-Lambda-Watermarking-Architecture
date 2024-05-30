# Configure AWS provider
provider "aws" {
  region = "us-west-2"  # Replace with your desired region
}

# Create S3 Bucket for images
resource "aws_s3_bucket" "Created_Bucket_Name" {
  bucket = "Created_Bucket_Name"

  tags = {
    Name = "Image Bucket with Watermarking"
  }
}

# Create an S3 Access Point for the S3 bucket
resource "aws_s3_access_point" "Created_Bucket_Name_access_point" {
  bucket = aws_s3_bucket.Created_Bucket_Name.id
  name   = "image-bucket-access-point"
}

# Define Lambda function (replace with your Lambda code zip)
resource "aws_lambda_function" "watermark_lambda" {
  filename         = "lambda_function.zip"  # Replace with your Lambda zip file
  function_name    = "image-watermarker"
  role             = aws_iam_role.lambda_role.arn  # Reference the IAM role
  handler          = "lambda.handler"  # Replace with your function's handler
  runtime          = "python3.9"  # Adjust based on your function's runtime

  # Specify environment variables if needed
  environment {
    variables = {
      # key = "value"
    }
  }

  depends_on = [aws_iam_role_policy_attachment.attach_lambda_policy]
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

# IAM Policy for Lambda to access S3 objects
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

# Attach IAM policy to the Lambda role
resource "aws_iam_role_policy_attachment" "attach_lambda_policy" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

# S3 Object Lambda Access Point for watermarking
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

# Upload an image to S3 bucket using local-exec provisioner
resource "null_resource" "upload_image" {
  provisioner "local-exec" {
    command = "aws s3 cp ./a_neon_frog.jpeg  s3://${aws_s3_bucket.Created_Bucket_Name.bucket}/a_neon_frog.jpeg"
  }

  depends_on = [aws_s3_bucket.Created_Bucket_Name]
}

