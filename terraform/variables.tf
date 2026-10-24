variable "aws_region" {
  description = "AWS region for deployment"
  default     = "ap-south-1"
}

variable "project_name" {
  description = "Name of the project"
  default     = "devops-assignment"
}

variable "app_port" {
  description = "Port exposed by the Nginx reverse proxy"
  default     = 80
}

variable "image_base_identity" {
  description = "Base identity for the Docker images"
  default     = "<YOUR_DOCKERHUB_USERNAME/YOUR_ECR_URL>"
}