import json
import subprocess
import sys
import os
import urllib.request
import base64

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

        return ""

# If this script is not being run as part of an Octopus step, print directly to std out.
if "printverbose" not in globals():
    def printverbose(msg):
        print(msg)


def execute(args, cwd=None, print_args=None, print_output=printverbose):
    """
        The execute method provides the ability to execute external processes while capturing and returning the
        output to std err and std out and exit code.
    """
    process = subprocess.Popen(args,
                               stdout=subprocess.PIPE,
                               stderr=subprocess.PIPE,
                               text=True,
                               cwd=cwd)
    stdout, stderr = process.communicate()
    retcode = process.returncode

    if print_args is not None:
        print_output(' '.join(args))

    if print_output is not None:
        print_output(stdout)
        print_output(stderr)

    return stdout, stderr, retcode

# The values for these variables are injected by Terraform as it reads the file with the templatefile() function
cac_proto = '${cac_proto}'
cac_host = '${cac_host}'
cac_org = '${cac_org}'
cac_username = '${cac_username}'
cac_password = '${cac_password}'
new_repo = '${new_repo}'
template_repo = '${template_repo}'
branch = 'main'

# Attempt to view the template repo
try:
    url = cac_proto + '://' + cac_host + '/' + cac_org + '/' + template_repo + '.git'
    auth = base64.b64encode((cac_username + ':' + cac_password).encode('ascii'))
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
    auth = base64.b64encode((cac_username + ':' + cac_password).encode('ascii'))
    auth_header = "Basic " + auth.decode('ascii')
    headers = {
        "Authorization": auth_header,
    }
    request = urllib.request.Request(url, headers=headers)
    urllib.request.urlopen(request)
except:
    # If we could not view the repo, assume it needs to be created.
    url = cac_proto + '://' + cac_host + '/api/v1/org/' + cac_org + '/repos'
    auth = base64.b64encode((cac_username + ':' + cac_password).encode('ascii'))
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
execute(['git', 'clone', cac_proto + '://' + cac_username + ':' + cac_password + '@'
         + cac_host + '/' + cac_org + '/' + new_repo + '.git'])
execute(
    ['git', 'remote', 'add', 'upstream', cac_proto + '://' + cac_username + ':' + cac_password + '@'
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
