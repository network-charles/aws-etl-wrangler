resource "aws_glue_workflow" "etl_csv_to_parquet" {
  name = "workflow"
}

resource "aws_glue_catalog_database" "catalog-db" {
  name = "catalog-db"
}

resource "aws_glue_crawler" "s3" {
  database_name = aws_glue_catalog_database.catalog-db.name
  name          = "crawler"
  role          = aws_iam_role.glue_admin_role.arn

  s3_target {
    path = "s3://${aws_s3_bucket.data-assoc-s3.bucket}/processed/"
  }
}

resource "aws_glue_trigger" "start_crawler" {
  name          = "trigger-start-crawler"
  type          = "ON_DEMAND"
  workflow_name = aws_glue_workflow.etl_csv_to_parquet.name
  enabled       = false

  actions {
    crawler_name = aws_glue_crawler.s3.name
  }
}
