data "aws_lambda_layer_version" "panda-layer" {
  layer_name = "AWSSDKPandas-Python311"
}

resource "aws_lambda_function" "csv_to_parquet" {
  function_name    = "csv-to-parquet"
  role             = aws_iam_role.lambda_exec.arn
  handler          = "lambda_function.handler"
  runtime          = "python3.11"
  filename         = "lambda_function.zip"
  source_code_hash = filebase64sha256("lambda_function.zip")
  layers = [data.aws_lambda_layer_version.panda-layer.arn]
  memory_size = 512
  timeout     = 60

  depends_on = [aws_cloudwatch_log_group.log]
}

resource "aws_cloudwatch_log_group" "log" {
  name              = "/aws/lambda/csv-to-parquet"
  retention_in_days = 14
}

resource "aws_lambda_permission" "allow_s3" {
  statement_id  = "AllowExecutionFromS3"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.csv_to_parquet.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.data-assoc-s3.arn
}
