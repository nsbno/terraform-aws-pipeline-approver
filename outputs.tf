output "function_name" {
  description = "The name of the dispatcher Lambda function."
  value       = aws_lambda_function.dispatcher.id
}

output "lambda_exec_role_id" {
  description = "The name of the execution role given to the dispatcher lambda."
  value       = aws_iam_role.dispatcher.id
}
