resource "aws_security_group" "this" {
  vpc_id = data.terraform_remote_state.vpc.outputs.vpc_id
}

# we should never do the following (`all_tcp`, `all_udp`) under normal
# circumstances.
#
# we are opening up non-privileged port so that we can do
# `wormhole-rs tx --force-redirect`.

resource "aws_vpc_security_group_ingress_rule" "all_tcp" {
  security_group_id = aws_security_group.this.id

  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 1024
  to_port     = 65535
  ip_protocol = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "all_udp" {
  security_group_id = aws_security_group.this.id

  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 1024
  to_port     = 65535
  ip_protocol = "udp"
}

resource "aws_vpc_security_group_egress_rule" "all" {
  security_group_id = aws_security_group.this.id

  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "-1"
}

resource "aws_instance" "this" {
  ami = data.aws_ami.amzn_linux_2023_latest.image_id
  # instance types that you can use here are
  # - "t3.micro"
  # - "c6i.4xlarge"
  # - "c6a.4xlarge"
  # - "c6a.2xlarge"
  #
  # https://aws.amazon.com/ec2/spot/instance-advisor/
  instance_type               = "c6a.4xlarge"
  associate_public_ip_address = true
  subnet_id                   = data.terraform_remote_state.vpc.outputs.public_subnet_ids[0]
  vpc_security_group_ids      = [aws_security_group.this.id]
  user_data_base64            = filebase64("user_data.sh")
  iam_instance_profile        = data.terraform_remote_state.iam.outputs.ec2_instance_pubsys_iam_instance_profile_name

  root_block_device {
    volume_size = 64
  }

  instance_market_options {
    market_type = "spot"
  }
}