
variable "region" {
  type        = string
  description = "Region to launch vpc"
  default     = "us.east.1"
}
variable "cidr" {
  type        = string
  description = "The CIDR of the VPC."
}

variable "public_subnet" {
  type        = string
  description = "The public subnet to create."
}
variable "private_subnet" {
  type        = string
  description = "The public subnet to create."
}

variable "public1_subnet" {
  type        = string
  description = "The public subnet to create."
}
variable "private1_subnet" {
  type        = string
  description = "The public subnet to create."
}

/*variable "instance_count" {
    type = number
    description = "number of instances to launch"
}*/
variable "instance_type" {
  type        = string
  description = "The type of instance to launch"
}
variable "key_name" {
  type        = string
  description = "Key used to connect to instance generated"
}
variable "ssh_port" {
  description = "The port the EC2 Instance should listen on for SSH requests."
  type        = number
  default     = 22
}

variable "ssh_user" {
  description = "SSH user name to use for remote exec connections,"
  type        = string
  default     = "ubuntu"
}

variable "secret_key" {
  type        = string
  description = "secret key of user provisioning infrastructure"
}

variable "access_key" {
  type        = string
  description = "access key of user rivisioning infrastructure"
}
