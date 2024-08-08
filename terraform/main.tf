provider "aws" {
  region = "ap-south-1"
  # Credentials will be provided through environment variables or Jenkins credentials
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

# Load Balancer
resource "aws_elb" "example" {
  name               = "example-lb"
  availability_zones = ["ap-south-1a", "ap-south-1b"]
  
  listener {
    instance_port     = 80
    instance_protocol = "HTTP"
    lb_port           = 80
    protocol          = "HTTP"
  }
  
  health_check {
    target              = "TCP:80"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
  
  tags = {
    Name = "example-lb"
  }
}

output "s3_bucket" {
  value = aws_s3_bucket.kops_state.bucket
}

output "elb_dns_name" {
  value = aws_elb.example.dns_name
}
