/*

key_pair - outputs.tf

*/

output "keypair_id" {
  value       = aws_key_pair.mykp.id
  description = "The ID of the key pair"
}