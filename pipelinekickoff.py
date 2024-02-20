# Standard Library
import argparse
import os
import boto3
import random
import string
import subprocess, sys

# Pull in args
parser = argparse.ArgumentParser(description="AWS")
parser.add_argument(
    "--access",
    help="AWS Access Key",
    type=str,
)
parser.add_argument(
    "--secret",
    type=str,
    help="AWS Secret Key",
)
args = parser.parse_args()

# Change directory to layers folder
os.chdir("layers")

# Write function to get folders in working directory
def list_folders_in_current_directory():
    current_directory = os.getcwd()
    folders = [name for name in os.listdir(current_directory) if os.path.isdir(os.path.join(current_directory, name))]
    return folders

# Call function to get folders in working directory
folders_list = list_folders_in_current_directory()

# Write function to remove existing terraform.secret.tf file
def recursively_remove_file_in_folder(target_file):
    current_directory = os.getcwd()
    folders = [name for name in os.listdir(current_directory) if os.path.isdir(os.path.join(current_directory, name))]
    for folder in folders:
        file_path = os.path.join(folder, target_file)
        if os.path.exists(file_path):
            os.remove(file_path)
            print(f"Removed '{file_path}'")

# Call function to remove existing config.tf and data.tf files
recursively_remove_file_in_folder("config.tf")
recursively_remove_file_in_folder("data.tf")

# Write function to write config file
def generate_config_tf(bucket_name):
    for folder in folders_list:
        tf_code = f'''
terraform {{
  required_version = "~> 1.5.5"
  required_providers {{
    aws = {{
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }}
  }}

  backend "s3" {{
    bucket = "{bucket_name}"
    key    = "state_{folder}"
    region = "us-east-1"
  }}
}}

provider "aws" {{
  region = var.region
}}
'''
        file_path = os.path.join(folder,"config.tf")
        with open(file_path, "w") as config_tf_file:
            config_tf_file.write(tf_code)
            print(f"Wrote new '{file_path}'")

# Write function for data blocks
def generate_data_tf(layer, data_layer, bucket_name):
    for folder in folders_list:
        if layer == folder:
            tf_code = f'''
data "terraform_remote_state" "state_{data_layer}" {{
  backend = "s3"
  config = {{
    bucket = "{bucket_name}"
    key    = "state_{data_layer}"
    region = "us-east-1"
  }}
}}
'''
            file_path = os.path.join(folder,"data.tf")
            with open(file_path, "a") as data_tf_file:
                data_tf_file.write(tf_code)
                print(f"Appended '{file_path}'")

# Generate random string for unique S3 bucket name
def get_random_string(length):
    # choose from all lowercase letter
    letters = string.ascii_lowercase
    result_str = ''.join(random.choice(letters) for i in range(length))
    return result_str

random_string = get_random_string(22)

# Create Backend S3 Bucket
s3_client = boto3.client(
    's3',
    aws_access_key_id=args.access,
    aws_secret_access_key=args.secret,
    region_name='us-east-1'
)

sts_client = boto3.client(
    'sts',
    aws_access_key_id=args.access,
    aws_secret_access_key=args.secret,
    region_name='us-east-1'
)

account_number = sts_client.get_caller_identity().get('Account')

bucket_response = s3_client.create_bucket(
    Bucket=f'{account_number}-{random_string}'
)

tf_bucket = bucket_response['Location'][1:]

# Call function to write secret file
generate_config_tf(tf_bucket)

# Call functions to write data files
generate_data_tf('100security','000base',tf_bucket)
generate_data_tf('200data','000base',tf_bucket)
generate_data_tf('200data','100security',tf_bucket)
generate_data_tf('300compute','000base',tf_bucket)
generate_data_tf('300compute','100security',tf_bucket)
generate_data_tf('350beanstalk','000base',tf_bucket)
generate_data_tf('350beanstalk','100security',tf_bucket)
generate_data_tf('400container','000base',tf_bucket)
generate_data_tf('400container','100security',tf_bucket)
generate_data_tf('410codedeploy','000base',tf_bucket)
generate_data_tf('410codedeploy','100security',tf_bucket)
generate_data_tf('450promgrafana','000base',tf_bucket)
generate_data_tf('490kubernetes','000base',tf_bucket)
generate_data_tf('500api','000base',tf_bucket)
generate_data_tf('500api','100security',tf_bucket)
generate_data_tf('500api','400container',tf_bucket)

# Set Github repo secrets
subprocess.run(f'gh secret set AWS_ACCESS_KEY_ID --body "{args.access}"', shell = True, executable="/bin/bash")
subprocess.run(f'gh secret set AWS_SECRET_ACCESS_KEY --body "{args.secret}"', shell = True, executable="/bin/bash")