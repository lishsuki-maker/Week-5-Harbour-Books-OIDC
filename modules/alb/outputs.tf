output "alb_dns_name" {
  description = "DNS name of the ALB"
  value       = aws_alb.this.dns_name
}

output "target_group_arn" {
  description = "ARN of the ALB target group"
  value       = aws_alb_target_group.this.arn
}

output "alb_security_group_id" {
  description = "Security group ID of the ALB"
  value       = aws_security_group.alb.id
}
