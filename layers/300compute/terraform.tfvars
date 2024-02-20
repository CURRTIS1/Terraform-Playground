/*

300compute - terraform.tfvars

*/

region                    = "us-east-1"
environment               = "Dev"
layer                     = "300compute"
key_name                  = "Curtis-KP"
windowstest_instance_name = "Curtis-Win-Test"
windowstest_instance_type = "t3.small"
linuxtest_instance_name   = "Curtis-Lin-Test"
linuxtest_instance_type   = "t3.small"
tg_name                   = "Curtis-TG-Test"
elb_name                  = "Curtis-ALB-Test"
asg_instance_type         = "t3.small"
pre_user_data_commands    = "yum install -y tomcat"
post_user_data_commands   = "systemctl start tomcat"