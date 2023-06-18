#!/usr/bin/env python3

# GitHub apps are the preferred solution for machine-to-github interaction:
# https://docs.github.com/en/apps/oauth-apps/building-oauth-apps/differences-between-github-apps-and-oauth-apps#machine-vs-bot-accounts
# Unfortunately, GitHub apps are a pain to use with regular git tooling, as they only generate tokens that live for 1
# hour. This script regenerates the token and updates any Octopus git credentials to ensure they are always available.
# This script needs to be triggers every 30 mins to ensure all spaces have valid tokens.

import jwt
import time
import urllib.request
import os
import json

# If this script is not being run as part of an Octopus step, return variables from environment variables.
if "get_octopusvariable" not in globals():
    def get_octopusvariable(variable):
        if variable == 'GitHub.App.PrivateKey':
            return os.environ['GITHUB_APP_PRIVATEKEY']
        if variable == 'GitHub.App.Id':
            return os.environ['GITHUB_APP_ID']
        if variable == 'GitHub.App.InstallationId':
            return os.environ['GITHUB_APP_INSTALLATIONID']
        if variable == 'Global.Octopus.ApiKey':
            return os.environ['GLOBAL_OCTOPUS_APIKEY']
        if variable == 'Octopus.GitHubAppCreds.Name':
            return os.environ['OCTOPUS_GITHUBAPPCREDS_NAME']

        return ""

# If this script is not being run as part of an Octopus step, print directly to std out.
if "printverbose" not in globals():
    def printverbose(msg):
        print(msg)

app_id = get_octopusvariable('GitHub.App.Id')
signing_key = jwt.jwk_from_pem(get_octopusvariable('GitHub.App.PrivateKey'))

payload = {
    # Issued at time
    'iat': int(time.time()),
    # JWT expiration time (10 minutes maximum)
    'exp': int(time.time()) + 600,
    # GitHub App's identifier
    'iss': app_id
}

# Create JWT
jwt_instance = jwt.JWT()
encoded_jwt = jwt_instance.encode(payload, signing_key, alg='RS256')

# Create access token
url = "https://api.github.com/app/installations/" + get_octopusvariable('GitHub.App.InstallationId') + "/access_tokens"
headers = {
    'Authorization': 'Bearer ' + encoded_jwt,
    'Accept': 'application/vnd.github+json',
    'X-GitHub-Api-Version': '2022-11-28'
}
request = urllib.request.Request(url, headers=headers)
response = urllib.request.urlopen(request)
response_json = json.loads(response.read().decode())
token = response_json['token']

# Update git credentials

url = 'http://octopus:8080/api/Spaces'
headers = {
    "X-Octopus-ApiKey": get_octopusvariable('Global.Octopus.ApiKey'),
    'Accept': 'application/json'
}
request = urllib.request.Request(url, headers=headers)
response = urllib.request.urlopen(request)
spaces_json = json.loads(response.read().decode())

for space in spaces_json['Items']:
    space_id = space['Id']

    url = 'http://octopus:8080/api/' + space_id + '/Git-Credentials'
    headers = {
        "X-Octopus-ApiKey": get_octopusvariable('Global.Octopus.ApiKey'),
        'Accept': 'application/json'
    }
    request = urllib.request.Request(url, headers=headers)
    response = urllib.request.urlopen(request)
    git_creds_json = json.loads(response.read().decode())

    for git_cred in git_creds_json['Items']:
        if git_cred['Name'] == get_octopusvariable('Octopus.GitHubAppCreds.Name'):
            url = 'http://octopus:8080/api/' + space_id + '/Git-Credentials/' + git_cred['Id']
            headers = {
                "X-Octopus-ApiKey": get_octopusvariable('Global.Octopus.ApiKey'),
                'Accept': 'application/json'
            }
            body = {
                'Details': {
                    'Password': {
                        'HasValue': True,
                        'NewValue': token
                    },
                    'Type': 'UsernamePassword',
                    'Username': 'x-access-token'
                }
            }
            request = urllib.request.Request(url, headers=headers, data=json.dumps(body).encode("utf-8"), method='PUT')
            response = urllib.request.urlopen(request)
            if not response.getcode() == 200:
                print("Failed to update git creds in space " + space['Name'])
