/*

350beanstalk - outputs.tf

*/

output "elasticbeanstalk_dns" {
  value       = aws_elastic_beanstalk_environment.beanstalkappenv.endpoint_url
  description = "The URL of the Elastic Beanstalk endpoint"
}