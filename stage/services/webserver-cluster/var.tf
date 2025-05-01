# services/webserver-cluster/var.tf
variable "server_port" {
  description = "The port server will use for http requests"
  type        = number
  default     = 80
}
