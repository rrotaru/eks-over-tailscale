#!/bin/sh
# User data setup for EC2 helper instance

# Update all packages
dnf update -y

# Download kubectl and set up kubeconfig
curl -o /usr/bin/kubectl https://s3.us-west-2.amazonaws.com/amazon-eks/1.29.0/2024-01-04/bin/linux/amd64/kubectl
chmod +x /usr/bin/kubectl

# Download and install helm
curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | sh

# Set up aws cli and kube config
mkdir ~/.aws
cat <<EOF > ~/.aws/config
[profile ssm]
sso_session = ssm
sso_account_id = ${aws_account}
sso_role_name = AdministratorAccess
region = ${aws_region}
output = yaml
[sso-session ssm]
sso_start_url = ${aws_sso_login_url}
sso_region = ${aws_region}
sso_registration_scopes = sso:account:access
EOF
