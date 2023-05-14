from bottle import route, run, request
import subprocess


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
def index(name):
    body = request.body.readlines()
    stdout, stderr, _ = execute(
        ['octo',
         'run-runbook',
         '--server', 'http://octopus:8080',
         '--apiKey', 'API-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA',
         'space', 'Default',
         '--project', 'PR Checks',
         '--runbook', 'PR Check',
         '--environment', 'Sync',
         '--variable', 'Webhook.Pr.Body:' + body])
    print(stdout)
    print(stderr)


run(host='localhost', port=4000)
