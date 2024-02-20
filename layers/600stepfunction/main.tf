/*

600stepfunction - main.tf

Required layers:


Required modules:


*/

terraform {
  required_version = "~> 1.5.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "local" {
    path = "./terraform.600stepfunction.tfstate"
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


## ----------------------------------
## IAM role for State function

resource "aws_iam_role" "sfn_role" {
  name = "sfn_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "states.amazonaws.com"
        }
      },
    ]
  })
  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "sfnrole_attach" {
  role       = aws_iam_role.sfn_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaRole"
}


## ----------------------------------
## State machine

resource "aws_sfn_state_machine" "sfn_state_machine" {
  name     = "my-state-machine"
  role_arn = aws_iam_role.sfn_role.arn

  definition = <<EOF
{
  "Comment": "A simple AWS Step Functions state machine that automates a call center support session.",
  "StartAt": "Open Case",
  "States": {
    "Open Case": {
      "Type": "Task",
      "Resource": "${aws_lambda_function.lambda_OpenCaseFunction.arn}",
      "Next": "Assign Case"
    }, 
    "Assign Case": {
      "Type": "Task",
      "Resource": "${aws_lambda_function.lambda_AssignCaseFunction.arn}",
      "Next": "Work on Case"
    },
    "Work on Case": {
      "Type": "Task",
      "Resource": "${aws_lambda_function.lambda_WorkOnCaseFunction.arn}",
      "Next": "Is Case Resolved"
    },
    "Is Case Resolved": {
        "Type" : "Choice",
        "Choices": [ 
          {
            "Variable": "$.Status",
            "NumericEquals": 1,
            "Next": "Close Case"
          },
          {
            "Variable": "$.Status",
            "NumericEquals": 0,
            "Next": "Escalate Case"
          }
      ]
    },
     "Close Case": {
      "Type": "Task",
      "Resource": "${aws_lambda_function.lambda_CloseCaseFunction.arn}",
      "End": true
    },
    "Escalate Case": {
      "Type": "Task",
      "Resource": "${aws_lambda_function.lambda_EscalateCaseFunction.arn}",
      "Next": "Fail"
    },
    "Fail": {
      "Type": "Fail",
      "Cause": "Engage Tier 2 Support."    }   
  }
}
EOF
}


## ----------------------------------
## IAM role for Lambda

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
## Lambda function AssignCaseFunction

resource "aws_lambda_function" "lambda_AssignCaseFunction" {
  filename      = "${path.module}/app/AssignCaseFunction.zip"
  function_name = "AssignCaseFunction"
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "index.handler"
  source_code_hash = filebase64sha256("${path.module}/app/AssignCaseFunction.zip")
  runtime = "nodejs12.x"
}


## ----------------------------------
## Lambda function CloseCaseFunction

resource "aws_lambda_function" "lambda_CloseCaseFunction" {
  filename      = "${path.module}/app/CloseCaseFunction.zip"
  function_name = "CloseCaseFunction"
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "index.handler"
  source_code_hash = filebase64sha256("${path.module}/app/CloseCaseFunction.zip")
  runtime = "nodejs12.x"
}


## ----------------------------------
## Lambda function EscalateCaseFunction

resource "aws_lambda_function" "lambda_EscalateCaseFunction" {
  filename      = "${path.module}/app/EscalateCaseFunction.zip"
  function_name = "EscalateCaseFunction"
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "index.handler"
  source_code_hash = filebase64sha256("${path.module}/app/EscalateCaseFunction.zip")
  runtime = "nodejs12.x"
}


## ----------------------------------
## Lambda function OpenCaseFunction

resource "aws_lambda_function" "lambda_OpenCaseFunction" {
  filename      = "${path.module}/app/OpenCaseFunction.zip"
  function_name = "OpenCaseFunction"
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "index.handler"
  source_code_hash = filebase64sha256("${path.module}/app/OpenCaseFunction.zip")
  runtime = "nodejs12.x"
}


## ----------------------------------
## Lambda function WorkOnCaseFunction

resource "aws_lambda_function" "lambda_WorkOnCaseFunction" {
  filename      = "${path.module}/app/WorkOnCaseFunction.zip"
  function_name = "WorkOnCaseFunction"
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "index.handler"
  source_code_hash = filebase64sha256("${path.module}/app/WorkOnCaseFunction.zip")
  runtime = "nodejs12.x"
}