# it looks like you cannot directly see instance profiles in AWS
# console.
#
# here are two commands that you can use.
#
# ```
# aws iam list-instance-profiles --profile <PROFILE>
#
# aws iam get-instance-profile --instance-profile-name <INSTANCE_PROFILE_NAME> --profile <PROFILE>
# ```

output "ec2_instance_iam_instance_profile_name" {
  description = "The name of the ec2_instance IAM instance profile"
  value       = aws_iam_instance_profile.ec2_instance.name
}

output "ec2_instance_pubsys_iam_instance_profile_name" {
  description = "The name of the ec2_instance_pubsys IAM instance profile"
  value       = aws_iam_instance_profile.ec2_instance_pubsys.name
}