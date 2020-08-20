data "aws_caller_identity" "current-account" {}
data "aws_region" "current" {}

locals {
  current_account_id = data.aws_caller_identity.current-account.account_id
  current_region     = data.aws_region.current.name
}

data "archive_file" "receiver" {
  type        = "zip"
  source_file = "${path.module}/src/receiver.py"
  output_path = "${path.module}/src/receiver.zip"
}

data "archive_file" "dispatcher" {
  type        = "zip"
  source_file = "${path.module}/src/dispatcher.py"
  output_path = "${path.module}/src/dispatcher.zip"
}

resource "aws_lambda_function" "receiver" {
  function_name    = "${var.name_prefix}-pipeline-approval-receiver"
  handler          = "receiver.lambda_handler"
  role             = aws_iam_role.receiver.arn
  runtime          = "python3.7"
  filename         = data.archive_file.receiver.output_path
  source_code_hash = filebase64sha256(data.archive_file.receiver.output_path)
  environment {
    variables = {
      WAIT_FOR_PREVIOUS_EXECUTIONS = var.wait_for_previous_executions
      SLACK_WEBHOOK_URL            = jsonencode(var.slack_webhook_url)
    }
  }
  timeout = var.lambda_timeout
  tags    = var.tags
}

resource "aws_lambda_function" "dispatcher" {
  function_name    = "${var.name_prefix}-pipeline-approval-dispatcher"
  handler          = "dispatcher.lambda_handler"
  role             = aws_iam_role.dispatcher.arn
  runtime          = "python3.7"
  filename         = data.archive_file.dispatcher.output_path
  source_code_hash = filebase64sha256(data.archive_file.dispatcher.output_path)
  environment {
    variables = {
      API_URL           = "${aws_api_gateway_deployment.this.invoke_url}${aws_api_gateway_resource.this.path}"
      SLACK_WEBHOOK_URL = var.slack_webhook_url
    }
  }
  timeout = var.lambda_timeout
  tags    = var.tags
}

resource "aws_iam_role" "dispatcher" {
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
  tags               = var.tags
}

resource "aws_iam_role_policy" "logs_to_dispatcher" {
  policy = data.aws_iam_policy_document.logs_for_lambda.json
  role   = aws_iam_role.dispatcher.id
}

resource "aws_iam_role" "receiver" {
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
  tags               = var.tags
}

resource "aws_iam_role_policy" "logs_to_receiver" {
  policy = data.aws_iam_policy_document.logs_for_lambda.json
  role   = aws_iam_role.receiver.id
}

resource "aws_iam_role_policy" "task_status_to_receiver" {
  policy = data.aws_iam_policy_document.task_status_for_lambda.json
  role   = aws_iam_role.receiver.id
}


##################################
#                                #
# API Gateway                    #
#                                #
##################################
resource "aws_api_gateway_rest_api" "this" {
  name        = "${var.name_prefix}-pipeline-receiver"
  description = "An API that facilitates sending task success / failure to a task in a Step Function state machine"
}

resource "aws_api_gateway_resource" "this" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  parent_id   = aws_api_gateway_rest_api.this.root_resource_id
  path_part   = "run"
}

resource "aws_api_gateway_method" "this" {
  rest_api_id   = aws_api_gateway_rest_api.this.id
  resource_id   = aws_api_gateway_resource.this.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "this" {
  rest_api_id             = aws_api_gateway_rest_api.this.id
  resource_id             = aws_api_gateway_resource.this.id
  http_method             = aws_api_gateway_method.this.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.receiver.invoke_arn
}

resource "aws_api_gateway_deployment" "this" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  stage_name  = "default"
  depends_on  = [aws_api_gateway_integration.this]
}

resource "aws_lambda_permission" "this" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.receiver.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "arn:aws:execute-api:${local.current_region}:${local.current_account_id}:${aws_api_gateway_rest_api.this.id}/*"
}
