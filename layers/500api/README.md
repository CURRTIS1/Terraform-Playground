# 500api layer

This creates an API gateway with multiple integrations:
- Lambda backend with a GET and POST function
- HTTP integration to an ALB in front of an ECS service
- VPC Link integration to an internal NLB in from of an internal ALB in front of an ECS service