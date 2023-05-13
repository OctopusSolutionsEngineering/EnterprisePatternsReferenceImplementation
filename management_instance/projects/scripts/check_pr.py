import subprocess
import json
import os
import shutil
from urllib.request import Request
import sys
from pathlib import Path

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


execute(['git', 'config', '--global', 'user.email', 'octopus@octopus.com'])
execute(['git', 'config', '--global', 'user.name', 'Octopus Server'])

webhook_body = get_octopusvariable("Webhook.Pr.Body") if "get_octopusvariable" in globals() else Path(
    'test.json').read_text()
pr = json.loads(webhook_body)
base_repo = pr['base']['repo']['clone_url']

if os.path.exists('clone'):
    shutil.rmtree('clone')

os.mkdir('clone')

execute(['git', 'clone', base_repo.replace('localhost', 'gitea'), '.'], 'clone')

if not os.path.exists('clone/check.js') or not os.path.exists('clone/package.json'):
    print('No check.js file in the main branch')
    sys.exit(1)

shutil.copy2('clone/check.js', '.')
shutil.copy2('clone/package.json', '.')

execute(['git', 'checkout', '-b', pr['head']['ref'], pr['base']['ref']], 'clone')
execute(['git', 'pull', 'origin', pr['head']['ref']], 'clone')
execute(['git', 'checkout', pr['base']['ref']], 'clone')
execute(['git', 'merge', '--no-ff', '--no-edit', pr['head']['ref']], 'clone')

execute(['npm', 'install'])
stdout, stderr, retcode = execute(['node', 'check.js', 'clone/.octopus/project'])

print(stdout)

shutil.rmtree('clone')
shutil.rmtree('node_modules')
os.remove('check.js')
os.remove('package.json')
os.remove('package-lock.json')

url = "http://gitea:3000/api/v1/repos/" + pr['base']['repo']['full_name'] + "/statuses/" + pr['head']['sha']
status = {"context": "octopus", "description": stdout, "state": "success" if retcode == 0 else "failure",
          "target_url": "http://localhost:18080"}

request = Request(url, headers={"Content-Type": "application/json"} or {}, data=json.dumps(status).encode("utf-8"))
