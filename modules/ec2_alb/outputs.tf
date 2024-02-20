/*

ec2_alb - outputs.tf

*/

output "elb_target_group" {
  value       = aws_lb_target_group.elb_target_group.id
  description = "Id of the Target Group"
}

output "elb_target_group_name" {
  value       = aws_lb_target_group.elb_target_group.name
  description = "Name of the Target Group"
}

output "elb" {
  value       = aws_lb.myelb.id
  description = "Id of the ALB"
}

output "elb_name" {
  value       = aws_lb.myelb.name
  description = "Name of the ALB"
}

output "elb_dns" {
  value       = aws_lb.myelb.dns_name
  description = "DNS of the ALB"
}

output "elb_alb_listener" {
  value       = aws_lb_listener.myelblistener.port
  description = "Listener of the ALB"
}