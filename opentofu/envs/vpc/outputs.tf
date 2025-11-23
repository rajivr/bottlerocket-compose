output "public_subnet_ids" {
  description = "The IDs of the subnet"
  value       = aws_subnet.public[*].id
}

output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.this.id
}