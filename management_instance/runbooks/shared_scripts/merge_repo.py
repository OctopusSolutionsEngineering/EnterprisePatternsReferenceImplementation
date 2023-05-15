import subprocess
import sys
import os

if "get_octopusvariable" not in globals():
    print("Script must be run as an Octopus step")
    sys.exit(1)


def execute(args, cwd=None, env=None, print_args=None, print_output=printverbose):
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


cac_proto = '${cac_proto}'
cac_host = '${cac_host}'
cac_org = '${cac_org}'
cac_username = '${cac_username}'
cac_password = '${cac_password}'
new_repo = '${new_repo}'
template_repo = '${template_repo}'
project_dir = '${project_dir}'
branch = 'main'

# Set some default user details
execute(['git', 'config', '--global', 'user.email', 'octopus@octopus.com'])
execute(['git', 'config', '--global', 'user.name', 'Octopus Server'])

# Clone the template repo to test for a step template reference
os.mkdir('template')
execute(['git', 'clone',
         cac_proto + '://' + cac_username + ':' + cac_password + '@' + cac_host + '/' + cac_org + '/' + template_repo + '.git', 'template'])
if branch != 'master' and branch != 'main':
    execute(['git', 'checkout', '-b', branch, 'origin/' + branch], cwd='template')
else:
    execute(['git', 'checkout', branch], cwd='template')

try:
    with open('template/' + project_dir + '/deployment_process.ocl', 'r') as file:
        data = file.read()
        if 'ActionTemplates' in data:
            print("Template repo references a step template. Step templates can not be merged across spaces or instances.")
            sys.exit(1)
except Exception as ex:
    print(ex)
    print('Failed to open template/' + project_dir + '/deployment_process.ocl to check for ActionTemplates')

# Merge the template changes
execute(['git', 'clone',
         cac_proto + '://' + cac_username + ':' + cac_password + '@' + cac_host + '/' + cac_org + '/' + new_repo + '.git'])
execute(['git', 'remote', 'add', 'upstream',
         cac_proto + '://' + cac_username + ':' + cac_password + '@' + cac_host + '/' + cac_org + '/' + template_repo + '.git'],
        cwd=new_repo)
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
    execute(['git', 'merge' '--continue'], cwd=new_repo, env=dict(os.environ, GIT_EDITOR="/bin/true"))

    _, _, diff_result = execute(['git', 'diff', '--quiet', '--exit-code', '@{upstream}'], cwd=new_repo)
    if diff_result != 0:
        execute(['git', 'push' 'origin'], cwd=new_repo)
    else:
        print('No changes found.')
else:
    print(
        'Template repo branch could not be automatically merged into project branch. This merge will need to be resolved manually.')
    sys.exit(1)
