# Terraform

Environment to practice IAC for AWS

### In order to use the A Cloud Guru playground account and spin up an environment:

##### Clone this repository to your local machine
```
git clone git@github.com:CURRTIS1/Terraform.git
```

#### Create a file called 'terraform.secret.tf' in each layer (ie ./000base/terraform.secret.tf)

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

###### Note: This repo expects you to have at least terraform version 1.2.0 installed
###### Note: When forking this repo ensure to update the module sources in the main.tf files
###### Note: Each layer stores its own state file relative to the folder
###### Note: The playground account lasts four hours and after that everything is deleted
###### Note: The playground doesn’t have any resources when created
###### Note: A Cloud Guru doesn’t count playground use as activity so your account may end up being marked as ‘inactive’ if you aren’t doing courses/labs.
###### Note: If you don't destroy your resources you may need to run a 'terraform state rm' next apply when using new access keys in ACG