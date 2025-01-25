# IAM Role for Transfer Family Access
resource "aws_iam_role" "transfer_role" {
  name = "transfer-family-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = {
          Service = "transfer.amazonaws.com"
        }
      },
    ]
  })
}

# IAM Policy for Transfer Family Permissions
resource "aws_iam_policy" "transfer_policy" {
  name        = "transfer-policy"
  description = "Policy to access SFTP server"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = "transfer:ListFiles"
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action   = "transfer:GetFile"
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action   = "transfer:PutFile"
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

# Attach the policy to the role
resource "aws_iam_role_policy_attachment" "transfer_policy_attachment" {
  policy_arn = aws_iam_policy.transfer_policy.arn
  role       = aws_iam_role.transfer_role.name
}
