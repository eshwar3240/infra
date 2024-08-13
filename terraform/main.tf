provider "aws" {
  region = "ap-south-1"  # Specify your desired AWS region
}

# Data source for default VPC
data "aws_vpc" "eshwar1000_default" {
  default = true
}

# Data source for public subnets
data "aws_subnets" "eshwar1000_public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.eshwar1000_default.id]
  }
}

# Data source for default security group
data "aws_security_group" "eshwar1000_default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.eshwar1000_default.id]
  }
}

# S3 bucket for Kops state management
resource "aws_s3_bucket" "eshwar1000_kops_state" {
  bucket = "eshwar1000-kops-state-bucket"  # Ensure this is globally unique
}

# Enable versioning for the S3 bucket
resource "aws_s3_bucket_versioning" "eshwar1000_kops_state_versioning" {
  bucket = aws_s3_bucket.eshwar1000_kops_state.id
  versioning_configuration {
    status = "Disabled"
  }
}

# S3 bucket for Load Balancer logs
resource "aws_s3_bucket" "eshwar1000_lb_logs" {
  bucket = "eshwar1000-lb-logs-bucket"  # Ensure this is globally unique
}

# Enable versioning for the S3 bucket used for load balancer logs
resource "aws_s3_bucket_versioning" "eshwar1000_lb_logs_versioning" {
  bucket = aws_s3_bucket.eshwar1000_lb_logs.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Application Load Balancer
resource "aws_lb" "eshwar1000_test_lb" {
  name               = "eshwar1000-test-lb-tf"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [data.aws_security_group.eshwar1000_default.id]
  subnets            = data.aws_subnets.eshwar1000_public.ids

  enable_deletion_protection = false

  access_logs {
    bucket  = aws_s3_bucket.eshwar1000_lb_logs.id
    prefix  = "eshwar1000-test-lb"
    enabled = true
  }

  tags = {
    Environment = "production"
  }
}

# Load Balancer Listener
resource "aws_lb_listener" "eshwar1000_http_listener" {
  load_balancer_arn = aws_lb.eshwar1000_test_lb.arn
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

# Outputs
output "s3_bucket" {
  value = aws_s3_bucket.eshwar1000_kops_state.bucket
}

output "lb_logs_bucket" {
  value = aws_s3_bucket.eshwar1000_lb_logs.bucket
}

output "elb_dns_name" {
  value = aws_lb.eshwar1000_test_lb.dns_name
}
}
