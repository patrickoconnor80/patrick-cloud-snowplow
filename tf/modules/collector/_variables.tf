variable "prefix" {
  description = "A name which will be pre-pended to the resources created"
  type        = string
}

variable "name" {
  description = "A name which will be pre-pended to the resources created"
  type        = string
}

variable "vpc_id" {
  description = "The VPC to deploy the collector within"
  type        = string
}

variable "subnet_ids" {
  description = "The list of at least two subnets in different availability zones to deploy the collector across"
  type        = list(string)
}

variable "ssh_key_name" {
  description = "The name of the preexisting SSH key-pair to attach to all EC2 nodes deployed"
  type        = string
}

variable "ssh_ip_allowlist" {
  description = "The list of CIDR ranges to allow SSH traffic from"
  type        = list(any)
  default     = ["0.0.0.0/0"]
}

variable "min_size" {
  description = "The minimum number of servers in this server-group"
  default     = 1
  type        = number
}

variable "max_size" {
  description = "The maximum number of servers in this server-group"
  default     = 2
  type        = number
}

variable "amazon_linux_2_ami_id" {
  description = "The AMI ID to use which must be based of of Amazon Linux 2; by default the latest community version is used"
  default     = ""
  type        = string
}

variable "tags" {
  description = "The tags to append to this resource"
  default     = {}
  type        = map(string)
}

variable "good_stream_name" {
  description = "The name of the good kinesis/sqs stream that the collector will insert data into"
  type        = string
}

variable "bad_stream_name" {
  description = "The name of the bad kinesis/sqs stream that the collector will insert data into"
  type        = string
}