import subprocess
import json
import os
import shutil
from urllib.request import urlopen, Request


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

pr = json.loads(get_octopusvariable("Webhook.Pr.Body"))
base_repo = pr['base']['repo']['clone_url']

pr['head']['ref']

execute(['git', 'clone', base_repo + "/localhost/gitea", '.'])

if not os.path.exists('check.js') or not os.path.exists('package.json'):
    print('No check.js file in the main branch')

shutil.copy2('check.js', '..')
shutil.copy2('package.json', '..')

execute(['git', 'checkout', '-b', pr['head']['ref'], pr['base']['ref']], 'clone')
execute(['git', 'pull', 'origin', pr['head']['ref']], 'clone')
execute(['git', 'checkout', pr['base']['ref']], 'clone')
execute(['git', 'merge', '--no-ff', '--no-edit', pr['head']['ref']], 'clone')

execute(['npm', 'install'])
stdout, stderr, retcode = execute(['node', 'check.js', 'clone/.octopus/project'])

print(stdout)

shutil.rmtree('clone')

url = "http://gitea:3000/api/v1/repos/" + pr['base']['repo']['full_name'] + "/statuses/" + pr['head']['sha']
status = {"context": "octopus", "description": stdout.rep, "state": "success" if retcode == 0 else "failure",
          "target_url": "http://localhost:18080"}

request = Request(url, headers={"Content-Type": "application/json"} or {}, data=json.dumps(status))
