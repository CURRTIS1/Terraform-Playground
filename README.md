# Terraform

Environment to practice IAC for AWS

### In order to use the A Cloud Guru playground account and spin up an environment:

##### Clone this repository to your local machine
```
git clone git@github.rackspace.com:EE-Squads-AWS/ACG-Playground-Terraform.git
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

#### Alternatively use the Python script 'acg.py' which recursively creates a terraform.secret.tf file in the layer subdirectories

Example

`python3 acg.py --access 123456789 --secret 123456789abcdefghijklmnopqrstuvwxyz`

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

-----------------------------------------------------------------------------------------------

### Common Errors

##### The below error is caused by a limitation in the ACG playground
##### Just delete the playground account and re-create a new one
```
module.vpc_basenetwork.aws_nat_gateway.natgw[0]: Creating...
╷
│ Error: error creating EC2 NAT Gateway: NotAvailableInZone: Nat Gateway is not available in this availability zone
│       status code: 400, request id: 4fd10fdc-bf3c-453a-8dc3-8e97667b2f94
│ 
│   with module.vpc_basenetwork.aws_nat_gateway.natgw[0],
│   on ../../modules/vpc_basenetwork/main.tf line 128, in resource "aws_nat_gateway" "natgw":
│  128: resource "aws_nat_gateway" "natgw" {
  ```



##### The below error is caused by a limitation in the ACG playground
##### Just delete the playground account and re-create a new one
```
│ Error: error modifying EC2 Subnet (subnet-01cf6852519754003) MapPublicIpOnLaunch: InvalidParameterValue: invalid value for parameter map-public-ip-on-launch: true
│       status code: 400, request id: 7f397919-6077-441f-8be6-9216c747cc1e
│ 
│   with module.vpc_basenetwork.aws_subnet.subnet_public[1],
│   on ../../modules/vpc_basenetwork/main.tf line 78, in resource "aws_subnet" "subnet_public":
│   78: resource "aws_subnet" "subnet_public" {
  ```


##### The below error is caused by using a region other than us-east-1
```
│ Error: Error fetching Availability Zones: UnauthorizedOperation: You are not authorized to perform this operation.
│       status code: 403, request id: 805c4f7d-724e-499c-850d-cebeb26bb2ff
│
│   with module.base_vpc.data.aws_availability_zones.available,
│   on ../../modules/vpc_basenetwork/main.tf line 12, in data "aws_availability_zones" "available":
│   12: data "aws_availability_zones" "available" {
│
```