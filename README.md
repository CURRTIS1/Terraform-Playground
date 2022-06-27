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


#### Run a terraform initialisation for any layer you want to run 'terraform init'

#### To apply a layer change your directory to the layer ie ./Terraform/layers/000base and run 'terraform apply'

#### You don't have to apply all layers, just the 000base layer and any subsequent layer listed in the 'Required layers' section in the main.tf file

-----------------------------------------------------------------------------------------------

#### Notes:
###### You will need to download the AWS CLI for the local executions to work
###### The stored credentials in your secrets file are referenced in the provider block
###### This repo expects you to have at least terraform version 1.2.0 installed
###### You don't have to run every layer, just 000base and any 'required layer' listed in the main.tf file
###### If you are forking this repo ensure to update the module sources in the main.tf files
###### Each layer stores its own state file relative to the folder
###### The playground account lasts four hours and after that everything is deleted
###### The playground doesn’t have any resources when created
###### A Cloud Guru doesn’t count playground use as activity so your account may end up being marked as ‘inactive’ if you aren’t doing courses/labs.
###### If you don't destroy your resources you may need to run a 'terraform state rm' next apply when using new access keys in ACG