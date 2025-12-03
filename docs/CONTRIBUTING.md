# Contributing to CI/CD Level 3

Thank you for your interest in contributing! This document provides guidelines and instructions for contributing to this project.

## Code of Conduct

- Be respectful and inclusive
- Welcome newcomers and encourage diverse perspectives
- Focus on constructive feedback
- Maintain professional communication

## Getting Started

### 1. Fork and Clone

```bash
# Fork the repository on GitHub, then:
git clone https://github.com/yourusername/ci-cd-level3.git
cd ci-cd-level3
```

### 2. Setup Development Environment

```bash
# Run setup script
chmod +x scripts/setup.sh
./scripts/setup.sh

# Or manually
npm install
cp .env.example .env
npx husky install
```

### 3. Create a Branch

```bash
git checkout -b feature/your-feature-name
# or
git checkout -b fix/your-bug-fix
```

## Development Workflow

### Running Locally

```bash
# Start development server
npm run dev

# Run tests
npm test

# Run tests in watch mode
npm run test:watch
```

### Code Quality

Before committing, ensure your code passes all checks:

```bash
# Run all validations
npm run validate

# Or individually:
npm run lint
npm run format:check
npm test
```

### Git Hooks

This project uses Husky for git hooks:
- **pre-commit**: Runs lint-staged (ESLint + Prettier on staged files)
- **pre-push**: Runs all tests

## Commit Guidelines

### Commit Message Format

Follow the [Conventional Commits](https://www.conventionalcommits.org/) specification:

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Types

- **feat**: New feature
- **fix**: Bug fix
- **docs**: Documentation changes
- **style**: Code style changes (formatting, missing semicolons, etc.)
- **refactor**: Code refactoring without feature changes
- **perf**: Performance improvements
- **test**: Adding or updating tests
- **chore**: Build process or auxiliary tool changes
- **ci**: CI/CD configuration changes

### Examples

```bash
feat(api): add user authentication endpoint

fix(deploy): resolve PM2 restart issue

docs(readme): update installation instructions

test(integration): add API endpoint tests
```

## Pull Request Process

### 1. Update Your Branch

```bash
git fetch upstream
git rebase upstream/main
```

### 2. Push Your Changes

```bash
git push origin feature/your-feature-name
```

### 3. Create Pull Request

- Go to GitHub and create a Pull Request
- Fill out the PR template completely
- Link any related issues
- Ensure all CI checks pass

### 4. Code Review

- Address reviewer feedback
- Make requested changes
- Push updates to your branch

### 5. Merge

Once approved, a maintainer will merge your PR.

## Testing Guidelines

### Writing Tests

- Write tests for all new features
- Update tests for bug fixes
- Maintain code coverage above 70%
- Use descriptive test names

### Test Structure

```javascript
describe('Feature Name', () => {
  describe('Function/Method Name', () => {
    it('should do something specific', () => {
      // Arrange
      const input = 'test';
      
      // Act
      const result = functionToTest(input);
      
      // Assert
      expect(result).toBe('expected');
    });
  });
});
```

### Running Tests

```bash
# All tests
npm test

# Specific test file
npm test -- tests/app.test.js

# Watch mode
npm run test:watch

# Coverage report
npm test -- --coverage
```

## Code Style

### JavaScript Style Guide

- Use ES6+ features
- 2 spaces for indentation
- Single quotes for strings
- Semicolons required
- No trailing commas in objects/arrays (except ES5)

### File Naming

- Use camelCase for files: `myFile.js`
- Use PascalCase for classes: `MyClass.js`
- Use kebab-case for config files: `my-config.js`

### Directory Structure

```
src/
  ├── middleware/    # Express middleware
  ├── routes/        # Route handlers
  ├── services/      # Business logic
  ├── utils/         # Utility functions
  └── app.js         # App setup
```

## Documentation

### Code Comments

```javascript
/**
 * Function description
 * @param {string} param1 - Description
 * @param {number} param2 - Description
 * @returns {boolean} Description
 */
function myFunction(param1, param2) {
  // Implementation
}
```

### README Updates

- Update README.md for new features
- Add examples and usage instructions
- Update table of contents if needed

## Reporting Bugs

### Before Reporting

- Check existing issues
- Verify it's reproducible
- Check if it's already fixed in latest version

### Bug Report Template

```markdown
**Describe the bug**
A clear description of the bug.

**To Reproduce**
Steps to reproduce:
1. Go to '...'
2. Click on '...'
3. See error

**Expected behavior**
What you expected to happen.

**Screenshots**
If applicable, add screenshots.

**Environment:**
 - OS: [e.g., Ubuntu 20.04]
 - Node.js version: [e.g., 18.0.0]
 - npm version: [e.g., 8.0.0]

**Additional context**
Any other context about the problem.
```

## Feature Requests

### Feature Request Template

```markdown
**Is your feature request related to a problem?**
A clear description of the problem.

**Describe the solution you'd like**
A clear description of what you want to happen.

**Describe alternatives you've considered**
Any alternative solutions or features you've considered.

**Additional context**
Any other context or screenshots about the feature request.
```

## Questions?

- Open an issue with the `question` label
- Check existing issues and documentation first
- Be specific about what you're trying to achieve

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

---

Thank you for contributing! 🎉
