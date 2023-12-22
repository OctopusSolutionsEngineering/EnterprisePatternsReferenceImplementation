# This script forks a GitHub repo. It creates a token from a GitHub App installation to avoid
# having to use a regular user account.
import subprocess
import sys
import time

# Install our own dependencies
subprocess.check_call([sys.executable, '-m', 'pip', 'install', 'jwt'])

import argparse
import subprocess
import sys
import os
import urllib.request
import base64
import re
import json
import jwt

# If this script is not being run as part of an Octopus step, print directly to std out.
if "printverbose" not in globals():
    def printverbose(msg):
        print(msg)

if "printhighlight" not in globals():
    def printhighlight(msg):
        print(msg)

# If this script is not being run as part of an Octopus step, return variables from environment variables.
# Periods are replaced with underscores, and the variable name is converted to uppercase
if "get_octopusvariable" not in globals():
    def get_octopusvariable(variable):
        return os.environ[re.sub('\\.', '_', variable.upper())]


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


def printverbose_noansi(output):
    """
    Strip ANSI color codes and print the output as verbose
    :param output: The output to print
    """
    output_no_ansi = re.sub('\x1b\[[0-9;]*m', '', output)
    printverbose(output_no_ansi)


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


def check_repo_exists(git_protocol, git_host, git_organization, new_repo, username, password):
    url = git_protocol + '://' + git_host + '/' + git_organization + '/' + new_repo + '.git'
    try:
        auth = base64.b64encode((username + ':' + password).encode('ascii'))
        auth_header = "Basic " + auth.decode('ascii')
        headers = {
            "Authorization": auth_header
        }
        request = urllib.request.Request(url, headers=headers)
        urllib.request.urlopen(request)
        return True
    except:
        return False


def check_github_repo_exists(git_organization, new_repo, username, password):
    url = 'https://api.github.com/repos/' + git_organization + '/' + new_repo
    try:
        auth = base64.b64encode((username + ':' + password).encode('ascii'))
        auth_header = "Basic " + auth.decode('ascii')
        headers = {
            "Authorization": auth_header
        }
        request = urllib.request.Request(url, headers=headers)
        urllib.request.urlopen(request)
        return True
    except:
        return False


def generate_github_token(github_app_id, github_app_private_key, github_app_installation_id):
    # Generate the tokens used by git and the GitHub API
    app_id = github_app_id
    signing_key = jwt.jwk_from_pem(github_app_private_key.encode('utf-8'))

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
    url = 'https://api.github.com/app/installations/' + github_app_installation_id + '/access_tokens'
    headers = {
        'Authorization': 'Bearer ' + encoded_jwt,
        'Accept': 'application/vnd.github+json',
        'X-GitHub-Api-Version': '2022-11-28'
    }
    request = urllib.request.Request(url, headers=headers, method='POST')
    response = urllib.request.urlopen(request)
    response_json = json.loads(response.read().decode())
    return response_json['token']


def init_argparse():
    parser = argparse.ArgumentParser(
        usage='%(prog)s [OPTION] [FILE]...',
        description='Merge the upstream repo into the downstream repo'
    )
    parser.add_argument('--original-project-name',
                        action='store',
                        default=get_octopusvariable_quiet('Octopus.Project.Name') or get_octopusvariable_quiet(
                            'MergeRepo.Octopus.Project.Name'))
    parser.add_argument('--new-project-name',
                        action='store',
                        default=get_octopusvariable_quiet('Exported.Project.Name') or get_octopusvariable_quiet(
                            'MergeRepo.Exported.Project.Name'))
    parser.add_argument('--git-protocol',
                        action='store',
                        default=get_octopusvariable_quiet('Git.Url.Protocol') or get_octopusvariable_quiet(
                            'MergeRepo.Git.Url.Protocol'))
    parser.add_argument('--git-host',
                        action='store',
                        default=get_octopusvariable_quiet('Git.Url.Host') or get_octopusvariable_quiet(
                            'MergeRepo.Git.Url.Host'))
    parser.add_argument('--git-username',
                        action='store',
                        default=get_octopusvariable_quiet('Git.Credentials.Username') or get_octopusvariable_quiet(
                            'MergeRepo.Git.Credentials.Username'))
    parser.add_argument('--git-password',
                        action='store',
                        default=get_octopusvariable_quiet('Git.Credentials.Password') or get_octopusvariable_quiet(
                            'MergeRepo.Git.Credentials.Password'))
    parser.add_argument('--git-organization',
                        action='store',
                        default=get_octopusvariable_quiet('Git.Url.Organization') or get_octopusvariable_quiet(
                            'MergeRepo.Git.Url.Organization'))
    parser.add_argument('--github-app-id', action='store',
                        default=get_octopusvariable_quiet('GitHub.App.Id') or get_octopusvariable_quiet(
                            'PreviewMerge.GitHub.App.Id'))
    parser.add_argument('--github-app-installation-id', action='store',
                        default=get_octopusvariable_quiet('GitHub.App.InstallationId') or get_octopusvariable_quiet(
                            'PreviewMerge.GitHub.App.InstallationId'))
    parser.add_argument('--github-app-private-key', action='store',
                        default=get_octopusvariable_quiet('GitHub.App.PrivateKey') or get_octopusvariable_quiet(
                            'PreviewMerge.GitHub.App.PrivateKey'))
    parser.add_argument('--tenant-name',
                        action='store',
                        default=get_octopusvariable_quiet('Octopus.Deployment.Tenant.Name'))
    parser.add_argument('--template-repo-name',
                        action='store',
                        default=re.sub('[^a-zA-Z0-9]', '_', get_octopusvariable_quiet('Octopus.Project.Name').lower()))
    parser.add_argument('--repo-name',
                        action='store',
                        default='')
    return parser.parse_known_args()


def set_git_user():
    """
    Configure the user details that appear in the git logs
    """
    execute(['git', 'config', '--global', 'user.email', 'octopus@octopus.com'])
    execute(['git', 'config', '--global', 'user.name', 'Octopus Server'])


def clone_repo(template_repo_name_url, branch):
    """
    Clone the template repo into the template directory
    :param template_repo_name_url: The template repo url
    :param branch: The branch holding the template code
    :return: The directory holding the template repo
    """
    # Clone the template repo to test for a step template reference
    os.mkdir('template')
    execute(['git', 'clone', template_repo_name_url, 'template'])
    if branch != 'master' and branch != 'main':
        execute(['git', 'checkout', '-b', branch, 'origin/' + branch], cwd='template')
    else:
        execute(['git', 'checkout', branch], cwd='template')
    return 'template'


def add_upstream_remote(new_repo_url_wth_creds, template_repo_name_url_with_creds, new_repo):
    """
    Clone the downstream repo and link the upstream remote
    :param new_repo_url_wth_creds: The downstream repo url
    :param template_repo_name_url_with_creds: The upstream repo
    :param new_repo: The directory to clone the downstream repo into
    :return:
    """
    execute(['git', 'clone', new_repo_url_wth_creds])
    execute(['git', 'remote', 'add', 'upstream', template_repo_name_url_with_creds], cwd=new_repo)
    execute(['git', 'fetch', '--all'], cwd=new_repo)
    execute(['git', 'checkout', '-b', 'upstream-' + branch, 'upstream/' + branch], cwd=new_repo)

    # Checkout the project branch, assuming "main" or "master" are already linked upstream
    if branch != 'master' and branch != 'main':
        execute(['git', 'checkout', '-b', branch, 'origin/' + branch], cwd=new_repo)
    else:
        execute(['git', 'checkout', branch], cwd=new_repo)


def check_action_templates(project_dir, template_dir):
    """
    Verify that the template does not contain step templates.
    :param project_dir:  The name of the directory holding the Octopus CaC files
    :param template_dir: The directory holding the cloned template repo
    """
    try:
        with open(template_dir + '/' + project_dir + '/deployment_process.ocl', 'r') as file:
            data = file.read()
            if 'ActionTemplates' in data:
                print('Template repo references a step template. ' +
                      'Step templates can not be merged across spaces or instances.')
                sys.exit(1)
    except Exception as ex:
        print(ex)
        print('Failed to open ' + template_dir + '/' + project_dir +
              '/deployment_process.ocl to check for ActionTemplates')


def merge_changes(branch, new_repo, template_repo_name_url, new_repo_url):
    """
    Merge the changes between the upstream template repo and the downstream managed repo.
    :param branch: The branch holding the CaC code
    :param new_repo: The directory containing the downstream repo
    :param template_repo_name_url: The url of the upstream repo
    :param new_repo_url: The URL of the downstream repo
    """
    # Test to see if we can merge the two branches together without conflict.
    # https://stackoverflow.com/a/501461/8246539
    _, _, merge_result = execute(['git', 'merge', '--no-commit', '--no-ff', 'upstream-' + branch], cwd=new_repo)
    if merge_result == 0:
        # All good, so actually do the merge
        execute(['git', 'merge', 'upstream-' + branch], cwd=new_repo)
        execute(['git', 'merge', '--continue'], cwd=new_repo, env=dict(os.environ, GIT_EDITOR="/bin/true"))

        _, _, diff_result = execute(['git', 'diff', '--quiet', '--exit-code', '@{upstream}'], cwd=new_repo)
        if diff_result != 0:
            _, _, push_result = execute(['git', 'push', 'origin'], cwd=new_repo)
            if push_result == 0:
                printhighlight('Changes merged successfully from upstream repo ' + template_repo_name_url
                               + ' into the downstream repo ' + new_repo_url)
            else:
                print('The git push operation failed. Check the verbose logs for more details.')
                sys.exit(1)
        else:
            printhighlight('No changes found in the upstream repo ' + template_repo_name_url +
                           ' that do not exist in the downstream repo ' + new_repo_url)
    else:
        print('Template repo branch could not be automatically merged into project branch. ' +
              'This merge will need to be resolved manually.')
        printhighlight('To resolve the conflicts, run the following commands:')
        printhighlight('mkdir cac')
        printhighlight('cd cac')
        printhighlight('git clone ' + new_repo_url + ' .')
        printhighlight('git remote add upstream ' + template_repo_name_url)
        printhighlight('git fetch --all')
        printhighlight('git checkout -b upstream-' + branch + ' upstream/' + branch)
        if branch != 'master' and branch != 'main':
            printhighlight('git checkout -b ' + branch + ' origin/' + branch)
        else:
            printhighlight('git checkout ' + branch)
        printhighlight('git merge-base ' + branch + ' upstream-' + branch)
        printhighlight('git merge --no-commit --no-ff upstream-' + branch)
        sys.exit(1)


parser, _ = init_argparse()

# The access token is generated from a github app or supplied directly as an access token
token = generate_github_token(parser.github_app_id, parser.github_app_private_key,
                              parser.github_app_installation_id) if len(
    parser.git_password.strip()) == 0 else parser.git_password.strip()
username = 'x-access-token' if len(parser.git_username.strip()) == 0 else parser.git_username.strip()

tenant_name_sanitized = re.sub('[^a-zA-Z0-9]', '_', parser.tenant_name.lower())
new_project_name_sanitized = re.sub('[^a-zA-Z0-9]', '_', parser.new_project_name.lower())
original_project_name_sanitized = re.sub('[^a-zA-Z0-9]', '_', parser.original_project_name.lower())
project_name_sanitized = new_project_name_sanitized if len(new_project_name_sanitized) != 0 \
    else original_project_name_sanitized
new_repo = parser.repo_name if len(parser.repo_name) != 0 else tenant_name_sanitized + '_' + project_name_sanitized
project_dir = '.octopus/project'
branch = 'main'

new_repo_url = parser.git_protocol + '://' + parser.git_host + '/' + parser.git_organization + '/' + new_repo + '.git'
new_repo_url_wth_creds = parser.git_protocol + '://' + token + ':' + token + '@' + \
                         parser.git_host + '/' + parser.git_organization + '/' + new_repo + '.git'
template_repo_name_url = parser.git_protocol + '://' + parser.git_host + '/' + parser.git_organization + '/' + \
                         parser.template_repo_name + '.git'
template_repo_name_url_with_creds = parser.git_protocol + '://' + token + ':' + \
                                    token + '@' + parser.git_host + '/' + \
                                    parser.git_organization + '/' + parser.template_repo_name + '.git'

if parser.git_host == 'github.com':
    if not check_github_repo_exists(parser.git_organization, new_repo, username, token):
        print('Downstream repo ' + new_repo_url + ' is not available')
        sys.exit(1)

    if not check_github_repo_exists(parser.git_organization, parser.template_repo_name, username, token):
        print('Upstream repo ' + template_repo_name_url + ' is not available')
        sys.exit(1)
else:
    if not check_repo_exists(parser.git_protocol, parser.git_host, parser.git_organization, new_repo, username, token):
        print('Downstream repo ' + new_repo_url + ' is not available')
        sys.exit(1)

    if not check_repo_exists(parser.git_protocol, parser.git_host, parser.git_organization, parser.template_repo_name, username, token):
        print('Upstream repo ' + template_repo_name_url + ' is not available')
        sys.exit(1)

set_git_user()
template_dir = clone_repo(template_repo_name_url, branch)
check_action_templates(project_dir, template_dir)
add_upstream_remote(new_repo_url_wth_creds, template_repo_name_url_with_creds, new_repo)
merge_changes(branch, new_repo, template_repo_name_url, new_repo_url)
