provider "aws" {
  region = "ap-south-1"
  # Credentials will be provided through environment variables or Jenkins credentials
}

# Data source for default VPC
data "aws_vpc" "default" {
  default = true
}

# Data source for default public subnets
data "aws_subnets" "public" {
  vpc_id = data.aws_vpc.default.id
}

# Data source for default security group
data "aws_security_group" "default" {
  vpc_id = data.aws_vpc.default.id
}

# S3 bucket for Kops state management
resource "aws_s3_bucket" "kops_state" {
  bucket = "my-kops-state-bucket" # Ensure this is globally unique
}

# Enable versioning for the S3 bucket
resource "aws_s3_bucket_versioning" "kops_state" {
  bucket = aws_s3_bucket.kops_state.id
  versioning_configuration {
    status = "disabled"
  }
}

# S3 bucket for Load Balancer logs
resource "aws_s3_bucket" "lb_logs" {
  bucket = "my-lb-logs-bucket" # Ensure this is globally unique
}

# Enable versioning for the S3 bucket used for load balancer logs
resource "aws_s3_bucket_versioning" "lb_logs" {
  bucket = aws_s3_bucket.lb_logs.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Application Load Balancer
resource "aws_lb" "test" {
  name               = "test-lb-tf"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [data.aws_security_group.default.id]
  subnets            = data.aws_subnets.public.ids

  enable_deletion_protection = false

  access_logs {
    bucket  = aws_s3_bucket.lb_logs.id
    prefix  = "test-lb"
    enabled = true
  }

  tags = {
    Environment = "production"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.test.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "Hello, World!"
      status_code  = "200"
    }
  }
}

output "s3_bucket" {
  value = aws_s3_bucket.kops_state.bucket
}

output "lb_logs_bucket" {
  value = aws_s3_bucket.lb_logs.bucket
}

output "elb_dns_name" {
  value = aws_lb.test.dns_name
}
