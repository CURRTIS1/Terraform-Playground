/*

200data - main.tf

Required layers:
000base
100security

Required modules:


*/

locals {
  tags = {
    environment = var.environment
    layer       = var.layer
    terraform   = "true"
  }
}

## ----------------------------------
## Elastic Beanstalk S3 bucket

resource "aws_s3_bucket" "beanstalk_bucket" {
}

resource "aws_s3_bucket_versioning" "beanstalk_bucket_versioning" {
  bucket = aws_s3_bucket.beanstalk_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_object" "examplebucket_object" {
  depends_on = [aws_s3_bucket_versioning.beanstalk_bucket_versioning]

  key    = "app.zip"
  bucket = aws_s3_bucket.beanstalk_bucket.id
  source = "./app/app.zip"
}


## ----------------------------------
## Elastic Beanstalk policy attachments

resource "aws_iam_role_policy_attachment" "ssmrole_attach" {
  role       = data.terraform_remote_state.state_000base.outputs.ssm_role_name
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkWebTier"
}

resource "aws_iam_role_policy_attachment" "ssmrole_attach2" {
  role       = data.terraform_remote_state.state_000base.outputs.ssm_role_name
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkMulticontainerDocker"
}

resource "aws_iam_role_policy_attachment" "ssmrole_attach3" {
  role       = data.terraform_remote_state.state_000base.outputs.ssm_role_name
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkWorkerTier"
}


## ----------------------------------
## Elastic Beanstalk application

resource "aws_elastic_beanstalk_application" "elasticapp" {
  name = "MyElasticBeanstalkApp"
}


## ----------------------------------
## Elastic Beanstalk application version

resource "aws_elastic_beanstalk_application_version" "elasticappv1" {
  name        = "MyElasticBeanstalkAppv1"
  application = aws_elastic_beanstalk_application.elasticapp.name
  description = "application version created by terraform"
  bucket      = aws_s3_bucket.beanstalk_bucket.id
  key         = aws_s3_object.examplebucket_object.id
}


## ----------------------------------
## Elastic Beanstalk Environment

resource "aws_elastic_beanstalk_environment" "beanstalkappenv" {
  name                = "MyElasticBeanstalkEnv"
  application         = aws_elastic_beanstalk_application.elasticapp.name
  solution_stack_name = "64bit Amazon Linux 2 v3.4.0 running Python 3.8"
  tier                = "WebServer"
  version_label       = "MyElasticBeanstalkAppv1"
  setting {
    namespace = "aws:ec2:vpc"
    name      = "VPCId"
    value     = data.terraform_remote_state.state_000base.outputs.vpc_id
  }
  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = "ssm_profile"
  }
  setting {
    namespace = "aws:ec2:vpc"
    name      = "AssociatePublicIpAddress"
    value     = "True"
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "Subnets"
    value     = join(",", data.terraform_remote_state.state_000base.outputs.subnet_public)
  }
  setting {
    namespace = "aws:elasticbeanstalk:environment:process:default"
    name      = "MatcherHTTPCode"
    value     = "200"
  }
  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "LoadBalancerType"
    value     = "application"
  }
  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "InstanceType"
    value     = "t3.medium"
  }
  setting {
    namespace = "aws:ec2:vpc"
    name      = "ELBScheme"
    value     = "internet facing"
  }
  setting {
    namespace = "aws:autoscaling:asg"
    name      = "MinSize"
    value     = 2
  }
  setting {
    namespace = "aws:autoscaling:asg"
    name      = "MaxSize"
    value     = 3
  }
  setting {
    namespace = "aws:elasticbeanstalk:healthreporting:system"
    name      = "SystemType"
    value     = "basic"
  }

  depends_on = [
    aws_elastic_beanstalk_application_version.elasticappv1
  ]

}