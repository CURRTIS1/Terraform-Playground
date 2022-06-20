# ssm_role
Terraform ssm_role

This module allows you to create an SSM role for EC2 instances


By default the VPC will create:
- An SSM policy
- An SSM role


The following variables are not required when calling the module:

Variable | Description | Value | Default
-------- | ----------- | ----- | -------
"ssm_role_name" | Name for the SSM role | string | ssm_role
"ssm_profile_name" | Name for the SSM profile | string | ssm_profile