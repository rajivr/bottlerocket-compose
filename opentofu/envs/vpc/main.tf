# when creating a vpc, you need to provide either a `cidr_block` or a 
#`ipv4IpamPoolId`.
resource "aws_vpc" "this" {
  cidr_block = "10.0.0.0/16"
}

# we use `sort(data.aws_availability_zones.all_az.names)` in order to 
# overcome the reordering issues with list of AZs.
#
# *Note*: we specifically do not set `map_public_ip_on_launch`.
resource "aws_subnet" "public" {
  count = length(data.aws_availability_zones.all_az.names)

  vpc_id            = aws_vpc.this.id
  cidr_block        = "10.0.${count.index}.0/24"
  availability_zone = element(sort(data.aws_availability_zones.all_az.names), count.index)
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
}

# add a default route to `aws_internet_gateway.this` in the `main` 
# route table of `aws_vpc.this`.
#
# routes that do not match the `local` route (which takes precedence
# due to longest prefix rule) will go via `aws_internet_gateway.this`.
#
# no new route tables are being created.
resource "aws_route" "this" {
  route_table_id         = aws_vpc.this.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}
