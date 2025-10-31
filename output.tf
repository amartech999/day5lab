# Web Tier URLs (direct EC2 access)
output "web_tier_urls" {
  description = "Public URLs for Web Tier EC2s"
  value       = [for ip in aws_instance.web[*].public_ip : "http://${ip}"]
}

# Application Load Balancer DNS URL
output "app_load_balancer_url" {
  description = "Public URL of Application Load Balancer"
  value       = "http://${aws_lb.app_alb.dns_name}"
}

# App Tier (direct EC2 fallback, not through ALB)
output "app_tier_urls" {
  description = "Direct URLs for App Tier EC2s (port 8080)"
  value       = [for ip in aws_instance.app[*].public_ip : "http://${ip}:8080"]
}

# Database Instance Public IP
output "db_tier_ip" {
  description = "Public IP for DB instance (for SSH / MySQL test)"
  value       = aws_instance.db.public_ip
}

