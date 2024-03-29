variable "prefix" {
  description = "A name which will be pre-pended to the resources created"
  type        = string
}

variable "name" {
  description = "A name which will be pre-pended to the resources created"
  type        = string
}

variable "subnet_ids" {
  description = "The list of subnets to deploy the Iglu Server across"
  type        = list(string)
}

variable "ssh_key_name" {
  description = "The name of the SSH key-pair to attach to all EC2 nodes deployed"
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

variable "tags" {
  description = "The tags to append to this resource"
  default     = {}
  type        = map(string)
}


# --- Configuration options

variable "db_sg_id" {
  description = "The ID of the RDS security group that sits downstream of the webserver"
  type        = string
}

variable "db_host" {
  description = "The hostname of the database to connect to"
  type        = string
}

variable "db_port" {
  description = "The port the database is running on"
  type        = number
}

variable "db_name" {
  description = "The name of the database to connect to"
  type        = string
}

variable "db_username" {
  description = "The username to use to connect to the database"
  type        = string
}

variable "db_password" {
  description = "The password to use to connect to the database"
  type        = string
  sensitive   = true
}

variable "super_api_key" {
  description = "A UUIDv4 string to use as the master API key for Iglu Server management"
  type        = string
  sensitive   = true
}