# This script exists for those scenarios where the tenant space is created as part of the same process that
# attempts to populate the space. The tenant space ID variable, saved when the space is created, won't be refreshed
# in the middle of the deployment, so we query it directly.

import argparse
import json
import urllib.request
import urllib.parse
import os
import sys
import time

# If this script is not being run as part of an Octopus step, return variables from environment variables.
# Periods are replaced with underscores, and the variable name is converted to uppercase
if "get_octopusvariable" not in globals():
    def get_octopusvariable(variable):
        return os.environ[re.sub('\\.', '_', variable.upper())]

# If this script is not being run as part of an Octopus step, just print any set variable to std out.
if "set_octopusvariable" not in globals():
    def set_octopusvariable(name, variable):
        print(variable)


def get_octopusvariable_quiet(variable):
    """
    Gets an octopus variable, or an empty string if it does not exist.
    :param variable: The variable name
    :return: The variable value, or an empty string if the variable does not exist
    """
    try:
        return get_octopusvariable(variable)
    except:
        return ''


def init_argparse():
    parser = argparse.ArgumentParser(
        usage='%(prog)s [OPTION] [FILE]...',
        description='Lookup a space ID from the name'
    )
    parser.add_argument('--server-url',
                        action='store',
                        default=get_octopusvariable_quiet('ThisInstance.Server.Url') or get_octopusvariable_quiet(
                            'SpaceLookup.ThisInstance.Server.Url'),
                        help='Sets the server URL that holds the project to be serialized.')
    parser.add_argument('--api-key',
                        action='store',
                        default=get_octopusvariable_quiet('ThisInstance.Api.Key') or get_octopusvariable_quiet(
                            'SpaceLookup.ThisInstance.Api.Key'),
                        help='Sets the Octopus API key.')
    parser.add_argument('--space-name',
                        action='store',
                        default=get_octopusvariable_quiet('Lookup.Space.Name') or get_octopusvariable_quiet(
                            'SpaceLookup.Lookup.Space.Name') or get_octopusvariable_quiet('Octopus.Deployment.Tenant.Name'),
                        help='The name of the space to lookup.')


parser, _ = init_argparse()

url = parser.server_url + '/Spaces?partialName=' + urllib.parse.quote(parser.space_name)
headers = {
    'X-Octopus-ApiKey': parser.api_key,
    'Accept': 'application/json'
}
request = urllib.request.Request(url, headers=headers)

# Retry the request for up to a minute.
response = None
for x in range(12):
    response = urllib.request.urlopen(request)
    if response.getcode() == 200:
        break
    time.sleep(5)

if not response or not response.getcode() == 200:
    print('The API query failed')
    sys.exit(1)

data = json.loads(response.read().decode("utf-8"))

space = [x for x in data['Items'] if x['Name'] == parser.space_name]

if len(space) != 0:
    print('Matched tenant name to space')
    set_octopusvariable("SpaceID", space[0]['Id'])
else:
    print('Failed to match tenant name to space')
    sys.exit(1)
