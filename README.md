# sftp
Final Notes:
Internal Endpoint: The AWS Transfer Family server is set up with an internal endpoint, which means the traffic will flow through the ALB to the internal AWS Transfer Family endpoint.
ALB Configuration: The ALB is configured to forward incoming traffic on port 22 (SFTP) to the internal AWS Transfer Family server.
DNS Configuration: The Route 53 DNS record is set up to resolve to the public ALB DNS name.
Security Group: The ALB security group allows incoming traffic on port 22 (SFTP), and you can customize this further based on security requirements.
IAM Policies: An IAM role and policy are set up to define which users or services can interact with the AWS Transfer Family server.
