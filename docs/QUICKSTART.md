# Quick Start Guide

## 🚀 Get Started in 5 Minutes

### Step 1: Clone and Install (1 min)

```bash
# Clone the repository
git clone https://github.com/ausartal/ci-cd-level3.git
cd ci-cd-level3

# Install dependencies
npm install

# Copy environment file
cp .env.example .env
```

### Step 2: Run Locally (30 sec)

```bash
# Start development server
npm run dev

# Visit http://localhost:3000
```

### Step 3: Run Tests (30 sec)

```bash
# Run all tests
npm test

# See coverage report at: coverage/lcov-report/index.html
```

### Step 4: Check Code Quality (30 sec)

```bash
# Validate everything
npm run validate
```

### Step 5: Deploy to Production (2 min)

#### Option A: Automatic (GitHub Actions)

1. **Configure GitHub Secrets:**
   - Go to: Repository → Settings → Secrets → Actions
   - Add: `SERVER_HOST`, `SERVER_USER`, `SERVER_KEY`, `SERVER_PORT`

2. **Push to main branch:**
```bash
git add .
git commit -m "feat: initial deployment"
git push origin main
```

GitHub Actions will automatically:
- ✅ Run lint checks
- ✅ Run tests on multiple Node.js versions
- ✅ Build the application
- ✅ Deploy to VPS
- ✅ Verify deployment

#### Option B: Manual VPS Deployment

1. **Setup VPS:**
```bash
# SSH into your VPS
ssh username@your-vps-ip

# Install Node.js and PM2
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs
sudo npm install -g pm2

# Clone repository
sudo mkdir -p /var/www/project
sudo chown -R $USER:$USER /var/www/project
cd /var/www/project
git clone https://github.com/yourusername/ci-cd-level3.git .
```

2. **Configure and Start:**
```bash
# Setup environment
cp .env.example .env
nano .env  # Update with production values

# Install dependencies
npm ci --production

# Start with PM2
pm2 start src/index.js --name ci-cd-app -i max
pm2 save
pm2 startup
```

---

## 📝 Common Commands

### Development
```bash
npm run dev          # Start dev server with auto-reload
npm run test:watch   # Run tests in watch mode
npm run lint:fix     # Auto-fix linting issues
npm run format       # Format all code
```

### Testing
```bash
npm test                    # Run all tests with coverage
npm run test:ci            # Run tests in CI mode
npm test -- app.test.js    # Run specific test file
```

### Production
```bash
npm start            # Start production server
npm run build        # Build the application
npm run validate     # Run all checks
```

### PM2 Management
```bash
pm2 list             # Show all processes
pm2 logs ci-cd-app   # View logs
pm2 restart ci-cd-app # Restart app
pm2 stop ci-cd-app   # Stop app
pm2 monit            # Monitor in real-time
```

---

## 🎯 Verify Installation

### Check Application
```bash
# Check if app is running
curl http://localhost:3000

# Expected response:
{
  "message": "CI/CD Level 3 - Professional Grade Application",
  "version": "1.0.0",
  "environment": "development",
  "status": "running"
}
```

### Check Health
```bash
curl http://localhost:3000/health

# Expected response:
{
  "uptime": 123.45,
  "message": "OK",
  "timestamp": 1234567890,
  "environment": "development"
}
```

### Check Tests
```bash
npm test

# Should see:
# ✓ All tests passing
# ✓ Coverage above 70%
```

### Check Code Quality
```bash
npm run lint
npm run format:check

# Should see:
# ✓ No linting errors
# ✓ All files formatted correctly
```

---

## 🔧 Environment Variables

Edit `.env` file:

```env
# Required
NODE_ENV=development    # development | production
PORT=3000              # Application port
HOST=localhost         # Host address

# Logging
LOG_LEVEL=info         # error | warn | info | debug
LOG_DIR=logs           # Log directory

# Optional (add as needed)
# DB_HOST=localhost
# API_KEY=your_key_here
```

---

## 📚 Project Structure Overview

```
ci-cd-level3/
├── src/               # Application source code
│   ├── app.js        # Express app setup
│   ├── index.js      # Entry point
│   ├── middleware/   # Custom middleware
│   └── routes/       # API routes
├── tests/            # Test files
├── config/           # Configuration files
├── scripts/          # Automation scripts
└── docs/             # Documentation
```

---

## 🆘 Troubleshooting

### Port Already in Use
```bash
# Find and kill process on port 3000
npx kill-port 3000
# Or use different port in .env
PORT=3001
```

### Tests Failing
```bash
# Clear cache and reinstall
npm test -- --clearCache
rm -rf node_modules package-lock.json
npm install
```

### Lint Errors
```bash
# Auto-fix most issues
npm run lint:fix
npm run format
```

### PM2 Issues
```bash
# Reset PM2
pm2 kill
pm2 start src/index.js --name ci-cd-app
```

---

## 📖 Next Steps

1. **Read the full documentation:**
   - [README.md](../README.md) - Complete guide
   - [DEPLOYMENT.md](docs/DEPLOYMENT.md) - Deployment details
   - [CONTRIBUTING.md](docs/CONTRIBUTING.md) - How to contribute

2. **Explore the code:**
   - Start with `src/index.js` and `src/app.js`
   - Check out the middleware in `src/middleware/`
   - Review the tests in `tests/`

3. **Customize for your needs:**
   - Add new routes in `src/routes/`
   - Add new tests in `tests/`
   - Update configuration in `config/`

4. **Setup CI/CD:**
   - Configure GitHub secrets
   - Review `.github/workflows/ci-cd.yml`
   - Test deployment pipeline

---

## 🎉 Success!

You now have a professional-grade CI/CD application running locally and ready for deployment!

**Need help?** Check the [full documentation](../README.md) or open an issue.

---

**Happy Coding! 🚀**
