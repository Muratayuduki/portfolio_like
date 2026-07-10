variable "project_name" {
  description = "Project name used for AWS resource names."
  type        = string
  default     = "gmail-priority-bot"
}

variable "aws_region" {
  description = "AWS region for MVP resources."
  type        = string
  default     = "ap-northeast-1"
}

variable "environment" {
  description = "Deployment environment name."
  type        = string
  default     = "dev"
}

variable "schedule_expression" {
  description = "EventBridge Scheduler expression for the classifier Lambda."
  type        = string
  default     = "rate(30 minutes)"
}

variable "lambda_package_path" {
  description = "Path to the Lambda deployment zip. Build this before terraform apply."
  type        = string
  default     = "../../backend/dist/lambda.zip"
}

variable "scheduler_enabled" {
  description = "Whether EventBridge Scheduler should invoke the classifier. Keep false until Gmail OAuth is configured."
  type        = bool
  default     = false
}
