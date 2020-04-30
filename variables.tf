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

variable "slack_webhook_url" {
  description = "The URL of a Slack webhook to post messages to."
  type        = string
}
