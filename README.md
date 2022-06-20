# Terraform

Environment to practice IAC for AWS

### In order to use the A Cloud Guru playground account and spin up an environment:

##### Clone this repository to your local machine
```
git clone git@github.com:CURRTIS1/Terraform.git
```

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

###### Note: When forking this repo ensure to update the module sources in the main.tf files