resource "aws_iam_role" "ec2_instance" {
  assume_role_policy = data.aws_iam_policy_document.ec2_service_trust.json
}

resource "aws_iam_role_policy_attachment" "amazon_ssm_managed_instance_core_ec2_instance" {
  role       = aws_iam_role.ec2_instance.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "amazon_ec2_container_registry_read_only_ec2_instance" {
  role       = aws_iam_role.ec2_instance.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_instance_profile" "ec2_instance" {
  role = aws_iam_role.ec2_instance.name
}

# we need to add this policy to the permission set in `org-formation`.
#
# therefore we give it a name, so it can be added customer managed 
# policy of the permission set.
#
# *note:* once a policy is attached to a permission set, you cannot 
#         make changes to it till it is removed from the permission set
#         in `org-formation`.
resource "aws_iam_policy" "bottlerocket_image_developer_identity_pass_role_ec2_instance" {
  name = "bottlerocket_image_developer_identity_pass_role_ec2_instance"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"

        Action = [
          "iam:GetRole",
          "iam:PassRole",
        ]

        Resource = aws_iam_role.ec2_instance.arn
      }
    ]
  })
}

resource "aws_iam_role" "ec2_instance_pubsys" {
  assume_role_policy = data.aws_iam_policy_document.ec2_service_trust.json
}

resource "aws_iam_policy" "pubsys_identity" {
  policy = data.aws_iam_policy_document.pubsys_identity.json
}

resource "aws_iam_role_policy_attachment" "pubsys_identity_ec2_instance_pubsys" {
  role       = aws_iam_role.ec2_instance_pubsys.name
  policy_arn = aws_iam_policy.pubsys_identity.arn
}

resource "aws_iam_role_policy_attachment" "amazon_ssm_managed_instance_core_ec2_instance_pubsys" {
  role       = aws_iam_role.ec2_instance_pubsys.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2_instance_pubsys" {
  role = aws_iam_role.ec2_instance_pubsys.name
}

# we need to add this policy to the permission set in `org-formation`.
#
# therefore we give it a name, so it can be added customer managed 
# policy of the permission set.
#
# *note:* once a policy is attached to a permission set, you cannot 
#         make changes to it till it is removed from the permission set
#         in `org-formation`.
resource "aws_iam_policy" "bottlerocket_image_developer_identity_pass_role_ec2_instance_pubsys" {
  name = "bottlerocket_image_developer_identity_pass_role_ec2_instance_pubsys"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"

        Action = [
          "iam:GetRole",
          "iam:PassRole",
        ]

        Resource = aws_iam_role.ec2_instance_pubsys.arn
      }
    ]
  })
}
