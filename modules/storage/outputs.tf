output "ingest_queue_url" {
  description = "URL of the osquery ingest SQS queue"
  value       = aws_sqs_queue.ingest.url
}

output "ingest_queue_arn" {
  description = "ARN of the osquery ingest SQS queue"
  value       = aws_sqs_queue.ingest.arn
}

output "ingest_dlq_arn" {
  description = "ARN of the dead-letter queue"
  value       = aws_sqs_queue.ingest_dlq.arn
}

output "bucket_name" {
  description = "S3 bucket name"
  value       = aws_s3_bucket.main.id
}

output "bucket_arn" {
  description = "S3 bucket ARN"
  value       = aws_s3_bucket.main.arn
}
