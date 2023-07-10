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
        description='Create a GitHub issue'
    )
    parser.add_argument('--github-app-id', action='store', default=get_octopusvariable_quiet('GitHub.App.Id'))
    parser.add_argument('--github-app-installation-id', action='store',
                        default=get_octopusvariable_quiet('GitHub.App.InstallationId'))
    parser.add_argument('--github-app-private-key', action='store',
                        default=get_octopusvariable_quiet('GitHub.App.PrivateKey'))
    parser.add_argument('--git-organization', action='store', default=get_octopusvariable_quiet('Git.Url.Organization'))
    parser.add_argument('--git-repo', action='store')
    parser.add_argument('--issue-title', action='store')
    parser.add_argument('--issue-body', action='store')
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


def create_issue(token, org, repo, title, body):
    # Attempt to view the template repo
    try:
        url = 'https://api.github.com/repos/' + org + '/' + repo + '/issues'
        headers = {
            'Accept': 'application/vnd.github+json',
            'Authorization': 'Bearer ' + token,
            'X-GitHub-Api-Version': '2022-11-28'
        }
        body_object = {
            title: title,
            body: body
        }
        request = urllib.request.Request(url, headers=headers, data=json.dumps(body_object).encode('utf-8'))
        urllib.request.urlopen(request)
    except:
        print('Could not create the GitHub issue')
        sys.exit(1)


token = generate_github_token()
org = parser.git_organization.strip()
repo = parser.git_repo.strip()
title = parser.issue_title.strip()
body = parser.issue_body.strip()

create_issue(token, org, repo, title, body)