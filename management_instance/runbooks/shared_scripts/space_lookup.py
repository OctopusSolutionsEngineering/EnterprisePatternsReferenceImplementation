# This script exists for those scenarios where the tenant space is created as part of the same process that
# attempts to populate the space. The tenant space ID variable, saved when the space is created, won't be refreshed
# in the middle of the deployment, so we query it directly.

import json
import urllib.request

if "get_octopusvariable" not in globals():
    print("Script must be run as an Octopus step")
    sys.exit(1)


url = 'http://octopus:8080/api/Spaces'
headers = {
    "X-Octopus-ApiKey": "API-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA",
    'Accept': 'application/json'
}
request = urllib.request.Request(url, headers=headers)
response = urllib.request.urlopen(request)
data = json.loads(response.read().decode("utf-8"))

space = [x for x in data['Items'] if x['Name'] == get_octopusvariable('Octopus.Deployment.Tenant.Name')]

if len(space) != 0:
    print('Matched tenant name to space')
    set_octopusvariable("SpaceID", space[0]['Id'])
else:
    print('Failed to match tenant name to space')
    sys.exit(1)
