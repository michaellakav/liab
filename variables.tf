data "aws_availability_zones" "available" {}
variable "aws_region" {
    default = "us-west-2"
}
variable "UntrustCIDR_Block" {}
variable "TrustCIDR_Block" {}
variable "VPCName" {}
variable "VPCCIDR" {}
variable "StackName" {}

variable "AppCIDR_Block" {}
variable "MGMTCIDR_Block" {}