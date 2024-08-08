provider "aws" {
  region = "ap-south-1"
  # Credentials will be provided through environment variables or Jenkins credentials
}

# Data source for default VPC
data "aws_vpc" "default" {
  default = true
}

# Data source for default subnets
data "aws_subnet_ids" "default" {
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
    status = "Enabled"
  }
}

# Application Load Balancer
resource "aws_lb" "example" {
  name               = "example-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [data.aws_security_group.default.id]
  subnets            = data.aws_subnet_ids.default.ids

  enable_deletion_protection = false
  idle_timeout               = 60
  drop_invalid_header_fields = true
  enable_http2               = true

  tags = {
    Name = "example-lb"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.example.arn
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

output "elb_dns_name" {
  value = aws_lb.example.dns_name
}
