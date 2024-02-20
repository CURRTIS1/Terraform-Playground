# Standard Library
import argparse
import os

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

# Call function to remove existing terraform.secret.tf file
recursively_remove_file_in_folder("terraform.secret.tf")

# Write function to write secret file
def generate_secret_tf(secret1_value,secret2_value):
    tf_code = f'''
# secret.tf - Define sensitive variables or secrets

variable "aws_access_key" {{
  description = "The AWS Access Key"
  default     = "{secret1_value}"
}}

variable "aws_secret_key" {{
  description = "The AWS Secret Key"
  default     = "{secret2_value}"
}}
'''
    for folder in folders_list:
        file_path = os.path.join(folder,"terraform.secret.tf")
        with open(file_path, "w") as secret_tf_file:
            secret_tf_file.write(tf_code)
            print(f"Wrote new '{file_path}'")

# Call function to write secret file
generate_secret_tf(args.access,args.secret)