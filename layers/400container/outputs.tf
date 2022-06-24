/*

400container - outputs.tf

*/

output "elb_alb" {
  value       = module.ec2_alb.elb_dns
  description = "The ALB DNS name"
}

output "elb_nlb" {
  value       = aws_lb.networkloadbalancer.dns_name
  description = "The NLB DNS name"
}

output "elb_nlb_arn" {
  value       = aws_lb.networkloadbalancer.arn
  description = "The NLB arn"
}