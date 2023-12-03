variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-southeast-2"
}

variable "website_bucket" {
  description = "S3 bucket name"
  type        = string
  default     = "techscrum-dev"

  validation {
    condition = length(var.website_bucket) > 2 && length(var.website_bucket) < 64 && can(regex("^[0-9A-Za-z-]+$", var.website_bucket))
    error_message = "The bucket_name must follow naming rules. Check them out at: https://docs.aws.amazon.com/AmazonS3/latest/userguide/bucketnamingrules.html."
  }
}

variable "log_bucket" {
  description = "S3 bucket name for access logging storage"
  type        = string
  default     = "techscrum-dev-access-log"
}

variable "domain_name" {
  type        = string
  description = "The domain name to use"
  default     = "dev.techscrumjr11.com"
}
