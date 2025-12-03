# CI/CD Level 3 - Professional Grade Application

[![CI/CD Pipeline](https://github.com/yourusername/ci-cd-level3/actions/workflows/ci-cd.yml/badge.svg)](https://github.com/yourusername/ci-cd-level3/actions/workflows/ci-cd.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Node.js Version](https://img.shields.io/badge/node-%3E%3D14.0.0-brightgreen)](https://nodejs.org)

A **professional-grade CI/CD project** demonstrating enterprise-level practices for Node.js applications with comprehensive automated testing, code quality checks, and deployment automation using GitHub Actions.

---

## 📋 Table of Contents

- [Features](#-features)
- [Architecture](#-architecture)
- [Project Structure](#-project-structure)
- [Prerequisites](#-prerequisites)
- [Installation](#-installation)
- [Configuration](#-configuration)
- [Usage](#-usage)
- [Testing](#-testing)
- [CI/CD Pipeline](#-cicd-pipeline)
- [Deployment](#-deployment)
- [Troubleshooting](#-troubleshooting)
- [Contributing](#-contributing)
- [License](#-license)

---

## ✨ Features

- **🏗️ Professional Project Structure** - Well-organized codebase following industry best practices
- **🧪 Comprehensive Testing** - Unit tests, integration tests, and code coverage reporting
- **🔍 Code Quality** - ESLint, Prettier, and pre-commit hooks with Husky
- **📊 Logging System** - Winston-based logging with multiple transports
- **🔄 CI/CD Automation** - GitHub Actions workflow with matrix testing
- **🚀 Automated Deployment** - SSH-based deployment to VPS with health checks
- **🛡️ Error Handling** - Centralized error handling middleware
- **💚 Health Monitoring** - Built-in health check endpoints
- **📦 Production Ready** - PM2 process management and graceful shutdown

---

## 🏛️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     GitHub Repository                        │
└────────────────┬────────────────────────────────────────────┘
                 │
                 │ Push/PR
                 ▼
┌─────────────────────────────────────────────────────────────┐
│                   GitHub Actions CI/CD                       │
├─────────────────────────────────────────────────────────────┤
│  1. Lint & Format Check (ESLint + Prettier)                 │
│  2. Test Matrix (Node 14, 16, 18, 20)                       │
│  3. Security Audit (npm audit)                              │
│  4. Build & Create Artifacts                                │
│  5. Deploy to VPS (SSH) - main branch only                  │
│  6. Health Check Verification                               │
└────────────────┬────────────────────────────────────────────┘
                 │
                 │ Deploy (main branch)
                 ▼
┌─────────────────────────────────────────────────────────────┐
│                    Production VPS                            │
├─────────────────────────────────────────────────────────────┤
│  • Pull latest code                                         │
│  • Install dependencies (npm ci)                            │
│  • Restart with PM2                                         │
│  • Health check validation                                  │
│  • Rollback on failure                                      │
└─────────────────────────────────────────────────────────────┘
```

---

## 📁 Project Structure

```
ci-cd-level3/
├── .github/
│   └── workflows/
│       └── ci-cd.yml          # GitHub Actions CI/CD pipeline
├── config/
│   ├── index.js               # Application configuration
│   └── logger.js              # Winston logger setup
├── scripts/
│   ├── deploy.sh              # Deployment script for VPS
│   └── setup.sh               # Development environment setup
├── src/
│   ├── middleware/
│   │   └── errorHandler.js    # Error handling middleware
│   ├── routes/
│   │   └── health.js          # Health check endpoint
│   ├── app.js                 # Express application setup
│   └── index.js               # Application entry point
├── tests/
│   ├── app.test.js            # Application unit tests
│   ├── config.test.js         # Configuration tests
│   └── integration.test.js    # Integration tests
├── .editorconfig              # Editor configuration
├── .env.example               # Environment variables template
├── .eslintrc.js               # ESLint configuration
├── .gitignore                 # Git ignore rules
├── .lintstagedrc.js           # Lint-staged configuration
├── .prettierrc.js             # Prettier configuration
├── .prettierignore            # Prettier ignore rules
├── jest.config.js             # Jest testing configuration
├── LICENSE                    # MIT License
├── package.json               # Project dependencies and scripts
└── README.md                  # This file
```

---

## 🔧 Prerequisites

- **Node.js**: >= 14.0.0
- **npm**: >= 6.0.0
- **Git**: For version control
- **PM2**: For production process management (on VPS)

---

## 📦 Installation

### 1. Clone the repository

```bash
git clone https://github.com/yourusername/ci-cd-level3.git
cd ci-cd-level3
```

### 2. Run setup script

```bash
chmod +x scripts/setup.sh
./scripts/setup.sh
```

Or manually:

```bash
npm install
cp .env.example .env
npx husky install
```

### 3. Configure environment variables

Edit `.env` file with your configuration:

```env
NODE_ENV=development
PORT=3000
HOST=localhost
LOG_LEVEL=info
LOG_DIR=logs
```

---

## ⚙️ Configuration

### GitHub Secrets

Configure the following secrets in your GitHub repository (`Settings > Secrets and variables > Actions`):

| Secret Name    | Description                          | Example                    |
|----------------|--------------------------------------|----------------------------|
| `SERVER_HOST`  | VPS IP address or hostname          | `192.168.1.100`            |
| `SERVER_USER`  | SSH username                        | `ubuntu`                   |
| `SERVER_KEY`   | SSH private key (PEM format)        | `-----BEGIN RSA PRIVATE...`|
| `SERVER_PORT`  | SSH port (optional, default: 22)    | `22`                       |

### VPS Setup

1. **Install Node.js and PM2:**

```bash
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs
sudo npm install -g pm2
```

2. **Clone repository on VPS:**

```bash
sudo mkdir -p /var/www/project
sudo chown -R $USER:$USER /var/www/project
cd /var/www/project
git clone https://github.com/yourusername/ci-cd-level3.git .
```

3. **Initial setup:**

```bash
npm ci --production
cp .env.example .env
# Edit .env with production values
pm2 start src/index.js --name ci-cd-app
pm2 save
pm2 startup
```

---

## 🚀 Usage

### Development

```bash
# Start development server with auto-reload
npm run dev

# Run tests in watch mode
npm run test:watch
```

### Production

```bash
# Start production server
npm start

# Or with PM2
pm2 start src/index.js --name ci-cd-app -i max
```

### Available Scripts

| Command              | Description                                      |
|----------------------|--------------------------------------------------|
| `npm start`          | Start the application                            |
| `npm run dev`        | Start with nodemon for development              |
| `npm test`           | Run tests with coverage                          |
| `npm run test:ci`    | Run tests in CI mode                            |
| `npm run lint`       | Check code quality with ESLint                  |
| `npm run lint:fix`   | Fix ESLint issues automatically                 |
| `npm run format`     | Format code with Prettier                       |
| `npm run format:check` | Check code formatting                          |
| `npm run validate`   | Run all checks (lint + format + test)           |

---

## 🧪 Testing

### Running Tests

```bash
# Run all tests with coverage
npm test

# Run tests in watch mode
npm run test:watch

# Run tests in CI mode
npm run test:ci
```

### Test Coverage

Coverage reports are generated in the `coverage/` directory. Open `coverage/lcov-report/index.html` in your browser to view detailed coverage.

**Coverage Thresholds:**
- Branches: 70%
- Functions: 70%
- Lines: 70%
- Statements: 70%

### Test Structure

- **Unit Tests**: `tests/app.test.js`, `tests/config.test.js`
- **Integration Tests**: `tests/integration.test.js`

---

## 🔄 CI/CD Pipeline

### How CI Works

The CI pipeline runs on **every push and pull request** to `main` and `develop` branches:

1. **Lint Job**: Checks code quality with ESLint and Prettier
2. **Test Job**: Runs tests across Node.js versions 14, 16, 18, and 20
3. **Build Job**: Creates production build and artifacts
4. **Security Job**: Runs npm audit for vulnerabilities

### How CD Works

The CD pipeline runs **only on pushes to main branch**:

1. **Waits** for all CI jobs to pass
2. **Downloads** build artifacts
3. **Connects** to VPS via SSH
4. **Executes** deployment script
5. **Verifies** deployment with health check
6. **Rolls back** on failure

### Workflow Diagram

```
Push/PR → Lint → Test (Matrix) → Build → Security
                                    ↓
                       (main branch only)
                                    ↓
                                 Deploy → Health Check → ✅ Success
                                    ↓                    ↓
                                 Failure → Rollback → ❌ Failed
```

### Matrix Testing

Tests run across multiple Node.js versions to ensure compatibility:
- Node.js 14.x
- Node.js 16.x
- Node.js 18.x
- Node.js 20.x

---

## 🚢 Deployment

### Automatic Deployment

Deployment happens automatically when code is pushed to the `main` branch and all CI checks pass.

### Manual Deployment

SSH into your VPS and run:

```bash
cd /var/www/project
chmod +x scripts/deploy.sh
./scripts/deploy.sh
```

### Deployment Process

1. **Backup**: Creates backup of current version
2. **Pull**: Fetches latest code from repository
3. **Install**: Installs production dependencies
4. **Health Check**: Verifies current app status
5. **Restart**: Restarts application with PM2
6. **Verify**: Confirms deployment success
7. **Rollback**: Reverts on failure

### Health Check Endpoint

```bash
# Check application health
curl http://localhost:3000/health

# Response:
{
  "uptime": 1234.56,
  "message": "OK",
  "timestamp": 1234567890,
  "environment": "production"
}
```

---

## 🔧 Troubleshooting

### Common Issues

#### 1. Tests Failing Locally

```bash
# Clear Jest cache
npm test -- --clearCache

# Reinstall dependencies
rm -rf node_modules package-lock.json
npm install
```

#### 2. Deployment Fails on VPS

```bash
# Check PM2 logs
pm2 logs ci-cd-app

# Check deployment script permissions
chmod +x scripts/deploy.sh

# Verify SSH connection
ssh username@server-ip
```

#### 3. GitHub Actions Failing

- Check that all secrets are properly configured
- Verify branch names match workflow triggers
- Review GitHub Actions logs for specific errors

#### 4. Linting Errors

```bash
# Auto-fix most issues
npm run lint:fix
npm run format

# Check specific files
npx eslint src/app.js
```

#### 5. Port Already in Use

```bash
# Find process using port 3000
lsof -i :3000

# Kill the process
kill -9 <PID>

# Or use different port in .env
PORT=3001
```

---

## 📊 Code Quality

This project maintains high code quality through:

- **ESLint**: JavaScript linting
- **Prettier**: Code formatting
- **Husky**: Git hooks for pre-commit checks
- **Lint-staged**: Run linters on staged files only
- **Jest**: Comprehensive test coverage

### Pre-commit Hooks

Automatically runs before each commit:
- ESLint on JavaScript files
- Prettier formatting
- All configured checks must pass

---

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Commit Message Convention

Follow conventional commits:
- `feat:` New feature
- `fix:` Bug fix
- `docs:` Documentation changes
- `style:` Code style changes
- `refactor:` Code refactoring
- `test:` Test updates
- `chore:` Build/config changes

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 👨‍💻 Author

**Your Name**
- GitHub: [@Ausartal](https://github.com/ausartal)
- Email: ahmadnabaalfalah@gmail.com

---

## 🙏 Acknowledgments

- Express.js for the web framework
- Jest for testing framework
- Winston for logging
- GitHub Actions for CI/CD
- PM2 for process management

---

## 📈 Project Status

🟢 **Active Development** - This project is actively maintained and open for contributions.

---

**Made with ❤️ for learning CI/CD best practices**
