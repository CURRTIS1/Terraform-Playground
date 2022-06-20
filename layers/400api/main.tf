/*

400api - main.tf

Required layers:
000base
100security
350container

Required modules:

*/

terraform {
  required_version = "1.2.1"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }

  backend "s3" {
    bucket = "curtis-terraform-test-2020"
    key    = "terraform.400api.tfstate"
    region = "us-east-1"
    encrypt = true
  }
}

provider "aws" {
  region     = var.region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

locals {
  tags = {
    environment = var.environment
    layer       = var.layer
    terraform   = "true"
  }
}

data "terraform_remote_state" "state_000base" {
  backend = "s3"
  config = {
    bucket = "curtis-terraform-test-2020"
    key    = "terraform.000base.tfstate"
    region = "us-east-1"
  }
}

data "terraform_remote_state" "state_100security" {
  backend = "s3"
  config = {
    bucket = "curtis-terraform-test-2020"
    key    = "terraform.100security.tfstate"
    region = "us-east-1"
  }
}

data "terraform_remote_state" "state_350container" {
  backend = "s3"
  config = {
    bucket = "curtis-terraform-test-2020"
    key    = "terraform.350container.tfstate"
    region = "us-east-1"
  }
}


## ----------------------------------
## IAM Role for Lambda

resource "aws_iam_role" "iam_for_lambda" {
  name = "iam_for_lambda"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}


## ----------------------------------
## Lambda policy

resource "aws_iam_policy" "lambda_policy" {
  name        = "lambda_policy"
  description = "lambda policy for EC2"
  policy      = <<EOF
{
  "Version" : "2012-10-17",
  "Statement" : [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:DescribeNetworkInterfaces",
        "ec2:CreateNetworkInterface",
        "ec2:DeleteNetworkInterface",
        "ec2:DescribeInstances",
        "ec2:AttachNetworkInterface"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}


## ----------------------------------
## Lambda policy attachment

resource "aws_iam_role_policy_attachment" "lambda_attach" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}


## ----------------------------------
## Lambda policy attachment

resource "aws_iam_role_policy_attachment" "lambda_attach2" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}


## ----------------------------------
## Lambda Function GET

resource "aws_lambda_function" "apibackend-get" {
  filename         = "${path.module}/lambda-code/lambdafunction-get.zip"
  function_name    = "Api-Backend-Get"
  role             = aws_iam_role.iam_for_lambda.arn
  runtime          = "python3.8"
  source_code_hash = filebase64sha256("${path.module}/lambda-code/lambdafunction-get.zip")
  handler          = "get.lambda_handler"
  vpc_config {
    subnet_ids         = data.terraform_remote_state.state_000base.outputs.subnet_private
    security_group_ids = [data.terraform_remote_state.state_100security.outputs.sg_web]
  }
}


## ----------------------------------
## Lambda Function POST

resource "aws_lambda_function" "apibackend-post" {
  filename         = "${path.module}/lambda-code/lambdafunction-post.zip"
  function_name    = "Api-Backend-Post"
  role             = aws_iam_role.iam_for_lambda.arn
  runtime          = "python3.8"
  source_code_hash = filebase64sha256("${path.module}/lambda-code/lambdafunction-post.zip")
  handler          = "post.lambda_handler"
  vpc_config {
    subnet_ids         = data.terraform_remote_state.state_000base.outputs.subnet_private
    security_group_ids = [data.terraform_remote_state.state_100security.outputs.sg_web]
  }
}


## ----------------------------------
## API Gateway

resource "aws_api_gateway_rest_api" "TestAPI" {
  name = "MyTestAPI"
  endpoint_configuration {
    types = ["REGIONAL"]
  }
}


## ----------------------------------
## API Gateway resource

resource "aws_api_gateway_resource" "MyAPIResource" {
  rest_api_id = aws_api_gateway_rest_api.TestAPI.id
  parent_id   = aws_api_gateway_rest_api.TestAPI.root_resource_id
  path_part   = "testing"
}


## ----------------------------------
## API Gateway GET method

resource "aws_api_gateway_method" "GetMethod" {
  rest_api_id   = aws_api_gateway_rest_api.TestAPI.id
  resource_id   = aws_api_gateway_resource.MyAPIResource.id
  http_method   = "GET"
  authorization = "NONE"
}


## ----------------------------------
## API Gateway GET integration

resource "aws_api_gateway_integration" "get-integration" {
  rest_api_id             = aws_api_gateway_rest_api.TestAPI.id
  resource_id             = aws_api_gateway_resource.MyAPIResource.id
  http_method             = aws_api_gateway_method.GetMethod.http_method
  integration_http_method = "POST"
  type                    = "AWS"
  uri                     = aws_lambda_function.apibackend-get.invoke_arn
  connection_type         = "INTERNET"
  content_handling        = "CONVERT_TO_TEXT"
  passthrough_behavior    = "WHEN_NO_MATCH"
}


## ----------------------------------
## API Gateway GET method response

resource "aws_api_gateway_method_response" "getresponse200" {
  rest_api_id = aws_api_gateway_rest_api.TestAPI.id
  resource_id = aws_api_gateway_resource.MyAPIResource.id
  http_method = aws_api_gateway_method.GetMethod.http_method
  status_code = "200"
  response_models = {
    "application/json" = "Empty"
  }
}


## ----------------------------------
## API Gateway GET integration response

resource "aws_api_gateway_integration_response" "MyGetIntegrationResponse" {
  rest_api_id = aws_api_gateway_rest_api.TestAPI.id
  resource_id = aws_api_gateway_resource.MyAPIResource.id
  http_method = aws_api_gateway_method.GetMethod.http_method
  status_code = aws_api_gateway_method_response.getresponse200.status_code
  response_templates = {
    "application/json" = ""
  }
  depends_on = [
    aws_api_gateway_integration.get-integration
  ]
}


## ----------------------------------
## API Gateway POST method

resource "aws_api_gateway_method" "PostMethod" {
  rest_api_id   = aws_api_gateway_rest_api.TestAPI.id
  resource_id   = aws_api_gateway_resource.MyAPIResource.id
  http_method   = "POST"
  authorization = "NONE"
}


## ----------------------------------
## API Gateway POST integration

resource "aws_api_gateway_integration" "post-integration" {
  rest_api_id             = aws_api_gateway_rest_api.TestAPI.id
  resource_id             = aws_api_gateway_resource.MyAPIResource.id
  http_method             = aws_api_gateway_method.PostMethod.http_method
  integration_http_method = "POST"
  type                    = "AWS"
  uri                     = aws_lambda_function.apibackend-post.invoke_arn
  connection_type         = "INTERNET"
  content_handling        = "CONVERT_TO_TEXT"
  passthrough_behavior    = "WHEN_NO_MATCH"
}


## ----------------------------------
## API Gateway POST method response

resource "aws_api_gateway_method_response" "postresponse200" {
  rest_api_id = aws_api_gateway_rest_api.TestAPI.id
  resource_id = aws_api_gateway_resource.MyAPIResource.id
  http_method = aws_api_gateway_method.PostMethod.http_method
  status_code = "200"
  response_models = {
    "application/json" = "Empty"
  }
}


## ----------------------------------
## API Gateway POST integration response

resource "aws_api_gateway_integration_response" "MyPostIntegrationResponse" {
  rest_api_id = aws_api_gateway_rest_api.TestAPI.id
  resource_id = aws_api_gateway_resource.MyAPIResource.id
  http_method = aws_api_gateway_method.PostMethod.http_method
  status_code = aws_api_gateway_method_response.postresponse200.status_code
  response_templates = {
    "application/json" = ""
  }
  depends_on = [
    aws_api_gateway_integration.post-integration
  ]
}


## ----------------------------------
## GET Lambda permission for API Gateway

resource "aws_lambda_permission" "get_api" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.apibackend-get.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.TestAPI.execution_arn}/*/${aws_api_gateway_method.GetMethod.http_method}/${aws_api_gateway_resource.MyAPIResource.path_part}"
}


## ----------------------------------
## POST Lambda permission for API Gateway

resource "aws_lambda_permission" "post_api" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.apibackend-post.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.TestAPI.execution_arn}/*/${aws_api_gateway_method.PostMethod.http_method}/${aws_api_gateway_resource.MyAPIResource.path_part}"
}

## --------------------------------------------------------------------
## --------------------------------------------------------------------
## --------------------------------------------------------------------
## --------------------------------------------------------------------

## ----------------------------------
## Second API resource

resource "aws_api_gateway_resource" "MyAPIResourcepublic" {
  rest_api_id = aws_api_gateway_rest_api.TestAPI.id
  parent_id   = aws_api_gateway_rest_api.TestAPI.root_resource_id
  path_part   = "get-test-alb"
}

## ----------------------------------
## API Gateway GET method

resource "aws_api_gateway_method" "GetMethod2" {
  rest_api_id   = aws_api_gateway_rest_api.TestAPI.id
  resource_id   = aws_api_gateway_resource.MyAPIResourcepublic.id
  http_method   = "GET"
  authorization = "NONE"
}


## ----------------------------------
## API Gateway GET integration

resource "aws_api_gateway_integration" "get-integration2" {
  rest_api_id             = aws_api_gateway_rest_api.TestAPI.id
  resource_id             = aws_api_gateway_resource.MyAPIResourcepublic.id
  http_method             = aws_api_gateway_method.GetMethod2.http_method
  integration_http_method = "GET"
  type                    = "HTTP"
  uri                     = "http://${data.terraform_remote_state.state_350container.outputs.elb_alb}/get"
  connection_type         = "INTERNET"
  passthrough_behavior    = "WHEN_NO_MATCH"
}


## ----------------------------------
## API Gateway GET method response

resource "aws_api_gateway_method_response" "getresponse2002" {
  rest_api_id = aws_api_gateway_rest_api.TestAPI.id
  resource_id = aws_api_gateway_resource.MyAPIResourcepublic.id
  http_method = aws_api_gateway_method.GetMethod2.http_method
  status_code = "200"
  response_models = {
    "application/json" = "Empty"
  }
}


## ----------------------------------
## API Gateway GET integration response

resource "aws_api_gateway_integration_response" "MyGetIntegrationResponse2" {
  rest_api_id = aws_api_gateway_rest_api.TestAPI.id
  resource_id = aws_api_gateway_resource.MyAPIResourcepublic.id
  http_method = aws_api_gateway_method.GetMethod2.http_method
  status_code = aws_api_gateway_method_response.getresponse2002.status_code
  response_templates = {
    "application/json" = ""
  }
  depends_on = [
    aws_api_gateway_integration.get-integration2
  ]
}


## --------------------------------------------------------------------
## --------------------------------------------------------------------
## --------------------------------------------------------------------
## --------------------------------------------------------------------

## ----------------------------------
## Second API resource

resource "aws_api_gateway_resource" "MyAPIResourceprivate" {
  rest_api_id = aws_api_gateway_rest_api.TestAPI.id
  parent_id   = aws_api_gateway_rest_api.TestAPI.root_resource_id
  path_part   = "get-test-nlb"
}

## ----------------------------------
## API Gateway GET method

resource "aws_api_gateway_method" "GetMethodNLB" {
  rest_api_id   = aws_api_gateway_rest_api.TestAPI.id
  resource_id   = aws_api_gateway_resource.MyAPIResourceprivate.id
  http_method   = "GET"
  authorization = "NONE"
}


## ----------------------------------
## API Gateway GET integration

resource "aws_api_gateway_integration" "get-integrationNLB" {
  rest_api_id             = aws_api_gateway_rest_api.TestAPI.id
  resource_id             = aws_api_gateway_resource.MyAPIResourceprivate.id
  http_method             = aws_api_gateway_method.GetMethodNLB.http_method
  integration_http_method = "GET"
  type                    = "HTTP"
  uri                     = "http://${data.terraform_remote_state.state_350container.outputs.elb_nlb}/get"
  connection_type         = "VPC_LINK"
  connection_id           = aws_api_gateway_vpc_link.vpclink-nlb.id
  passthrough_behavior    = "WHEN_NO_MATCH"
  depends_on = [
    aws_api_gateway_vpc_link.vpclink-nlb
  ]
}


## ----------------------------------
## API Gateway GET method response

resource "aws_api_gateway_method_response" "getresponse200NLB" {
  rest_api_id = aws_api_gateway_rest_api.TestAPI.id
  resource_id = aws_api_gateway_resource.MyAPIResourceprivate.id
  http_method = aws_api_gateway_method.GetMethodNLB.http_method
  status_code = "200"
  response_models = {
    "application/json" = "Empty"
  }
}


## ----------------------------------
## API Gateway GET integration response

resource "aws_api_gateway_integration_response" "MyGetIntegrationResponseNLB" {
  rest_api_id = aws_api_gateway_rest_api.TestAPI.id
  resource_id = aws_api_gateway_resource.MyAPIResourceprivate.id
  http_method = aws_api_gateway_method.GetMethodNLB.http_method
  status_code = aws_api_gateway_method_response.getresponse200NLB.status_code
  response_templates = {
    "application/json" = ""
  }
  depends_on = [
    aws_api_gateway_integration.get-integrationNLB
  ]
}


## ----------------------------------
## API Gateway VPC Link

resource "aws_api_gateway_vpc_link" "vpclink-nlb" {
  name        = "NLB-VPC-Link"
  description = "VPC Link to internal NLB"
  target_arns = [data.terraform_remote_state.state_350container.outputs.elb_nlb_arn]
}