/*

400container - terraform.tfvars

*/

region                 = "us-east-1"
environment            = "dev"
layer                  = "400container"
tg_name                = "alb-external-tg"
elb_name               = "alb-external"
target_type            = "instance"
tg_port                = 80
key_name               = "Curtis-KP2"
asg_instance_type      = "t3.small"
ami_id                 = "ami-01453e60fc2aef31b"
pre_user_data_commands = "#!/bin/bash\necho 'ECS_CLUSTER=My-ECS-Cluster' >> /etc/ecs/ecs.config"