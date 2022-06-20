# Terraform

Environment to practice IAC for AWS

### In order to use the A Cloud Guru playground account and spin up an environment:

##### Clone this repository to your local machine
```
git clone git@github.com:CURRTIS1/Terraform.git
```

##### Set the local stored credentials to your personal access keys
###### Note: This is the account which will store your state file, region may vary
```
aws configure set aws_access_key_id ************************** --profile default
aws configure set aws_secret_access_key ************************** --profile default
aws configure set region us-east-1 --profile default
```

#### In the main.tf file of each layer put your state bucket name in
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

#### Create a file 'terraform.secret.tf' in the Terraform folder

#### Open a Sandbox environment in A Cloud Guru

#### Store the A Cloud Guru credentials in your secrets file 'terraform.secret.tf'
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

#### The stored credentials in your secrets file are referenced in the provider block
```
provider "aws" {
  region     = var.region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}
```

###### Note: When you run a terraform apply it will deploy in the ACG environment
###### Note: Your state file will be stored in the bucket and account you reference in your local credentials
###### Note: Add '*.secret.tf' to your .gitignore file
###### Note: When forking this repo ensure to update the module sources in the main.tf files