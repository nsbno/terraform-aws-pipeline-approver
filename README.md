# terraform-aws-pipeline-approver
A Terraform module that exposes a Lambda function that can be used inside a Step Function to wait for some kind of manual approval. The Lambda function in question creates two links: one for approval and one for rejection, reporting back task success or task failure to the Step Function, respectively.

## Example
```terraform
module "pipeline-approver" {
  source             = "github.com/nsbno/terraform-aws-pipeline-approver?ref=XXXXXXX"
  state_machine_arns = ["arn:aws:states:eu-west-1:123456789012:stateMachine:my-state-machine"]
  name_prefix        = "example"
  slack_webhook_url  = "https://hooks.slack.com/services/xxxxxxxxx/xxxxxxxxx/xxxxxxxxxxxxxxxxxxxxxxxx"
}
```

You can then use the Lambda by adding a new state to your state machine definition:
```json
"Approve/Reject": {
  "Type": "Task",
  "Resource": "arn:aws:states:::lambda:invoke.waitForTaskToken",
  "Parameters": {
    "FunctionName": "${module.pipeline-approver.function_name}",
    "Payload": {
      "state_name.$": "$$.State.Name",
      "execution_id.$": "$$.Execution.Id",
      "token.$": "$$.Task.Token",
      "state_machine_id.$": "$$.StateMachine.Id"
    }
  },
  "TimeoutSeconds": 3600,
  "Next": "Approved"
},
```
