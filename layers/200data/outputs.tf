/*

200data - outputs.tf

*/

output "rds_cname" {
  value       = module.rds_mysql.rds_cname
  description = "The ID of the RDS instance"
}