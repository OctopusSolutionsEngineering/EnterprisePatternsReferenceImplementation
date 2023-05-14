import subprocess
import json
import os
import shutil
from urllib.request import Request
import sys
from pathlib import Path
from urllib.parse import urlparse

if "get_octopusvariable" not in globals():
    print("Script must be run as an Octopus step")
    sys.exit(1)


def execute(args, cwd=None):
    process = subprocess.Popen(args,
                               stdout=subprocess.PIPE,
                               stderr=subprocess.PIPE,
                               text=True,
                               cwd=cwd)
    stdout, stderr = process.communicate()
    retcode = process.returncode
    return stdout, stderr, retcode


try:
    # Some dummy values expected by git.
    execute(['git', 'config', '--global', 'user.email', 'octopus@octopus.com'])
    execute(['git', 'config', '--global', 'user.name', 'Octopus Server'])

    # Get the webhook body from the Octopus variable, or a test file.
    # Comment out the check at the start of the script to use the local test file.
    webhook_body = get_octopusvariable("Webhook.Pr.Body") if "get_octopusvariable" in globals() else Path(
        'test.json').read_text()
    pr = json.loads(webhook_body)
    base_repo = pr['base']['repo']['clone_url']

    # Clean up any existing clones
    if os.path.exists('clone'):
        shutil.rmtree('clone')

    # This is the directory the PR is cloned into
    os.mkdir('clone')

    # Clone the base repo
    execute(['git', 'clone', base_repo.replace('localhost', 'gitea'), '.'], 'clone')

    # We expect to find a file called check.js (and its associated package.json file).
    # If not, there is nothing to check
    if not os.path.exists('clone/check.js') or not os.path.exists('clone/package.json'):
        print('No check.js file in the main branch')
        sys.exit(1)

    # Copy the check files out of the main branch
    shutil.copy2('clone/check.js', '.')
    shutil.copy2('clone/package.json', '.')

    # Checkout the branch being merged, and initiate the merge
    execute(['git', 'checkout', '-b', pr['head']['ref'], pr['base']['ref']], 'clone')
    execute(['git', 'pull', 'origin', pr['head']['ref']], 'clone')
    execute(['git', 'checkout', pr['base']['ref']], 'clone')
    execute(['git', 'merge', '--no-ff', '--no-edit', pr['head']['ref']], 'clone')

    # Install the check file dependencies and run the check
    execute(['npm', 'install'])
    stdout, stderr, retcode = execute(['node', 'check.js', 'clone/.octopus/project'])

    # This is the result of the check
    print(stdout)

    # Gitea thinks it is hosted on localhost, but we know it is hosted on "gitea"
    parsedUrl = urlparse(pr['url'])
    baseUrl = parsedUrl.scheme + '://gitea:' + str(parsedUrl.port)

    # Post the check results back to Gitea
    url = baseUrl + '/api/v1/repos/' + pr['base']['repo']['full_name'] + "/statuses/" + pr['head']['sha']
    status = {"context": "octopus", "description": stdout, "state": "success" if retcode == 0 else "failure",
              "target_url": "http://localhost:18080"}

    request = Request(url, headers={"Content-Type": "application/json"} or {}, data=json.dumps(status).encode("utf-8"))
finally:
    # Clean everything up
    with contextlib.suppress(FileNotFoundError):
        shutil.rmtree('clone')
        shutil.rmtree('node_modules')
        os.remove('check.js')
        os.remove('package.json')
        os.remove('package-lock.json')
