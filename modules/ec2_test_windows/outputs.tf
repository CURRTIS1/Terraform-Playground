/*

ec2_test_windows - outputs.tf

*/

output "instance_id" {
  value       = aws_instance.ec2_windows_test.id
  description = "The ID of the instance"
}