resource "aws_s3_bucket" "data-assoc-s3" {
  bucket        = var.bucket_name
  force_destroy = true
}

resource "aws_s3_object" "source" {
  bucket = aws_s3_bucket.data-assoc-s3.bucket
  key      = "source/users.csv"
  source   = "${path.module}/source/users.csv"
  etag     = filemd5("${path.module}/source/users.csv")
}

resource "aws_lambda_invocation" "invoke_csv_to_parquet" {
  function_name = aws_lambda_function.csv_to_parquet.function_name
  input = jsonencode({
    Records = [
      {
        s3 = {
          bucket = { name = aws_s3_bucket.data-assoc-s3.id }
          object = { key = "source/users.csv" }
        }
      }
    ]
  })
  depends_on    = [
    aws_s3_object.source,
    aws_glue_workflow.etl_csv_to_parquet
  ]
}

resource "aws_s3_object" "processed" {
  bucket = aws_s3_bucket.data-assoc-s3.bucket
  key    = "processed/"
}

resource "aws_s3_object" "query-output" {
  bucket = aws_s3_bucket.data-assoc-s3.bucket
  key    = "query-output/"
}

resource "aws_s3_bucket_notification" "bucket_notify" {
  bucket = aws_s3_bucket.data-assoc-s3.bucket

  lambda_function {
    lambda_function_arn = aws_lambda_function.csv_to_parquet.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "source/"
  }
  depends_on = [aws_lambda_permission.allow_s3]
}
