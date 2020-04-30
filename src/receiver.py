#!/usr/bin/env python
#
# Copyright (C) 2020 Erlend Ekern <dev@ekern.me>
#
# Distributed under terms of the MIT license.

"""

"""
import boto3
import logging
import json
import os
import urllib.request
from datetime import datetime

logger = logging.getLogger(__name__)
logger.setLevel(logging.DEBUG)


def lambda_handler(event, context):
    logger.debug("Lambda triggered with input data '%s'", json.dumps(event))
    params = event.get("queryStringParameters", {})
    account_id = event["requestContext"]["accountId"]
    region = os.environ["AWS_REGION"]
    slack_webhook_url = os.environ["SLACK_WEBHOOK_URL"]
    required_params = [
        "token",
        "action",
        "execution_name",
        "state_machine_name",
    ]
    if not params or not all(param in params for param in required_params):
        logger.error("Missing one or more required parameters")
        return {
            "statusCode": 400,
            "body": json.dumps(
                {"message": "Missing one or more required parameters"}
            ),
        }

    state_machine_name = params["state_machine_name"]
    execution_name = params["execution_name"]
    state_machine_arn = f"arn:aws:states:{region}:{account_id}:stateMachine:{state_machine_name}"
    execution_arn = f"arn:aws:states:{region}:{account_id}:execution:{state_machine_name}:{execution_name}"
    redirect_url = f"https://console.aws.amazon.com/states/home?region={region}#/executions/details/{execution_arn}"

    client = boto3.client("stepfunctions")
    try:
        if params["action"] == "approve":
            client.send_task_success(
                taskToken=params["token"], output=json.dumps({})
            )

            messages = []
            timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
            messages = [
                f"*Execution:* {execution_name}",
                f"*Time:* {timestamp}",
                "*Status:* Manually approved, continuing execution",
            ]

            content = json.dumps(
                {
                    "attachments": [
                        {
                            "title": params["state_machine_name"],
                            "text": "\n".join(messages),
                            "mrkdwn_in": ["text"],
                            "fallback": "",
                        }
                    ]
                }
            )

            logger.debug("Sending message to Slack '%s'", content)

            slack_request = urllib.request.Request(
                slack_webhook_url,
                data=content.encode("utf-8"),
                headers={"Content-Type": "application/json"},
            )
            slack_response = urllib.request.urlopen(slack_request)
        else:
            client.send_task_failure(
                error="ManualRejection",
                cause="The execution was stopped because of a manual rejection.",
                taskToken=params["token"],
            )
    except client.exceptions.TaskTimedOut:
        return {
            "statusCode": 400,
            "body": json.dumps({"message": "The task has timed out"}),
        }
    except client.exceptions.InvalidToken:
        return {
            "statusCode": 400,
            "body": json.dumps({"message": "The token is invalid"}),
        }
    except client.exceptions.TaskDoesNotExist:
        return {
            "statusCode": 400,
            "body": json.dumps({"message": "The task does not exist"}),
        }

    return {"statusCode": 302, "headers": {"Location": redirect_url}}
