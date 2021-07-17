variable "aws_region" {
  default = "us-west-1"
}

variable "aws_availability_zones" {
  description = "Availability zones"
  type        = list(string)
  default     = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
}

variable "aws_account" {
  default = "804731442997"
}

variable "k8s_namespace" {
  default = "default"
}

variable "cluster_name" {
  default = "ricardo-eks"
  type    = string
}