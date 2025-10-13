# Autumn Application Infrastructure

This Terraform configuration deploys an EC2 instance with Caddy reverse proxy for the autumn application.

## Architecture

- **VPC**: 10.0.0.0/16 with DNS support enabled
- **Public Subnet**: 10.0.1.0/24 with auto-assign public IP
- **Internet Gateway**: For public internet access
- **Security Group**: Allows SSH (22), HTTP (80), HTTPS (443)
- **EC2 Instance**: t3.medium running Ubuntu 24.04 LTS
- **Caddy**: Reverse proxy with automatic HTTPS/TLS
- **Route53**: DNS records for finance.stakpak.dev and api-finance.stakpak.dev

## DNS Configuration

- `finance.stakpak.dev` → proxies to `localhost:3000`
- `api-finance.stakpak.dev` → proxies to `localhost:8080`

## Prerequisites

1. AWS credentials configured (via environment variables or `~/.aws/credentials`)
2. Terraform >= 1.5.7 installed
3. Access to Route53 zone `stakpak.dev`
4. Existing SSH key pair in AWS (default: `etch@stakpak.dev`)

## Deployment

```bash
# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Apply the configuration
terraform apply

# Get outputs
terraform output
```

The deployment will automatically:
1. Install Caddy reverse proxy with automatic HTTPS
2. Install Docker and Docker Compose
3. Install Bun runtime for ubuntu user
4. Clone the Stakpak Autumn repository to `/home/ubuntu/autumn`
5. Install project dependencies with `bun install`

**Manual steps required after deployment:**
```bash
cd /home/ubuntu/autumn
~/.bun/bin/bun setup
~/.bun/bin/bun db:generate && ~/.bun/bin/bun db:migrate
docker compose -f docker-compose.stakpak.yml up -d
```

## Configuration

You can customize the deployment by modifying `variables.tf` or passing variables:

```bash
terraform apply
```

## SSH Access

After deployment, connect to the instance using your existing SSH key:

```bash
ssh -i ~/.ssh/etch@stakpak.dev.pem ubuntu@<instance-public-ip>
```

Or use the output command:

```bash
$(terraform output -raw ssh_command)
```

## Caddy Configuration

Caddy is automatically installed and configured. The Caddyfile is located at `/etc/caddy/Caddyfile`.

To view Caddy logs:

```bash
sudo journalctl -u caddy -f
```

To reload Caddy configuration:

```bash
sudo systemctl reload caddy
```

## Monitoring Deployment

After applying, you can SSH into the instance and monitor the deployment:

```bash
# SSH into the instance
ssh -i ~/.ssh/etch@stakpak.dev.pem ubuntu@<instance-public-ip>

# View deployment logs (user-data script execution)
sudo tail -f /var/log/stakpak-setup.log

# View cloud-init logs
sudo cat /var/log/cloud-init-output.log

# Complete the setup manually
cd /home/ubuntu/autumn
~/.bun/bin/bun setup
~/.bun/bin/bun db:generate && ~/.bun/bin/bun db:migrate
docker compose -f docker-compose.stakpak.yml up -d

# Check Docker containers
docker compose -f docker-compose.stakpak.yml ps

# View container logs
docker compose -f docker-compose.stakpak.yml logs -f
```

The Stakpak dashboard will be available at `https://finance.stakpak.dev` and the API at `https://api-finance.stakpak.dev` once deployment completes.

## Security Notes

- Using existing SSH key pair `etch@stakpak.dev` - ensure it's kept secure
- Security group allows SSH from anywhere (0.0.0.0/0) - consider restricting to your IP
- Caddy handles TLS certificates automatically using Let's Encrypt
- Ubuntu user added to docker group for container management

## Cleanup

To destroy all resources:

```bash
terraform destroy
```

## Outputs

- `instance_id`: EC2 instance ID
- `instance_public_ip`: Public IP address
- `ssh_command`: Ready-to-use SSH command
- `finance_url`: https://finance.stakpak.dev
- `api_finance_url`: https://api-finance.stakpak.dev
