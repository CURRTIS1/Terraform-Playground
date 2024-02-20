import subprocess, sys

# Read bitbucket app password
bitbucket_user = 'CURRTIS1'
bitbucket_lab = 'currtis1-lab'
with open("password") as f:
    bitbucket_pass = f.read()
test_key = 'asdasdasdasd'
testing=subprocess.run(f'curl --user "$USER_NAME":"$PASSWORD" "https://api.bitbucket.org/2.0/repositories/{bitbucket_user}/{bitbucket_lab}/pipelines_config/variables/" -H "Content-Type: application/json"', shell = True, executable="/bin/bash")
print(testing)