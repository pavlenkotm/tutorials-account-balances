# Contributing to Web3 Multi-Language Playground

Thank you for your interest in contributing! This document provides guidelines for contributing to this project.

## 🤝 How to Contribute

### Reporting Issues

- Use the GitHub issue tracker
- Describe the issue clearly with steps to reproduce
- Include relevant code snippets and error messages
- Specify your environment (OS, language version, etc.)

### Suggesting Enhancements

- Open an issue with the `enhancement` label
- Clearly describe the proposed feature
- Explain why it would be beneficial
- Include example use cases

### Pull Requests

1. **Fork the repository**
2. **Create a feature branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```
3. **Make your changes**
   - Follow the existing code style
   - Add tests if applicable
   - Update documentation
4. **Commit your changes**
   ```bash
   git commit -m "feat(scope): add your feature"
   ```
   Follow [Conventional Commits](https://www.conventionalcommits.org/)
5. **Push to your fork**
   ```bash
   git push origin feature/your-feature-name
   ```
6. **Open a Pull Request**

## 📝 Commit Message Guidelines

We follow the Conventional Commits specification:

```
<type>(<scope>): <description>

[optional body]

[optional footer]
```

### Types

- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, etc.)
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Maintenance tasks

### Examples

```
feat(solidity): add ERC-1155 multi-token example
fix(python): correct balance calculation in wallet manager
docs(readme): update installation instructions
test(rust): add unit tests for counter program
```

## 🏗️ Adding New Language Examples

### Structure

Each language example should follow this structure:

```
examples/<language>/<project-name>/
├── README.md           # Comprehensive documentation
├── <source-files>      # Implementation files
├── <config-files>      # Build/dependency configuration
└── <test-files>        # Tests (if applicable)
```

### README Requirements

Each example must include:

1. **Title and Description**
2. **Features List** (with checkmarks ✅)
3. **Tech Stack**
4. **Setup Instructions**
5. **Usage Examples**
6. **Why This Language?** (benefits for Web3)
7. **Resources** (official docs, tutorials)
8. **License**

### Code Quality

- **Commented**: Include helpful comments
- **Documented**: Add docstrings/documentation
- **Working**: Code must compile/run
- **Secure**: Follow security best practices
- **Idiomatic**: Use language-specific best practices

## 🧪 Testing

- Add tests for new functionality
- Ensure existing tests pass
- Update test documentation

## 📚 Documentation

- Update the main README.md if adding new languages
- Keep inline documentation up to date
- Include code examples in documentation

## 🔍 Code Review Process

1. **Automated Checks**: CI/CD pipeline must pass
2. **Manual Review**: Maintainers review code
3. **Feedback**: Address review comments
4. **Approval**: At least one maintainer approval required
5. **Merge**: Squash and merge to main branch

## 🎯 Focus Areas

We especially welcome contributions in:

- New blockchain platforms (StarkNet, Cosmos, etc.)
- Additional language examples
- Improved documentation
- Test coverage
- Performance optimizations
- Security enhancements
- Tutorial content

## ⚖️ Code of Conduct

Please note that this project is released with a [Code of Conduct](CODE_OF_CONDUCT.md). By participating in this project you agree to abide by its terms.

## 📞 Getting Help

- Open an issue for questions
- Join discussions in pull requests
- Check existing issues and documentation

## 🙏 Recognition

Contributors will be recognized in:
- GitHub contributors list
- Release notes
- README acknowledgments (for significant contributions)

Thank you for contributing to the Web3 Multi-Language Playground! 🚀
