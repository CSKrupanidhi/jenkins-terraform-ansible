variable "aws_region" {
  description = "AWS deployment region"
  type        = string
  default     = "ap-southeast-2"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "environment" {
  description = "deployment environment"
  type        = string
  default     = "development"
}

variable "admin_cidr" {
  description = "public ip address for ssh access"
  type        = string

  validation {
    condition     = can(cidrnetmask(var.admin_cidr))
    error_message = "provide a valid CIDR block ,such as 203.0.113.10/32."
  }
}

variable "public_key_path" {
  description = "Path to SSH public key"
  type        = string

  default = "~/.ssh/jenkins-terraform-ansible.pub"
}


