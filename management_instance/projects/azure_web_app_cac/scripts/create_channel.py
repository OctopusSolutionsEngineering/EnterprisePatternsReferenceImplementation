import logging
import os
import re
# Import WebClient from Python SDK (github.com/slackapi/python-slack-sdk)
from slack_sdk import WebClient
from slack_sdk.errors import SlackApiError

# WebClient instantiates a client that can call API methods
# When using Bolt, you can use either `app.client` or the `client` passed to listeners.

client = WebClient(token=get_octopusvariable("Slack.Bot.Token"))
logger = logging.getLogger(__name__)

name = "incident-" + re.sub('[^A-Za-z0-9]', '-',  get_octopusvariable("Octopus.Space.Name").lower() + "-" + get_octopusvariable("Octopus.Project.Name").lower())

try:
    # Call the conversations.create method using the WebClient
    # conversations_create requires the channels:manage bot scope
    logger.info("Creating channel called " + name)
    result = client.conversations_create(
        # The name of the conversation
        name=name
    )
    # Log the result which includes information like the ID of the conversation
    logger.info(result)

except SlackApiError as e:
    if e.response.data['error'] != 'name_taken':
        logger.error("Error creating conversation: {}".format(e))
        raise e

try:
    result = client.conversations_list()
    logger.info(result)

    id = [x for x in result.data['channels'] if x['name'] == name][0]['id']
    logger.info("Channel ID: " + id)

    users = get_octopusvariable("Slack.Support.Users")

    if users != "":
        result = client.conversations_invite(channel=id, users=users)
        logger.info(result)

except SlackApiError as e:
    if e.response.data['error'] != 'already_in_channel':
        logger.error("Error creating conversation: {}".format(e))
        raise e

print('Incident channel created')
