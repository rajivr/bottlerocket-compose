resource "aws_security_group" "this" {
  vpc_id = data.terraform_remote_state.vpc.outputs.vpc_id
}

resource "aws_vpc_security_group_ingress_rule" "web" {
  security_group_id = aws_security_group.this.id

  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 80
  to_port     = 80
  ip_protocol = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "web_8080" {
  security_group_id = aws_security_group.this.id

  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 8080
  to_port     = 8080
  ip_protocol = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "all" {
  security_group_id = aws_security_group.this.id

  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "-1"
}

# https://aws.amazon.com/ec2/spot/instance-advisor/
resource "aws_instance" "this" {
  ami                         = "ami-xxxxxxxxxxxxxxxxx"
  instance_type               = "m7a.medium"
  associate_public_ip_address = true
  subnet_id                   = data.terraform_remote_state.vpc.outputs.public_subnet_ids[0]
  vpc_security_group_ids      = [aws_security_group.this.id]
  user_data_base64            = filebase64("user_data.toml")
  iam_instance_profile        = data.terraform_remote_state.iam.outputs.ec2_instance_iam_instance_profile_name

  instance_market_options {
    market_type = "spot"
  }
}