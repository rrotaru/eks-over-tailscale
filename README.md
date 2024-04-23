# EKS + Tailscale using Terraform

This repo provisions an EKS cluster and all required infrastructure + configuration to connect it to your tailnet.

## AWS infrastructure

This repository will create the following resources via Terraform:

- Networking (VPC with private subnets)
- EKS Cluster and node groups
- EC2 Helper instance for using helm and kubectl to set up the tailscale operator
- IAM
- Security groups

### Configure `kubectl` on the EC2 helper instance via SSM

You should be able to connect to your `k8s-helper-instance` EC2 via SSM. Once you are connected, you will need an AWS SSO session in order to create your kubeconfig file and auth to your EKS cluster using OIDC. Run the following on the EC2 instance:

```sh
# Login via SSO on the EC2 instance. Copy the 8 character XXXX-XXXX code, then click the link and enter the code.
aws sso login --profile=ssm

# Create a file in your ~/.kube/config to allow you to run kubectl and helm commands.
aws eks update-kubeconfig --name main
```

Should your tailnet-operator pod go down, this EC2 instance will serve as a fallback to connect to your EKS cluster. You may choose to terminate and re-provision it when needed to save on resources. You can destroy this instance with Terraform via:

```sh
terraform destroy --target=aws_instance.k8s_helper
```

Do not terminate this EC2 instance until you have validated that you can access your cluster via the tailnet.

## Tailnet config

This repository will create the following resources via Terraform:

- ACLs for accessing k8s (managing your Tailscale ACL via Terraform will overwrite any existing ACL)

You'll additionally need to run the following via eksctl on the EC2 helper instance (connect via ssm and follow the steps above):

```sh
#!/bin/sh

TS_OAUTH_CLIENT_ID=replaceme
TS_OAUTH_CLIENT_SECRET=replaceme

# Add tailscale helm repo and install tailscale operator chart
helm repo add tailscale https://pkgs.tailscale.com/helmcharts
helm repo update
helm upgrade \
  --install \
  tailscale-operator \
  tailscale/tailscale-operator \
  --namespace=tailscale \
  --create-namespace \
  --set-string oauth.clientId=$TS_OAUTH_CLIENT_ID \
  --set-string oauth.clientSecret=$TS_OAUTH_CLIENT_SECRET \
  --set-string apiServerProxyConfig.mode="noauth" \
  --wait
```

Add/update your kube-config with the following to enable connecting to your cluster via tailscale and authing via aws identity center.

Update the following placeholders with your values:

- `tailnet-name`: your tailnet name
- `aws-region`: e.g. us-east-2
- `eks-cluster-name`: the name of your k8s cluster
- `aws-sso-profile-name`: the name of the local sso profile to use for auth

```yaml
apiVersion: v1
clusters:
- cluster:
    server: https://tailscale-operator.<tailnet-name>.ts.net
  name: tailscale-operator.<tailnet-name>.ts.net
contexts:
- context:
    cluster: tailscale-operator.<tailnet-name>.ts.net
    user: tailscale-auth
  name: tailscale-operator.<tailnet-name>.ts.net
current-context: tailscale-operator.<tailnet-name>.ts.net
kind: Config
preferences: {}
users:
- name: tailscale-auth
  user:
    exec:
      apiVersion: client.authentication.k8s.io/v1beta1
      args:
      - --region
      - <aws-region>
      - eks
      - get-token
      - --cluster-name
      - <eks-cluster-name>
      - --output
      - json
      command: aws
      env:
      - name: AWS_PROFILE
        value: <aws-sso-profile-name>
      interactiveMode: IfAvailable
      provideClusterInfo: false
```

## Additional references

### AWS EKS

- [AWS VPC CNI plugin for k8s](https://docs.aws.amazon.com/eks/latest/userguide/cni-iam-role.html)

### Tailscale Kubernetes Operator

- [Why the hell is your Kubernetes API public?](https://leebriggs.co.uk/blog/2024/03/23/why-public-k8s-controlplane)
- [Configuration Docs](https://tailscale.com/kb/1236/kubernetes-operator#installation)
- [Helm chart repository](https://github.com/tailscale/tailscale/blob/main/cmd/k8s-operator/deploy/chart/values.yaml)