import json
import subprocess
import sys
import os
import urllib.request
import base64
import re
import argparse

# If this script is not being run as part of an Octopus step, return variables from environment variables.
# Periods are replaced with underscores, and the variable name is converted to uppercase
if "get_octopusvariable" not in globals():
    def get_octopusvariable(variable):
        return os.environ[re.sub('\\.', '_', variable.upper())]

# If this script is not being run as part of an Octopus step, print directly to std out.
if "printverbose" not in globals():
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
    """
    init_argparse does triple duty. It supports running the script as a regular CLI command, supports running the
    script in the context of a plain script step, and supports the script when embedded in a step template. This is
    why the values of all arguments are sourced from Octopus variables, and why we source from two styles of variables:
    regular project variables and prefixed step template variables.
    """
    parser = argparse.ArgumentParser(
        usage='%(prog)s [OPTION] [FILE]...',
        description='Find conflicts between Git repos'
    )
    parser.add_argument('--cac-username',
                        action='store',
                        default=get_octopusvariable_quiet('Git.Credentials.Username') or get_octopusvariable_quiet(
                            'ForkRepo.Git.Credentials.Username'),
                        help='The Git username')
    parser.add_argument('--cac-password',
                        action='store',
                        default=get_octopusvariable_quiet('Git.Credentials.Password') or get_octopusvariable_quiet(
                            'ForkRepo.Git.Credentials.Password'),
                        help='The Git password')
    parser.add_argument('--git-protocol',
                        action='store',
                        default=get_octopusvariable_quiet('Git.Url.Protocol') or get_octopusvariable_quiet(
                            'ForkRepo.Git.Url.Protocol'),
                        help='The Git protocol (http or https)')
    parser.add_argument('--git-host',
                        action='store',
                        default=get_octopusvariable_quiet('Git.Url.Host') or get_octopusvariable_quiet(
                            'ForkRepo.Git.Url.Host'),
                        help='The Git hostname (e.g. github.com or gitlab.com)')
    parser.add_argument('--git-organization',
                        action='store',
                        default=get_octopusvariable_quiet('Git.Url.Organization') or get_octopusvariable_quiet(
                            'ForkRepo.Git.Url.Organization'),
                        help='The Git organization')
    parser.add_argument('--template-repo',
                        action='store',
                        default=get_octopusvariable_quiet('Git.Url.Template') or get_octopusvariable_quiet(
                            'ForkRepo.Git.Url.Template'),
                        help='The name of the repository holding the upstream template project')
    parser.add_argument('--new-repo',
                        action='store',
                        default=get_octopusvariable_quiet('Git.Url.NewRepo') or get_octopusvariable_quiet(
                            'ForkRepo.Git.Url.NewRepo'),
                        help='The name of the repository holding the new downstream template project')
    parser.add_argument('--new-project-name',
                        action='store',
                        default=get_octopusvariable_quiet('Exported.Project.Name') or get_octopusvariable_quiet(
                            'ForkRepo.Exported.Project.Name'),
                        help='The name of the new project. This name is combined with the tenant to produce the new repo name. This value is ignored if --new-repo is supplied.')
    parser.add_argument('--mainline-branch',
                        action='store',
                        default=get_octopusvariable_quiet('Git.Branch.MainLine') or get_octopusvariable_quiet(
                            'ForkRepo.Git.Branch.MainLine'),
                        help='The branch name to use for the fork. Defaults to "main".')

    return parser.parse_known_args()


parser, _ = init_argparse()

tenant_name_sanitized = re.sub('[^a-zA-Z0-9]', '_', get_octopusvariable_quiet('Octopus.Deployment.Tenant.Name').lower())
new_project_name_sanitized = re.sub('[^a-zA-Z0-9]', '_', get_octopusvariable_quiet('Exported.Project.Name').lower())
original_project_name_sanitized = re.sub('[^a-zA-Z0-9]', '_', get_octopusvariable_quiet('Octopus.Project.Name').lower())
project_name_sanitized = new_project_name_sanitized if len(new_project_name_sanitized) != 0 \
    else original_project_name_sanitized
new_repo = parser.new_repo or tenant_name_sanitized + '_' + project_name_sanitized
template_repo = parser.template_repo or re.sub('[^a-zA-Z0-9]', '_',
                                               get_octopusvariable_quiet('Octopus.Project.Name').lower())
branch = parser.mainline_branch or 'main'

# Attempt to view the template repo
try:
    url = parser.git_protocol + '://' + parser.git_host + '/' + parser.git_organization + '/' + template_repo + '.git'
    auth = base64.b64encode((parser.cac_username + ':' + parser.cac_password).encode('ascii'))
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
    url = parser.git_protocol + '://' + parser.git_host + '/' + parser.git_organization + '/' + new_repo + '.git'
    auth = base64.b64encode((parser.cac_username + ':' + parser.cac_password).encode('ascii'))
    auth_header = "Basic " + auth.decode('ascii')
    headers = {
        "Authorization": auth_header,
    }
    request = urllib.request.Request(url, headers=headers)
    urllib.request.urlopen(request)
except:
    # If we could not view the repo, assume it needs to be created.
    url = parser.git_protocol + '://' + parser.git_host + '/api/v1/org/' + parser.git_organization + '/repos'
    auth = base64.b64encode((parser.cac_username + ':' + parser.cac_password).encode('ascii'))
    auth_header = "Basic " + auth.decode('ascii')
    headers = {
        "Authorization": auth_header,
        'Content-Type': 'application/json',
        'Accept': 'application/json'
    }
    body = {'name': new_repo}
    request = urllib.request.Request(url, headers=headers, data=json.dumps(body).encode('utf-8'))
    urllib.request.urlopen(request)

# Clone the repo and add the upstream repo
execute(['git', 'clone', parser.git_protocol + '://' + parser.cac_username + ':' + parser.cac_password + '@'
         + parser.git_host + '/' + parser.git_organization + '/' + new_repo + '.git'])
execute(
    ['git', 'remote', 'add', 'upstream',
     parser.git_protocol + '://' + parser.cac_username + ':' + parser.cac_password + '@'
     + parser.git_host + '/' + parser.git_organization + '/' + template_repo + '.git'],
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
    'Repo was forked from ' + parser.git_protocol + '://' + parser.git_host + '/' + parser.git_organization + '/' + template_repo + ' to '
    + parser.git_protocol + '://' + parser.git_host + '/' + parser.git_organization + '/' + new_repo)
