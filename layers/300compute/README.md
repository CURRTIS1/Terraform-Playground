# 300compute layer

This creates an Autorecovery test instance for both Linux and Windows and an ASG Linux instance behind an ALB using the modules:
key_pair
ec2_alb
ec2_asg
ec2_test_windows
ec2_test_linux


##### In order to set a key pair un-comment the key_pair module putting in your public key, then uncomment the key_name variable for your resource