# Terraform

Environment to practice IAC for AWS

### In order to use the A Cloud Guru playground account and spin up an environment:

##### Set the local stored credentials to your personal access keys
##### This is the account which will store your state file
```
aws configure set aws_access_key_id ************************** --profile default
aws configure set aws_secret_access_key ************************** --profile default
aws configure set region us-east-1 --profile default
```

#### In the main.tf file of each layer put your bucket name in
```
terraform {
  required_version = "1.2.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }

  backend "s3" {
    bucket  = "*************"
    key     = "terraform.tfstate""
    region  = "us-east-1"
    encrypt = true
  }
}
```

#### Store the Linux Academy credentials in your secrets file 'terraform.secret.tf'
```
variable "aws_access_key" {
  description = "The AWS Access Key"
  default     = "**************************"
}

variable "aws_secret_key" {
  description = "The AWS Secret Key"
  default     = "**************************"
}
```

#### Reference the stored credentials in your provider block
```
provider "aws" {
  region     = var.region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}
```

###### Note: Add '*.secret.tf' to your .gitignore file
###### Note: If you fork this repo ensure to update the module sources in the main.tf files