import sys
import subprocess

# Install our own dependencies
subprocess.check_call([sys.executable, '-m', 'pip', 'install', 'jwt'])

import json
import subprocess
import sys
import os
import urllib.request
import base64
import re
import jwt
import time

# If this script is not being run as part of an Octopus step, return variables from environment variables.
if "get_octopusvariable" not in globals():
    def get_octopusvariable(variable):
        if variable == 'ThisInstance.Server.Url':
            return os.environ['OCTOPUS_CLI_SERVER']
        elif variable == 'ThisInstance.Api.Key':
            return os.environ['OCTOPUS_CLI_API_KEY']
        elif variable == 'Octopus.Space.Id':
            return os.environ['OCTOPUS_SPACE_ID']
        elif variable == 'Octopus.Project.Name':
            return os.environ['OCTOPUS_PROJECT_NAME']
        if variable == 'Git.Credentials.Username':
            return os.environ['GIT_CREDENTIALS_USERNAME']
        if variable == 'Git.Credentials.Password':
            return os.environ['GIT_CREDENTIALS_PASSWORD']
        if variable == 'GitHub.App.Id':
            return os.environ['GITHUB_APP_ID']
        if variable == 'GitHub.App.PrivateKey':
            return os.environ['GITHUB_APP_PRIVATEKEY']

        return ""

# If this script is not being run as part of an Octopus step, print directly to std out.
if "printverbose" not in globals():
    def printverbose(msg):
        print(msg)


def execute(args, cwd=None, env=None, print_args=None, print_output=printverbose):
    """
        The execute method provides the ability to execute external processes while capturing and returning the
        output to std err and std out and exit code.
    """
    process = subprocess.Popen(args,
                               stdout=subprocess.PIPE,
                               stderr=subprocess.PIPE,
                               text=True,
                               cwd=cwd,
                               env=env)
    stdout, stderr = process.communicate()
    retcode = process.returncode

    if print_args is not None:
        print_output(' '.join(args))

    if print_output is not None:
        # Octopus does not use ANSI color codes in the output, so strip these codes
        stdout_no_ansi = re.sub('\x1b\[[0-9;]*m', '', stdout)
        stderr_no_ansi = re.sub('\x1b\[[0-9;]*m', '', stderr)

        print_output(stdout_no_ansi)
        print_output(stderr_no_ansi)

    return stdout, stderr, retcode


# The values for these variables are injected by Terraform as it reads the file with the templatefile() function
cac_proto = get_octopusvariable('Git.Url.Protocol')
cac_host = get_octopusvariable('Git.Url.Host')
cac_org = get_octopusvariable('Git.Url.Organization')

tenant_name_sanitized = re.sub('[^a-zA-Z0-9]', '_', get_octopusvariable('Octopus.Deployment.Tenant.Name').lower())
new_project_name_sanitized = re.sub('[^a-zA-Z0-9]', '_', get_octopusvariable('Exported.Project.Name').lower())
original_project_name_sanitized = re.sub('[^a-zA-Z0-9]', '_', get_octopusvariable('Octopus.Project.Name').lower())
project_name_sanitized = new_project_name_sanitized if len(
    new_project_name_sanitized) != 0 else original_project_name_sanitized
new_repo = tenant_name_sanitized + '_' + project_name_sanitized
template_repo = re.sub('[^a-zA-Z0-9]', '_', get_octopusvariable('Octopus.Project.Name').lower())
branch = 'main'

# Generate the tokens used by git and the GitHub API
app_id = get_octopusvariable('GitHub.App.Id')
signing_key = jwt.jwk_from_pem(get_octopusvariable('GitHub.App.PrivateKey').encode("utf-8"))

payload = {
    # Issued at time
    'iat': int(time.time()),
    # JWT expiration time (10 minutes maximum)
    'exp': int(time.time()) + 600,
    # GitHub App's identifier
    'iss': app_id
}

# Create JWT
jwt_instance = jwt.JWT()
encoded_jwt = jwt_instance.encode(payload, signing_key, alg='RS256')

# Create access token
url = "https://api.github.com/app/installations/" + get_octopusvariable('GitHub.App.InstallationId') + "/access_tokens"
headers = {
    'Authorization': 'Bearer ' + encoded_jwt,
    'Accept': 'application/vnd.github+json',
    'X-GitHub-Api-Version': '2022-11-28'
}
request = urllib.request.Request(url, headers=headers, method='POST')
response = urllib.request.urlopen(request)
response_json = json.loads(response.read().decode())
token = response_json['token']

# Attempt to view the template repo
try:
    url = cac_proto + '://' + cac_host + '/' + cac_org + '/' + template_repo + '.git'
    auth = base64.b64encode(('x-access-token:' + token).encode('ascii'))
    auth_header = "Basic " + auth.decode('ascii')
    headers = {
        "Authorization": auth_header,
    }
    request = urllib.request.Request(url, headers=headers)
    urllib.request.urlopen(request)
except:
    print('Could not find the template repo at ' + url)
    sys.exit(1)

# Attempt to view the new repo
try:
    url = cac_proto + '://' + cac_host + '/' + cac_org + '/' + new_repo + '.git'
    auth = base64.b64encode(('x-access-token:' + token).encode('ascii'))
    auth_header = "Basic " + auth.decode('ascii')
    headers = {
        "Authorization": auth_header,
    }
    request = urllib.request.Request(url, headers=headers)
    urllib.request.urlopen(request)
except:
    # If we could not view the repo, assume it needs to be created.
    # https://docs.github.com/en/rest/repos/repos?apiVersion=2022-11-28#create-an-organization-repository
    url = cac_proto + '://' + cac_host + '/orgs/' + cac_org + '/repos'
    headers = {
        "Authorization": 'Bearer ' + encoded_jwt,
        'Content-Type': 'application/json',
        'Accept': 'application/vnd.github+json',
        'X-GitHub-Api-Version': '2022-11-28',
    }
    body = {'name': new_repo}
    request = urllib.request.Request(url, headers=headers, data=json.dumps(body).encode('utf-8'))
    urllib.request.urlopen(request)

# Clone the repo and add the upstream repo
execute(['git', 'clone', cac_proto + '://' + 'x-access-token:' + token + '@'
         + cac_host + '/' + cac_org + '/' + new_repo + '.git'])
execute(
    ['git', 'remote', 'add', 'upstream', cac_proto + '://' + 'x-access-token:' + token + '@'
     + cac_host + '/' + cac_org + '/' + template_repo + '.git'],
    cwd=new_repo)
execute(['git', 'fetch', '--all'], cwd=new_repo)
_, _, show_branch_result = execute(['git', 'show-branch', 'remotes/origin/' + branch], cwd=new_repo)

if show_branch_result == 0:
    # Checkout the local branch.
    if branch != 'master' and branch != 'main':
        execute(['git', 'checkout', '-b', branch, 'origin/' + branch], cwd=new_repo)
    else:
        execute(['git', 'checkout', branch], cwd=new_repo)

    if os.path.exists(new_repo + '/.octopus'):
        print('The repo has already been forked.')
        sys.exit(0)

# Create a new branch representing the forked main branch.
execute(['git', 'checkout', '-b', branch], cwd=new_repo)

# Hard reset it to the template main branch.
execute(['git', 'reset', '--hard', 'upstream/' + branch], cwd=new_repo)

# Push the changes.
execute(['git', 'push', 'origin', branch], cwd=new_repo)

print(
    'Repo was forked from ' + cac_proto + '://' + cac_host + '/' + cac_org + '/' + template_repo + ' to '
    + cac_proto + '://' + cac_host + '/' + cac_org + '/' + new_repo)
