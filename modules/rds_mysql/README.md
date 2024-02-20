# rds_mysql
Terraform rds_mysql

This module allows you to create a mySQL RDS instance within your VPC

By default the RDS created will be:
- MySQL Engine - gp2 - db.t2.small - Multi-AZ


The following variables are required when calling the module:

Variable | Description | Value
-------- | ----------- | -----
"subnet_ids" | Subnets to be used in the RDS Subnet group | list
"engine_version" | Engine Version for the MySQL Database | string
"vpc_security_group_ids" | Security Groups to used with the RDS instance | list


The following variables are not required when calling the module:

Variable | Description | Value | Default
-------- | ----------- | ----- | -------
"region" | The region we are building into | string | us-east-1
"environment" | Build environment | string | Development
"layer" | Terraform layer | string | 200data
"subnet_group_name" | RDS Subnet Group name | string | myrdssubnetgroup
"allocated_storage" | Storage allocation for the RDS Instance | number | 20
"storage_type" | Storage type for the RDS Instance | string | gp2
"engine" | Engine version for the RDS Instance | string | mysql
"instance_class" | Instance class for the RDS Instance | string | db.t2.small
"name" | Name of the RDS Instance | string | db1
"multi_az" | Whether Multi-AZ is enabled | bool | true
"identifier" | Identifier for the RDS Instance | string | database-1-instance-1
"port" | Port for the RDS Instance | number | 3306
"username" | Username for the RDS Instance | string | admin
"password" | Password for the RDS Instance | string | Password
"skip_final_snapshot" | Whether Skip final snapshot is enabled | bool | true