from bottle import route, run, request
import subprocess
import json


def execute(args, cwd=None):
    process = subprocess.Popen(args,
                               stdout=subprocess.PIPE,
                               stderr=subprocess.PIPE,
                               text=True,
                               cwd=cwd)
    stdout, stderr = process.communicate()
    retcode = process.returncode
    return stdout, stderr, retcode


@route('/', method='POST')
def index():
    body = json.dumps(request.json)

    print(body)

    stdout, stderr, _ = execute(
        ['/usr/bin/octo',
         'run-runbook',
         '--server', 'http://octopus:8080',
         '--apiKey', 'API-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA',
         '--space', 'Default',
         '--project', 'PR Checks',
         '--runbook', 'PR Check',
         '--environment', 'Sync',
         '--variable', 'Webhook.Pr.Body:' + json.dumps(body)])

    print(stdout)
    print(stderr)


run(host='0.0.0.0', port=4000)
