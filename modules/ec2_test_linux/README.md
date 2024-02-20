# ec2_test_linux
Terraform ec2_test_linux module

This module allows you to create a test Linux instance with the latest Linux AMI

By default the Linux instance created will be:
- Latest Linux AMI
- t3.small
- Named "linux-Test"


The following variables are required when calling the module:

Variable | Description | Value
-------- | ----------- | -----
"linuxtest_subnet_id" | Subnet to put the instance in | string
"linuxtest_vpc_security_group_ids" | Security group(s) to attach to the instance | list(string)
"linuxtest_key_name" | Key Pair for the instance | string
"linuxtest_iam_instance_profile" | IAM Profile for the instance | ""


The following variables are not required when calling the module:

Variable | Description | Value | Default
-------- | ----------- | ----- | -------
"region" | The region we are building into | string | us-east-1
"environment" | Build environment | string | Development
"layer" | Terraform layer | string | 300compute
"linuxtest_instance_type" | Instance type | string | t3.small
"linuxtest_instance_name" | Name of the instance | string | Linux-Test