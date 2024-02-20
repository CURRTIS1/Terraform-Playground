#!/bin/bash

yum update -y

${pre_user_data_commands}

#yum install -y httpd
#echo '<h1>Hello World</h1>' > /var/www/html/index.html
#systemctl start httpd
#systemctl enable httpd

${post_user_data_commands}