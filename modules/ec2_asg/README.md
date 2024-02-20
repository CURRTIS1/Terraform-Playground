# ec2_asg
Terraform ec2_asg module

This module allows you to create an autoscaling group

By default the ASG created will be:
- ASG with min:0 max:1 instances
- t3.small
- Latest linux AMI


The following variables are required when calling the module:

Variable | Description | Value
-------- | ----------- | -----
"key_pair" | Key pair for the ASG instances | string
"security_groups" | Security groups for the ASG instances | string
"iam_instance_profile" | IAM instance profile of the ASG instances | string
"vpc_subnets" | VPC subnets to put the ASG instances in | list(string)


The following variables are not required when calling the module:

Variable | Description | Value | Default
-------- | ----------- | ----- | -------
"region" | The region we are building into | string | us-east-1
"environment" | Build environment | string | Development
"layer" | Terraform layer | string | 300compute
"instance_type" | Instance type of the ASG instances | string | t3.small
"asg_lt_name" | Name of autoscaling group launch template | string | My-asg-lt
"asg_name" | Name of autoscaling group | string | My-asg
"autoscale_min" | Min num of instances | number | 0
"autoscale_max" | Max num of instances | number | 1
"health_check" | Health check type for the ASG | string | EC2
"ami_id" | AMI for the instances | string | Latest amazon linux AMI
"pre_user_data_commands" | Script to be ran at the start of the user_data bootstrap | string | ""
"post_user_data_commands" | Script to be ran at the end of the user_data bootstrap | string | ""
"target_group_arn" | Target group ARN to attach to the ASG | string | ""