#!/usr/bin/env python
#
# Copyright (C) 2020 Erlend Ekern <dev@ekern.me>
#
# Distributed under terms of the MIT license.

"""

"""
import boto3
from datetime import datetime
import json
import logging
import os
import urllib.request
import urllib.parse

logger = logging.getLogger(__name__)
logger.setLevel(logging.DEBUG)


def lambda_handler(event, context):
    logger.debug("Lambda triggered with input data '%s'", json.dumps(event))
    api_url = os.environ["API_URL"]
    slack_webhook_url = os.environ["SLACK_WEBHOOK_URL"]
    logger.debug("Enviroment variable 'API_URL' = '%s'", api_url)
    params = {
        "execution_name": event["execution_id"].split(":")[7],
        "token": event["token"],
        "state_machine_name": event["state_machine_id"].split(":")[6],
    }

    link = f"{api_url}?{urllib.parse.urlencode(params)}"
    approve_link = f"{link}&action=approve"
    reject_link = f"{link}&action=reject"
    logger.debug("Created approve link '%s'", approve_link)
    logger.debug("Created reject link '%s'", reject_link)
    messages = []
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    messages = [
        f"*Execution:* {params['execution_name']}",
        f"*Time:* {timestamp}",
        f"*Status:* {event['state_name']}",
    ]
    content = json.dumps(
        {
            "attachments": [
                {
                    "title": params["state_machine_name"],
                    "text": "\n".join(messages),
                    "mrkdwn_in": ["text"],
                    "fallback": "",
                    "actions": [
                        {
                            "type": "button",
                            "name": "approve",
                            "text": "Approve",
                            "url": approve_link,
                            "style": "primary",
                        },
                        {
                            "type": "button",
                            "name": "reject",
                            "text": "Reject",
                            "url": reject_link,
                        },
                    ],
                }
            ],
        }
    )
    logger.debug("Sending message to Slack '%s'", content)

    slack_request = urllib.request.Request(
        slack_webhook_url,
        data=content.encode("utf-8"),
        headers={"Content-Type": "application/json"},
    )
    slack_response = urllib.request.urlopen(slack_request)

    return
