data "aws_iam_policy_document" "lambda_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      identifiers = ["lambda.amazonaws.com"]
      type        = "Service"
    }
  }
}

data "aws_iam_policy_document" "logs_for_lambda" {
  statement {
    effect    = "Allow"
    actions   = ["logs:CreateLogGroup"]
    resources = ["arn:aws:logs:${local.current_region}:${local.current_account_id}:*"]
  }
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = [
      "arn:aws:logs:${local.current_region}:${local.current_account_id}:log-group:/aws/lambda/${aws_lambda_function.receiver.function_name}*",
      "arn:aws:logs:${local.current_region}:${local.current_account_id}:log-group:/aws/lambda/${aws_lambda_function.dispatcher.function_name}*"
    ]
  }
}

data "aws_iam_policy_document" "sfn_for_lambda" {
  statement {
    effect = "Allow"
    actions = [
      "states:ListExecutions",
      "states:SendTaskSuccess",
      "states:SendTaskFailure"
    ]
    resources = var.state_machine_arns
  }
}
