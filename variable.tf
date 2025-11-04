variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "web_subnet_cidr" {
  default = "10.0.1.0/24"
}

variable "app_subnet_cidr" {
  default = "10.0.2.0/24"
}

variable "db_subnet_cidr" {
  default = "10.0.3.0/24"
}

variable "ami_id" {
  description = "AMI for EC2 instances"
  type        = string
  default     = "ami-0c02fb55956c7d316" # Amazon Linux 2 (for ap-south-1)
}

variable "instance_type" {
  default = "t3.micro"
}

variable "key_name" {
  description = "Existing EC2 Key Pair name"
  type        = string
  default     = "my-key"
}
