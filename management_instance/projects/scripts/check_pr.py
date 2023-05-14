import subprocess
import json
import os
import shutil
import sys
from pathlib import Path
from urllib.parse import urlparse
import urllib.request
import contextlib
import base64

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

    # When passing JSON variables via the octo cli, the JSON will be an escaped string.
    # Double-decoding the input allows us to work around this.
    try:
        pr = json.loads(pr)
    except:
        print("failed to double decode value")

    base_repo = pr['pull_request']['base']['repo']['clone_url']

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
        sys.exit(0)

    # Copy the check files out of the main branch
    shutil.copy2('clone/check.js', '.')
    shutil.copy2('clone/package.json', '.')

    # Checkout the branch being merged, and initiate the merge
    execute(['git', 'checkout', '-b', pr['pull_request']['head']['ref'], pr['pull_request']['base']['ref']], 'clone')
    execute(['git', 'pull', 'origin', pr['pull_request']['head']['ref']], 'clone')
    execute(['git', 'checkout', pr['pull_request']['base']['ref']], 'clone')
    execute(['git', 'merge', '--no-ff', '--no-edit', pr['pull_request']['head']['ref']], 'clone')

    # Install the check file dependencies and run the check
    execute(['npm', 'install'])
    stdout, stderr, retcode = execute(['node', 'check.js', 'clone/.octopus/project'])

    # This is the result of the check
    print(stdout)
    print(stderr)

    # Gitea thinks it is hosted on localhost, but we know it is hosted on "gitea"
    parsedUrl = urlparse(pr['pull_request']['url'])
    baseUrl = parsedUrl.scheme + '://gitea:' + str(parsedUrl.port)

    # Post the check results back to Gitea
    url = baseUrl + '/api/v1/repos/' + pr['pull_request']['base']['repo']['full_name'] + "/statuses/" + \
          pr['pull_request']['head']['sha']
    runbook_url = "http://localhost:18080/app#/Spaces-1/projects/pr-checks/operations/runbooks/" + \
                  get_octopusvariable("Octopus.Runbook.Id") + \
                  "/snapshots/" + \
                  get_octopusvariable("Octopus.RunbookSnapshot.Id") + \
                  "/runs/" + \
                  get_octopusvariable("Octopus.RunbookRun.Id") + \
                  "?activeTab=taskLog"

    status = {"context": "octopus", "description": stdout, "state": "success" if retcode == 0 else "failure",
              "target_url": runbook_url}
    status_string = json.dumps(status)

    auth = base64.b64encode("octopus:Password01!".encode('ascii'))
    auth_header = "Basic " + auth.decode('ascii')

    headers = {
        "Authorization": auth_header,
        "Content-Type": "application/json"
    }

    request = urllib.request.Request(url, headers=headers, data=status_string.encode('utf-8'))
    with urllib.request.urlopen(request) as response:
        data = json.loads(response.read().decode("utf-8"))
        print("##octopus[stdout-verbose]")
        print(data)
        print("##octopus[stdout-default]")

finally:
    # Clean everything up
    with contextlib.suppress(FileNotFoundError):
        shutil.rmtree('clone')
        shutil.rmtree('node_modules')
        os.remove('check.js')
        os.remove('package.json')
        os.remove('package-lock.json')
