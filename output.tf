output "lb_dns_name" {
  description = "The DNS name of the load balancer"
  value       = aws_lb.devops-external-elb.dns_name
}

output "bastion_public_ip" {
  description = "Bastion host public ip"
  value = aws_instance.devops-bastion.public_ip
}