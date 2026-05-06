output "server_ip" {
  description = "Public IP of the server"
  value       = aws_eip.statuspulse.public_ip
}

output "server_dns" {
  description = "Public DNS of the server"
  value       = aws_instance.statuspulse.public_dns
}

output "domain" {
  description = "Application domain"
  value       = "https://${var.domain}"
}