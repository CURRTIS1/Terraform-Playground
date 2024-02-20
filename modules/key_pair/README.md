# key_pair
Terraform key_pair

This module allows you to create a key pair within your account

The following variables are not required when calling the module:

Variable | Description | Value | Default
-------- | ----------- | ----- | -------
"public_key" | The public key for your key pair | string | ""


The following variables are not required when calling the module:

Variable | Description | Value | Default
-------- | ----------- | ----- | -------
"key_name" | The name of the Key Pair | string | MyKP
"region" | The region we are building into | string | us-east-1
"environment" | Build environment | string | Development
"layer" | Terraform layer | string | 300compute