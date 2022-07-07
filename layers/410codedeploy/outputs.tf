/*

410codedeploy - outputs.tf

*/

output "elb_dns" {
  value       = module.ec2_alb.elb_dns
  description = "DNS of the ALB"
}