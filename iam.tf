resource "aws_iam_role" "glue_admin_role" {
  name = "glue-admin-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "glue.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role" "lambda_exec" {
  name = "lambda_exec_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "glue" {
  name        = "glue_s3_catalog_policy"
  description = "policy for Glue to crawl S3 and write to Data Catalog"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::${var.bucket_name}",
          "arn:aws:s3:::${var.bucket_name}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "glue:CreateTable",
          "glue:UpdateTable",
          "glue:GetTable",
          "glue:GetDatabase",
          "glue:CreateDatabase"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "glue" {
  role       = aws_iam_role.glue_admin_role.name
  policy_arn = aws_iam_policy.glue.arn
}

resource "aws_iam_policy" "lambda" {
  name        = "lambda"
  description = "policy for Lambda to read/write S3 and start Glue workflow"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::${var.bucket_name}",
          "arn:aws:s3:::${var.bucket_name}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "glue:StartWorkflowRun"
        ]
        Resource = aws_glue_workflow.etl_csv_to_parquet.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.lambda.arn
}

data "aws_iam_policy" "AWSLambdaBasicExecutionRole" {
  name = "AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_basic_logs" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = data.aws_iam_policy.AWSLambdaBasicExecutionRole.arn
}
