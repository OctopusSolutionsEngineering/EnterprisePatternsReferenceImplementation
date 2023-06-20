# This script forks a GitHub repo. It creates a token from a GitHub App installation to avoid
# having to use a regular user account.

import subprocess
import sys

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
import argparse

# If this script is not being run as part of an Octopus step, setting variables is a noop
if 'set_octopusvariable' not in globals():
    def set_octopusvariable(variable, value):
        pass

# If this script is not being run as part of an Octopus step, return variables from environment variables.
# Periods are replaced with underscores, and the variable name is converted to uppercase
if "get_octopusvariable" not in globals():
    def get_octopusvariable(variable):
        return os.environ[re.sub('\\.', '_', variable.upper())]

# If this script is not being run as part of an Octopus step, print directly to std out.
if 'printverbose' not in globals():
    def printverbose(msg):
        print(msg)


def printverbose_noansi(output):
    """
    Strip ANSI color codes and print the output as verbose
    :param output: The output to print
    """
    output_no_ansi = re.sub('\x1b\[[0-9;]*m', '', output)
    printverbose(output_no_ansi)


def get_octopusvariable_quiet(variable):
    """
    Gets an octopus variable, or an empty string if it does not exist.
    :param variable: The variable name
    :return: The variable value, or an empty string if the variable does not exist
    """
    try:
        return get_octopusvariable(variable)
    except:
        return ''


def execute(args, cwd=None, env=None, print_args=None, print_output=printverbose_noansi):
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
        print_output(stdout)
        print_output(stderr)

    return stdout, stderr, retcode


def init_argparse():
    parser = argparse.ArgumentParser(
        usage='%(prog)s [OPTION] [FILE]...',
        description='Fork a GitHub repo'
    )
    parser.add_argument('--original-project-name', action='store',
                        default=get_octopusvariable_quiet('Octopus.Project.Name'))
    parser.add_argument('--new-project-name', action='store',
                        default=get_octopusvariable_quiet('Exported.Project.Name'))
    parser.add_argument('--github-app-id', action='store', default=get_octopusvariable_quiet('GitHub.App.Id'))
    parser.add_argument('--github-app-installation-id', action='store',
                        default=get_octopusvariable_quiet('GitHub.App.InstallationId'))
    parser.add_argument('--github-app-private-key', action='store',
                        default=get_octopusvariable_quiet('GitHub.App.PrivateKey'))
    parser.add_argument('--git-organization', action='store', default=get_octopusvariable_quiet('Git.Url.Organization'))
    parser.add_argument('--tenant-name', action='store',
                        default=get_octopusvariable_quiet('Octopus.Deployment.Tenant.Name'))
    parser.add_argument('--template-repo-name', action='store',
                        default=re.sub('[^a-zA-Z0-9]', '_', get_octopusvariable_quiet('Octopus.Project.Name').lower()))
    return parser.parse_known_args()


parser, _ = init_argparse()


def generate_github_token():
    # Generate the tokens used by git and the GitHub API
    app_id = parser.github_app_id
    signing_key = jwt.jwk_from_pem(parser.github_app_private_key.encode('utf-8'))

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
    url = 'https://api.github.com/app/installations/' + parser.github_app_installation_id + '/access_tokens'
    headers = {
        'Authorization': 'Bearer ' + encoded_jwt,
        'Accept': 'application/vnd.github+json',
        'X-GitHub-Api-Version': '2022-11-28'
    }
    request = urllib.request.Request(url, headers=headers, method='POST')
    response = urllib.request.urlopen(request)
    response_json = json.loads(response.read().decode())
    return response_json['token']


def generate_auth_header(token):
    auth = base64.b64encode(('x-access-token:' + token).encode('ascii'))
    return 'Basic ' + auth.decode('ascii')


def verify_template_repo(token, cac_org, template_repo):
    # Attempt to view the template repo
    try:
        url = 'https://api.github.com/repos/' + cac_org + '/' + template_repo
        headers = {
            'Accept': 'application/vnd.github+json',
            'Authorization': 'Bearer ' + token,
            'X-GitHub-Api-Version': '2022-11-28'
        }
        request = urllib.request.Request(url, headers=headers)
        urllib.request.urlopen(request)
    except:
        print('Could not find the template repo at ' + url)
        sys.exit(1)


def verify_new_repo(token, cac_org, new_repo):
    # Attempt to view the new repo
    try:
        url = 'https://api.github.com/repos/' + cac_org + '/' + new_repo
        headers = {
            'Accept': 'application/vnd.github+json',
            'Authorization': 'Bearer ' + token,
            'X-GitHub-Api-Version': '2022-11-28'
        }
        request = urllib.request.Request(url, headers=headers)
        urllib.request.urlopen(request)
        return True
    except:
        return False


def create_new_repo(token, cac_org, new_repo):
    # If we could not view the repo, assume it needs to be created.
    # https://docs.github.com/en/rest/repos/repos?apiVersion=2022-11-28#create-an-organization-repository
    # Note you have to use the token rather than the JWT:
    # https://stackoverflow.com/questions/39600396/bad-credentails-for-jwt-for-github-integrations-api
    url = 'https://api.github.com/orgs/' + cac_org + '/repos'
    headers = {
        'Authorization': 'token ' + token,
        'Content-Type': 'application/json',
        'Accept': 'application/vnd.github+json',
        'X-GitHub-Api-Version': '2022-11-28',
    }
    body = {'name': new_repo}
    request = urllib.request.Request(url, headers=headers, data=json.dumps(body).encode('utf-8'))
    urllib.request.urlopen(request)


def fork_repo(token, cac_org, new_repo, template_repo):
    # Clone the repo and add the upstream repo
    execute(['git', 'clone', 'https://' + 'x-access-token:' + token + '@'
             + 'github.com/' + cac_org + '/' + new_repo + '.git'])
    execute(
        ['git', 'remote', 'add', 'upstream', 'https://' + 'x-access-token:' + token + '@'
         + 'github.com/' + cac_org + '/' + template_repo + '.git'],
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
            print('The repo https://github.com/' + cac_org + '/' + new_repo + ' has already been forked.')
            sys.exit(0)

    # Create a new branch representing the forked main branch.
    execute(['git', 'checkout', '-b', branch], cwd=new_repo)

    # Hard reset it to the template main branch.
    execute(['git', 'reset', '--hard', 'upstream/' + branch], cwd=new_repo)

    # Push the changes.
    execute(['git', 'push', 'origin', branch], cwd=new_repo)


token = generate_github_token()
cac_org = parser.git_organization.strip()
tenant_name_sanitized = re.sub('[^a-zA-Z0-9]', '_', parser.tenant_name.lower().strip())
new_project_name_sanitized = re.sub('[^a-zA-Z0-9]', '_', parser.new_project_name.lower().strip())
original_project_name_sanitized = re.sub('[^a-zA-Z0-9]', '_', parser.original_project_name.lower().strip())
project_name_sanitized = new_project_name_sanitized if len(new_project_name_sanitized) != 0 \
    else original_project_name_sanitized
new_repo = tenant_name_sanitized + '_' + project_name_sanitized
template_repo = parser.template_repo_name.strip()
branch = 'main'

# This is the value of the forked git repo
set_octopusvariable('NewRepo', 'https://github.com/' + cac_org + '/' + new_repo)

verify_template_repo(token, cac_org, template_repo)
if not verify_new_repo(token, cac_org, new_repo):
    create_new_repo(token, cac_org, new_repo)
fork_repo(token, cac_org, new_repo, template_repo)

print(
    'Repo was forked from ' + 'https://github.com/' + cac_org + '/' + template_repo + ' to '
    + 'https://github.com/' + cac_org + '/' + new_repo)
