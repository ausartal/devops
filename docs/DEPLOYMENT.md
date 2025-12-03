# Deployment Guide

## Prerequisites

- VPS with Ubuntu 20.04+ or similar
- SSH access with sudo privileges
- Domain name (optional)

## Initial VPS Setup

### 1. Update System

```bash
sudo apt update && sudo apt upgrade -y
```

### 2. Install Node.js

```bash
# Install Node.js 18.x
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# Verify installation
node --version
npm --version
```

### 3. Install PM2

```bash
sudo npm install -g pm2

# Setup PM2 to start on boot
pm2 startup systemd
# Run the command that PM2 outputs
```

### 4. Install Git

```bash
sudo apt install git -y
```

### 5. Setup Application Directory

```bash
sudo mkdir -p /var/www/project
sudo chown -R $USER:$USER /var/www/project
cd /var/www/project
```

### 6. Clone Repository

```bash
git clone https://github.com/yourusername/ci-cd-level3.git .
```

### 7. Configure Environment

```bash
cp .env.example .env
nano .env
```

Update with production values:
```env
NODE_ENV=production
PORT=3000
HOST=0.0.0.0
LOG_LEVEL=info
LOG_DIR=logs
```

### 8. Install Dependencies

```bash
npm ci --production
```

### 9. Start Application

```bash
pm2 start ecosystem.config.js --env production
pm2 save
```

### 10. Setup Firewall

```bash
sudo ufw allow 22/tcp    # SSH
sudo ufw allow 3000/tcp  # Application port
sudo ufw enable
```

## GitHub Actions Setup

### 1. Generate SSH Key Pair

On your VPS:
```bash
ssh-keygen -t rsa -b 4096 -C "github-actions" -f ~/.ssh/github-actions
```

### 2. Add Public Key to Authorized Keys

```bash
cat ~/.ssh/github-actions.pub >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
```

### 3. Copy Private Key

```bash
cat ~/.ssh/github-actions
# Copy the entire output including BEGIN and END lines
```

### 4. Add Secrets to GitHub

Go to your repository: `Settings > Secrets and variables > Actions > New repository secret`

Add these secrets:
- **SERVER_HOST**: Your VPS IP address (e.g., `192.168.1.100`)
- **SERVER_USER**: Your SSH username (e.g., `ubuntu`)
- **SERVER_KEY**: Paste the private key from step 3
- **SERVER_PORT**: SSH port (default: `22`)

## Testing Deployment

### 1. Test SSH Connection

```bash
ssh -i ~/.ssh/github-actions username@your-vps-ip
```

### 2. Test Health Endpoint

```bash
curl http://your-vps-ip:3000/health
```

### 3. Test Deployment Script

```bash
cd /var/www/project
chmod +x scripts/deploy.sh
./scripts/deploy.sh
```

## Nginx Setup (Optional)

### 1. Install Nginx

```bash
sudo apt install nginx -y
```

### 2. Configure Nginx

```bash
sudo nano /etc/nginx/sites-available/ci-cd-app
```

Add:
```nginx
server {
    listen 80;
    server_name your-domain.com;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

### 3. Enable Site

```bash
sudo ln -s /etc/nginx/sites-available/ci-cd-app /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
```

### 4. Update Firewall

```bash
sudo ufw allow 'Nginx Full'
```

## SSL Setup with Certbot (Optional)

```bash
sudo apt install certbot python3-certbot-nginx -y
sudo certbot --nginx -d your-domain.com
```

## Monitoring

### View PM2 Logs

```bash
pm2 logs ci-cd-app
pm2 logs ci-cd-app --lines 100
```

### View PM2 Status

```bash
pm2 status
pm2 monit
```

### View Application Logs

```bash
cd /var/www/project
tail -f logs/combined.log
tail -f logs/error.log
```

## Troubleshooting

### Application Won't Start

```bash
# Check PM2 logs
pm2 logs ci-cd-app --err

# Restart application
pm2 restart ci-cd-app

# Check environment variables
pm2 env 0
```

### Deployment Fails

```bash
# Check SSH connection
ssh username@vps-ip

# Verify script permissions
ls -la scripts/deploy.sh
chmod +x scripts/deploy.sh

# Run deployment manually
cd /var/www/project
./scripts/deploy.sh
```

### Port Already in Use

```bash
# Find process
sudo lsof -i :3000

# Kill process
sudo kill -9 <PID>

# Or change port in .env
```

## Rollback

### Manual Rollback

```bash
cd /var/www/project

# View available backups
ls -la backups/

# Restore from backup
cp -r backups/YYYYMMDD_HHMMSS/* .

# Restart
pm2 restart ci-cd-app
```

### Git Rollback

```bash
cd /var/www/project
git log --oneline
git reset --hard <commit-hash>
npm ci --production
pm2 restart ci-cd-app
```

## Maintenance

### Update Dependencies

```bash
cd /var/www/project
npm update
npm audit fix
pm2 restart ci-cd-app
```

### Clean Up Old Backups

```bash
cd /var/www/project/backups
# Keep only last 10 backups
ls -t | tail -n +11 | xargs rm -rf
```

### Monitor Disk Space

```bash
df -h
du -sh /var/www/project/*
```
