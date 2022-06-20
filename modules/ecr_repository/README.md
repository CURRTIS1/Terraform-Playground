# ecr_repository

Terraform ecr_repository

This module allows you to create an ECR Repository.

By default the module will create:
- An ECR Repository
- An ECR policy which allows the pulling of images to Dev/Stg/Int


The following variables are required when calling the module:

Variable | Description | Value
-------- | ----------- | -----
"repository_name" | Name of Repository | string


The following variables are not required when calling the module:

Variable | Description | Value | Default
-------- | ----------- | ----- | -------
"region" | The region we are building into | string | us-east-1
"environment" | Build environment | string | Development
"layer" | Terraform layer | string | 400container
"image_tag_mutability" | Mutability of the image tag | string | "MUTABLE"
"image_scanning" | Image scanning on push or manual | bool | false