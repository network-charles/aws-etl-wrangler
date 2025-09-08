import boto3
import awswrangler as wr
import json
import logging

# set up logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# glue client
glue = boto3.client("glue")

def handler(event, context):
    try:
        logger.info("Received event: %s", json.dumps(event))

        # extract bucket and key from the S3 event
        record = event['Records'][0]['s3']
        bucket = record['bucket']['name']
        key = record['object']['key']
        s3_path = f"s3://{bucket}/{key}"
        logger.info("Processing S3 object: %s", s3_path)

        # read CSV from S3
        df = wr.s3.read_csv(path=s3_path)
        logger.info("Read %d rows from CSV", len(df))

        # remove duplicate rows based on the Name column
        df_clean = df.drop_duplicates(subset=["Name"])
        logger.info("Dropped duplicates, now %d rows", len(df_clean))

        # write Parquet to processed/users.parquet
        target_path = f"s3://{bucket}/processed/users.parquet"
        wr.s3.to_parquet(df=df_clean, path=target_path, index=False)
        logger.info("Written Parquet to: %s", target_path)

        # trigger Glue workflow
        response = glue.start_workflow_run(Name="workflow")
        logger.info("Triggered Glue workflow: %s", response['RunId'])

        return {
            "statusCode": 200,
            "body": json.dumps({
                "message": "CSV converted and workflow triggered",
                "s3_input": s3_path,
                "s3_output": target_path,
                "workflow_run_id": response['RunId']
            })
        }

    except Exception as e:
        logger.error("Error processing S3 object: %s", str(e), exc_info=True)
        return {
            "statusCode": 500,
            "body": json.dumps({"error": str(e)})
        }
