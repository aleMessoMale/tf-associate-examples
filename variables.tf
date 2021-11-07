variable "access_key" {
  type        = string
  description = "AWS access key"
}


variable "secret_key" {
  type        = string
  description = "AWS secret key"
}

variable "github_token" {
  type = string
  description = "GitHub token"
}


variable security_group_default_ports {
  type = list(string)
  default = [22,80,443]
}
