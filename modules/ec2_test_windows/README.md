# ec2_test_windows
Terraform ec2_test_windows module

This module allows you to create a test Windows instance with the latest Windows AMI

By default the Windows instance created will be:
- Latest Windows AMI
- t3.small
- Named "Windows-Test"


The following variables are required when calling the module:

Variable | Description | Value
-------- | ----------- | -----
"windowstest_subnet_id" | Subnet to put the instance in | string
"windowstest_vpc_security_group_ids" | Security group(s) to attach to the instance | list(string)
"windowstest_key_name" | Key Pair for the instance | string
"windowstest_iam_instance_profile" | IAM Profile for the instance | ""


The following variables are not required when calling the module:

Variable | Description | Value | Default
-------- | ----------- | ----- | -------
"region" | The region we are building into | string | us-east-1
"environment" | Build environment | string | Development
"layer" | Terraform layer | string | 300compute
"windowstest_instance_type" | Instance type | string | t3.small
"windowstest_instance_name" | Name of the instance | string | Windows-Test