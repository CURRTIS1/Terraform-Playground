/*

ec2_test_linux - outputs.tf

*/

output "instance_id" {
  value       = aws_instance.ec2_linux_test.id
  description = "The ID instance"
}