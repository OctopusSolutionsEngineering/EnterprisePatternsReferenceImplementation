import subprocess
import sys
import os
import urllib.request
import base64
import re

# If this script is not being run as part of an Octopus step, print directly to std out.
if "printverbose" not in globals():
    def printverbose(msg):
        print(msg)

if "get_octopusvariable" not in globals():
    def get_octopusvariable(variable):
        if variable == 'Git.Credentials.Username':
            return os.environ['GIT_CREDENTIALS_USERNAME']
        if variable == 'Git.Credentials.Password':
            return os.environ['GIT_CREDENTIALS_PASSWORD']


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


def check_repo_exists(url, username, password):
    try:
        auth = base64.b64encode((username + ':' + password).encode('ascii'))
        auth_header = "Basic " + auth.decode('ascii')
        headers = {
            "Authorization": auth_header
        }
        request = urllib.request.Request(url, headers=headers)
        urllib.request.urlopen(request)
        return True
    except Exception as ex:
        return False


cac_proto = '${cac_proto}'
cac_host = '${cac_host}'
cac_org = '${cac_org}'
cac_username = get_octopusvariable('Git.Credentials.Username')
cac_password = get_octopusvariable('Git.Credentials.Password')
new_repo = '${new_repo}'
template_repo = '${template_repo}'
project_dir = '${project_dir}'
branch = 'main'

new_repo_url = cac_proto + '://' + cac_host + '/' + cac_org + '/' + new_repo + '.git'
new_repo_url_wth_creds = cac_proto + '://' + cac_username + ':' + cac_password + '@' + cac_host + '/' + cac_org + '/' + new_repo + '.git'
template_repo_url = cac_proto + '://' + cac_host + '/' + cac_org + '/' + template_repo + '.git'
template_repo_url_with_creds = cac_proto + '://' + cac_username + ':' + cac_password + '@' + cac_host + '/' + cac_org + '/' + template_repo + '.git'

if not check_repo_exists(new_repo_url, cac_username, cac_password):
    print('Downstream repo ' + new_repo_url + ' is not available')
    sys.exit(1)

if not check_repo_exists(template_repo_url, cac_username, cac_password):
    print('Upstream repo ' + new_repo_url + ' is not available')
    sys.exit(1)

# Set some default user details
execute(['git', 'config', '--global', 'user.email', 'octopus@octopus.com'])
execute(['git', 'config', '--global', 'user.name', 'Octopus Server'])

# Clone the template repo to test for a step template reference
os.mkdir('template')
execute(['git', 'clone', template_repo_url, 'template'])
if branch != 'master' and branch != 'main':
    execute(['git', 'checkout', '-b', branch, 'origin/' + branch], cwd='template')
else:
    execute(['git', 'checkout', branch], cwd='template')

try:
    with open('template/' + project_dir + '/deployment_process.ocl', 'r') as file:
        data = file.read()
        if 'ActionTemplates' in data:
            print(
                'Template repo references a step template. Step templates can not be merged across spaces or instances.')
            sys.exit(1)
except Exception as ex:
    print(ex)
    print('Failed to open template/' + project_dir + '/deployment_process.ocl to check for ActionTemplates')

# Merge the template changes
execute(['git', 'clone', new_repo_url_wth_creds])
execute(['git', 'remote', 'add', 'upstream', template_repo_url_with_creds], cwd=new_repo)
execute(['git', 'fetch', '--all'], cwd=new_repo)
execute(['git', 'checkout', '-b', 'upstream-' + branch, 'upstream/' + branch], cwd=new_repo)

# Checkout the project branch, assuming "main" or "master" are already linked upstream
if branch != 'master' and branch != 'main':
    execute(['git', 'checkout', '-b', branch, 'origin/' + branch], cwd=new_repo)
else:
    execute(['git', 'checkout', branch], cwd=new_repo)

# Test to see if we can merge the two branches together without conflict.
# https://stackoverflow.com/a/501461/8246539
_, _, merge_result = execute(['git', 'merge', '--no-commit', '--no-ff', 'upstream-' + branch], cwd=new_repo)
if merge_result == 0:
    # All good, so actually do the merge
    execute(['git', 'merge', 'upstream-' + branch], cwd=new_repo)
    execute(['git', 'merge', '--continue'], cwd=new_repo, env=dict(os.environ, GIT_EDITOR="/bin/true"))

    _, _, diff_result = execute(['git', 'diff', '--quiet', '--exit-code', '@{upstream}'], cwd=new_repo)
    if diff_result != 0:
        execute(['git', 'push', 'origin'], cwd=new_repo)
        print('Changed merged successfully')
    else:
        print('No changes found.')
else:
    print(
        'Template repo branch could not be automatically merged into project branch. This merge will need to be resolved manually.')
    sys.exit(1)
