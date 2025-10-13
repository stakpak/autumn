#!/bin/bash
set -e

# Log file
LOG_FILE="/var/log/stakpak-setup.log"
exec > >(tee -a $LOG_FILE) 2>&1

echo "=== Starting Stakpak deployment at $(date) ==="

# Update system
echo "Updating system packages..."
apt-get update -y
DEBIAN_FRONTEND=noninteractive apt-get upgrade -y

# Install Caddy
echo "Installing Caddy..."
apt-get install -y debian-keyring debian-archive-keyring apt-transport-https curl
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | tee /etc/apt/sources.list.d/caddy-stable.list
apt-get update -y
apt-get install -y caddy

# Create Caddyfile
echo "Configuring Caddy reverse proxy..."
cat > /etc/caddy/Caddyfile <<'CADDYFILE'
finance.stakpak.dev {
    reverse_proxy localhost:3000
}

api-finance.stakpak.dev {
    reverse_proxy localhost:8080
}
CADDYFILE

# Enable and start Caddy
systemctl enable caddy
systemctl start caddy
echo "✅ Caddy configured and started"

# Install Docker
echo "Installing Docker..."
apt-get install -y ca-certificates curl
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
systemctl enable docker
systemctl start docker

# Wait for Docker to be fully ready
echo "Waiting for Docker to be ready..."
sleep 5
until docker info > /dev/null 2>&1; do
  echo "Waiting for Docker daemon..."
  sleep 2
done

# Add ubuntu user to docker group for permission
echo "Adding ubuntu user to docker group..."
usermod -aG docker ubuntu
echo "✅ Docker installed and started"
echo "✅ Ubuntu user added to docker group"

# Docker Compose is already installed as docker-compose-plugin
echo "✅ Docker Compose installed (via plugin)"

# Install required packages for Bun
echo "Installing required packages..."
apt-get install -y unzip git
echo "✅ Required packages installed"

# Install Bun for ubuntu user
echo "Installing Bun for ubuntu user..."
sudo -u ubuntu bash -c 'curl -fsSL https://bun.sh/install | bash'

# Fix bun binary permissions
chmod +x /home/ubuntu/.bun/bin/bun
echo "✅ Bun installed for ubuntu user"

# Clone Stakpak Autumn repository to ubuntu home
echo "Cloning Stakpak Autumn repository..."
cd /home/ubuntu
sudo -u ubuntu git clone https://github.com/stakpak/autumn.git autumn
cd /home/ubuntu/autumn
echo "✅ Repository cloned to /home/ubuntu/autumn"

# Install dependencies as ubuntu user
echo "Installing project dependencies..."
sudo -u ubuntu bash -c 'cd /home/ubuntu/autumn && /home/ubuntu/.bun/bin/bun install'
echo "✅ Dependencies installed"

echo "=== Stakpak deployment completed at $(date) ==="
echo ""
echo "📦 Repository cloned to: /home/ubuntu/autumn"
echo "📝 To complete setup, SSH into the instance and run:"
echo "   cd /home/ubuntu/autumn"
echo "   ~/.bun/bin/bun setup"
echo "   ~/.bun/bin/bun db:generate && ~/.bun/bin/bun db:migrate"
echo "   docker compose -f docker-compose.stakpak.yml up -d"
echo "   docker compose -f docker-compose.stakpak.yml ps"
echo ""
echo "🌐 Dashboard will be available at: https://finance.stakpak.dev"
echo "🌐 API will be available at: https://api-finance.stakpak.dev"
