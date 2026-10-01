output "rds_endpoint" {
  description = "The RDS endpoint"
  value       = aws_db_instance.harbour_books_reformation.endpoint
}
