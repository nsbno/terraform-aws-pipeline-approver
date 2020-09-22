variable "name_prefix" {
  description = "A prefix used for naming resources."
  type        = string
}

variable "tags" {
  description = "A map of tags (key-value pairs) passed to resources."
  type        = map(string)
  default     = {}
}

variable "state_machine_arns" {
  description = "A list of ARNs of state machines that the Lambda can send task success / failure to."
  type        = list(string)
}

variable "wait_for_previous_executions" {
  description = "Whether to allow for task approval/rejection if there are previous executions still running."
  default     = true
}

variable "slack_webhook_url" {
  description = "The URL of a Slack webhook to post messages to."
  type        = string
}

variable "lambda_timeout" {
  description = "The maximum number of seconds the Lambda functions are allowed to run."
  default     = 30
}
