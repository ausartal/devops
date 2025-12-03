#!/bin/bash

set -e

echo "Setting up development environment..."

# Create necessary directories
mkdir -p logs
mkdir -p tmp

# Copy environment file if it doesn't exist
if [ ! -f .env ]; then
    echo "Creating .env file from .env.example..."
    cp .env.example .env
    echo "✅ .env file created. Please update it with your configuration."
else
    echo "ℹ️  .env file already exists"
fi

# Install dependencies
echo "Installing dependencies..."
npm install

# Setup git hooks with husky
echo "Setting up git hooks..."
npx husky install
npx husky add .husky/pre-commit "npx lint-staged"
npx husky add .husky/pre-push "npm test"

echo "✅ Development environment setup complete!"
echo ""
echo "Next steps:"
echo "  1. Update .env file with your configuration"
echo "  2. Run 'npm test' to verify everything works"
echo "  3. Run 'npm run dev' to start development server"
