data "aws_iam_policy_document" "ec2_service_trust" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "pubsys_identity" {
  statement {
    effect = "Allow"

    actions = [
      "ebs:StartSnapshot",
      "ebs:CompleteSnapshot",
      "ebs:PutSnapshotBlock",
      "ec2:CreateSnapshot",
      "ec2:RegisterImage",
      "ec2:DescribeImages",
      "ec2:DescribeImageAttribute",
      "ec2:DescribeSnapshotAttribute",
      "ec2:DescribeSnapshots",
    ]

    resources = ["*"]
  }
}
