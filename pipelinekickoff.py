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