#!/bin/bash

sudo yum update -y
sudo yum install ruby -y
sudo yum install wget -y
cd /home/ec2-user
"test" >> test.txt
wget https://aws-codedeploy-${region}.s3.amazonaws.com/latest/install
chmod +x ./install
sudo ./install auto
sudo service codedeploy-agent status