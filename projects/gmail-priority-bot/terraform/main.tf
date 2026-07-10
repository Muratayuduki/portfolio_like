provider "aws" {
  region = var.aws_region
}

locals {
  name_prefix = "${var.project_name}-${var.environment}"

  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

resource "aws_dynamodb_table" "classification_results" {
  name         = "${local.name_prefix}-classification-results"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "messageId"

  attribute {
    name = "messageId"
    type = "S"
  }

  tags = local.common_tags
}

resource "aws_cloudwatch_log_group" "classifier" {
  name              = "/aws/lambda/${local.name_prefix}-classifier"
  retention_in_days = 14

  tags = local.common_tags
}

resource "aws_secretsmanager_secret" "gmail_oauth" {
  name        = "${local.name_prefix}/gmail-oauth"
  description = "Gmail OAuth authorized user JSON for label-only classification."

  tags = local.common_tags
}

resource "aws_iam_role" "lambda_execution" {
  name = "${local.name_prefix}-lambda-execution"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy" "lambda_policy" {
  name = "${local.name_prefix}-lambda-policy"
  role = aws_iam_role.lambda_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "${aws_cloudwatch_log_group.classifier.arn}:*"
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:Query",
          "dynamodb:Scan"
        ]
        Resource = aws_dynamodb_table.classification_results.arn
      },
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = aws_secretsmanager_secret.gmail_oauth.arn
      }
    ]
  })
}

resource "aws_lambda_function" "classifier" {
  function_name = "${local.name_prefix}-classifier"
  role          = aws_iam_role.lambda_execution.arn
  handler       = "app.handler"
  runtime       = "python3.12"
  filename      = var.lambda_package_path
  timeout       = 60

  environment {
    variables = {
      RESULTS_TABLE_NAME    = aws_dynamodb_table.classification_results.name
      GMAIL_OAUTH_SECRET_ID = aws_secretsmanager_secret.gmail_oauth.id
      GMAIL_LOOKBACK_QUERY  = "newer_than:1d"
      GMAIL_MAX_RESULTS     = "25"
      DRY_RUN               = "true"
    }
  }

  depends_on = [
    aws_cloudwatch_log_group.classifier,
    aws_iam_role_policy.lambda_policy
  ]

  tags = local.common_tags
}

resource "aws_iam_role" "scheduler_execution" {
  name = "${local.name_prefix}-scheduler-execution"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "scheduler.amazonaws.com"
        }
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy" "scheduler_policy" {
  name = "${local.name_prefix}-scheduler-policy"
  role = aws_iam_role.scheduler_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "lambda:InvokeFunction"
        Resource = aws_lambda_function.classifier.arn
      }
    ]
  })
}

resource "aws_scheduler_schedule" "classifier" {
  name                         = "${local.name_prefix}-classifier"
  schedule_expression          = var.schedule_expression
  schedule_expression_timezone = "Asia/Tokyo"
  state                        = var.scheduler_enabled ? "ENABLED" : "DISABLED"

  flexible_time_window {
    mode = "OFF"
  }

  target {
    arn      = aws_lambda_function.classifier.arn
    role_arn = aws_iam_role.scheduler_execution.arn
  }
}
