variable "prefix" {
  description = "A name which will be pre-pended to the resources created"
  type        = string
}

variable "name" {
  description = "A name which will be pre-pended to the resources created"
  type        = string
}

variable "tags" {
  description = "The tags to append to this resource"
  default     = {}
  type        = map(string)
}

variable "get_record_iam_roles" {
  description = "Grant AWS Roles Get access to Kinesis stream"
  default     = []
  type        = list(string)
}

variable "put_record_iam_roles" {
  description = "Grant AWS Roles Put access to Kinesis stream"
  default     = []
  type        = list(string)
}

variable "alarm_action" {
  description = "Where to send the Cloudwatch Alarm actions"
  type        = string
}