resource "aws_athena_workgroup" "glue" {
  name = "glue"
  configuration {
    enforce_workgroup_configuration = true
    result_configuration {
      output_location = "s3://${aws_s3_bucket.data-assoc-s3.bucket}/query-output/"
    }
  }
  force_destroy = true
}
