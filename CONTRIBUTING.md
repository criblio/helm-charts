# Contributing to Cribl Helm Charts

Thank you for your interest in contributing to Cribl Helm Charts! This document provides guidelines and information for developers working on this repository.

## Table of Contents

- [Repository Structure](#repository-structure)
- [Prerequisites](#prerequisites)
- [Development Workflow](#development-workflow)
- [GitHub Workflows](#github-workflows)
- [Coding Standards](#coding-standards)
- [Testing](#testing)
- [Adding New Charts](#adding-new-charts)
- [Release Process](#release-process)
- [Code Review](#code-review)

## Repository Structure

```text
helm-charts/
├── .github/
│   └── workflows/             # GitHub Actions CI/CD workflows
│       ├── pr.yml             # Pull request validation
│       └── release.yml        # Release automation
├── common_docs/               # Shared documentation across charts
│   ├── EKS_SPECIFICS.md
│   └── EXTRA_EXAMPLES.md
├── helm-chart-sources/        # Source code for all Helm charts
│   ├── appscope/              # AppScope chart
│   ├── common/                # Shared templates and helpers
│   ├── edge/                  # Cribl Edge chart
│   ├── logstream-leader/      # Cribl Leader chart
│   ├── logstream-workergroup/ # Stream Worker Group chart
│   ├── outpost/               # Cribl Outpost chart
│   └── pod-killer/            # Pod killer utility chart
├── scripts/                   # Build and release automation scripts
│   ├── build.sh               # Local chart packaging
│   ├── bump-version           # Version bumping script
│   └── kubeconform.sh         # Kubernetes manifest validation
├── images/                    # Documentation images
├── index.yaml                 # Helm repository index
└── README.md                  # User-facing documentation
```

### Chart Structure

Each chart in `helm-chart-sources/` follows the standard Helm chart structure:

```text
chart-name/
├── Chart.yaml              # Chart metadata (version, appVersion, dependencies)
├── values.yaml             # Default configuration values
├── README.md               # Chart-specific documentation
├── templates/              # Kubernetes manifest templates
│   ├── _helpers.tpl        # Template helpers and functions
│   ├── deployment.yaml     # Main workload definition
│   ├── service.yaml        # Service definitions
│   ├── ingress.yaml        # Ingress rules
│   └── ...                 # Other Kubernetes resources
└── tests/                  # Unit tests for the chart
    ├── *_test.yaml         # Test suites
    ├── fixtures/           # Test fixture values
    └── values/             # Additional test values
```

## Prerequisites

### Required Tools

- **Helm 3.x**: Install via Homebrew on macOS: `brew install helm`
- **kubectl**: Kubernetes CLI tool
- **Docker**: For running tests in containers
- **Go 1.19+**: Required for kubeconform validation

### Helm Plugins

Install the helm-unittest plugin for running tests:

```bash
helm plugin install https://github.com/helm-unittest/helm-unittest
```

### Optional Tools

- **kubeconform**: Kubernetes manifest validation (installed via CI or manually with `go install`)

  ```bash
  go install github.com/yannh/kubeconform/cmd/kubeconform@latest
  ```

## Development Workflow

### Setting Up Your Development Environment

1. **Fork and clone the repository**:

   ```bash
   git clone https://github.com/criblio/helm-charts.git
   cd helm-charts
   ```

2. **Create a feature branch**:

   ```bash
   git checkout -b feature/my-improvement
   ```

3. **Make your changes** to the chart source files in `helm-chart-sources/`

4. **Test locally** (see [Testing](#testing) section)

5. **Commit your changes**:

   ```bash
   git add .
   git commit -m "Description of changes"
   ```

6. **Push and create a pull request**:

   ```bash
   git push origin feature/my-improvement
   ```

### Local Development Tips

- Use `helm template` to render templates locally and inspect generated manifests:

  ```bash
  helm template my-release helm-chart-sources/logstream-leader
  ```

- Use `helm template` with custom values:

  ```bash
  helm template my-release helm-chart-sources/logstream-leader -f custom-values.yaml
  ```

- Lint charts during development:

  ```bash
  helm lint helm-chart-sources/logstream-leader
  ```

## GitHub Workflows

### Pull Request Workflow (`.github/workflows/pr.yml`)

Runs automatically on all pull requests. Executes the following checks:

1. **Helm Linting**: Validates chart syntax and structure

   ```bash
   helm lint helm-chart-sources/*
   ```

2. **Unit Tests**: Runs helm-unittest on all charts

   ```bash
   helm unittest helm-chart-sources/*
   ```

3. **Kubeconform Validation**: Validates that rendered manifests conform to Kubernetes schemas
   - Tests all charts with their fixture values
   - Ensures generated YAML is valid Kubernetes resources

**All checks must pass before a PR can be merged.**

### Release Workflow (`.github/workflows/release.yml`)

Triggered when a new version tag (e.g., `v1.2.3`) is pushed to the repository:

1. **Package Charts**: Creates `.tgz` packages for all charts
2. **Update Helm Repository Index**: Updates `index.yaml` with new versions
3. **Create GitHub Release**: Uploads packaged charts as release artifacts
4. **Commit Index**: Pushes updated `index.yaml` back to the master branch

**Note**: This workflow is typically triggered by the `bump-version` script.

## Coding Standards

### Helm Template Best Practices

1. **Use Named Templates**: Define reusable template snippets in `_helpers.tpl`

   ```yaml
   {{- define "chart.labels" -}}
   app.kubernetes.io/name: {{ include "chart.name" . }}
   app.kubernetes.io/instance: {{ .Release.Name }}
   {{- end }}
   ```

2. **Provide Sensible Defaults**: `values.yaml` should have production-ready defaults

3. **Document Values**: Add comments in `values.yaml` explaining each configuration option

4. **Support Common Kubernetes Patterns**:
   - Resource requests and limits
   - Security contexts
   - Pod disruption budgets
   - Horizontal pod autoscaling
   - Node affinity and tolerations

5. **Conditional Resource Creation**: Use `if` blocks to conditionally render resources:

   ```yaml
   {{- if .Values.ingress.enabled }}
   # ingress resource
   {{- end }}
   ```

6. **Quote String Values**: Always quote string values in templates to prevent type coercion issues:

   ```yaml
   value: {{ .Values.config.token | quote }}
   ```

### YAML Formatting

- Use **2 spaces** for indentation (no tabs)
- Keep lines under **120 characters** when possible
- Use comments to explain complex logic
- Maintain consistent ordering of Kubernetes resource fields

### Versioning

Charts follow [Semantic Versioning](https://semver.org/):

- **MAJOR**: Breaking changes or major new features
- **MINOR**: New features, backwards compatible
- **PATCH**: Bug fixes, backwards compatible

Both `version` (chart version) and `appVersion` (application version) in `Chart.yaml` should be updated appropriately and match.

## Testing

### Unit Tests

Unit tests use [helm-unittest](https://github.com/helm-unittest/helm-unittest/) to validate template rendering logic.

#### Running Tests Locally

**Option 1: Using Docker** (recommended for consistency with CI):

```bash
# Test a specific chart
docker run -ti --rm -v "$(pwd):/apps" helmunittest/helm-unittest helm-chart-sources/logstream-leader

# Test all charts
docker run -ti --rm -v "$(pwd):/apps" helmunittest/helm-unittest helm-chart-sources/*
```

**Option 2: Using the Helm Plugin** (if installed):

```bash
# Test a specific chart
helm unittest helm-chart-sources/logstream-leader

# Test all charts
helm unittest helm-chart-sources/*
```

#### Writing Unit Tests

Test files are located in each chart's `tests/` directory and follow the pattern `*_test.yaml`.

**Test Structure**:

```yaml
suite: Test Suite Name
templates:
  - template-to-test.yaml
tests:
  - it: Should do something specific
    set:
      # Override values for this test
      someValue: customValue
    asserts:
      - equal:
          path: spec.some.path
          value: expectedValue
      - exists:
          path: spec.required.field
      - notExists:
          path: spec.should.not.exist
```

**Common Assertions**:

- `equal`: Check exact value match
- `exists`: Verify path exists
- `notExists`: Verify path doesn't exist
- `contains`: Check if array contains value
- `isKind`: Verify resource kind
- `matchRegex`: Pattern matching

**Example Test**:

```yaml
suite: Deployment Tests
templates:
  - deployment.yaml
tests:
  - it: Should set custom image tag
    set:
      criblImage:
        tag: "3.5.0"
    asserts:
      - equal:
          path: spec.template.spec.containers[0].image
          value: cribl/cribl:3.5.0
```

#### Test Fixtures

Fixture files in `tests/fixtures/` provide complete value sets for testing complex scenarios:

- Used by kubeconform validation
- Useful for testing realistic configurations
- Should represent common deployment patterns

### Validation Tests

Run kubeconform locally:

```bash
./scripts/kubeconform.sh
```

This validates that all templates render to valid Kubernetes manifests.

### Manual Testing

Before submitting a PR, test your changes in a real Kubernetes cluster:

1. **Package the chart locally**:

   ```bash
   helm package helm-chart-sources/logstream-leader
   ```

2. **Install in a test cluster**:

   ```bash
   kubectl create namespace test-cribl
   helm install test-release ./logstream-leader-*.tgz -n test-cribl
   ```

3. **Verify resources are created correctly**:

   ```bash
   kubectl get all -n test-cribl
   kubectl describe deployment test-release-logstream-leader -n test-cribl
   ```

4. **Test upgrades**:

   ```bash
   helm upgrade test-release ./logstream-leader-*.tgz -n test-cribl
   ```

5. **Clean up**:

   ```bash
   helm uninstall test-release -n test-cribl
   kubectl delete namespace test-cribl
   ```

## Adding New Charts

### Creating a New Chart

1. **Generate the chart structure**:

   ```bash
   cd helm-chart-sources
   helm create my-new-chart
   ```

2. **Update `Chart.yaml`**:
   - Set appropriate `name`, `description`, and `version`
   - Add the Cribl icon URL
   - Set `type: application`
   - Define `appVersion` to match the application version

3. **Configure `values.yaml`**:
   - Define all configurable parameters
   - Provide sensible defaults
   - Add comments explaining each option
   - Follow patterns from existing charts

4. **Create templates**:
   - Use `_helpers.tpl` for common template functions
   - Consider reusing templates from the `common/` chart
   - Implement standard Kubernetes resources (Deployment, Service, etc.)

5. **Add documentation**:
   - Create a comprehensive `README.md`
   - Document all values with examples
   - Include deployment instructions

6. **Write tests**:
   - Create unit tests in `tests/` directory
   - Add test fixtures in `tests/fixtures/`
   - Aim for high coverage of template logic

7. **Add to `bump-version`**:
   - Adjust the regexps in `scripts/bump-version` to include the new chart

8. **Add to build scripts**:
   - Verify the chart is picked up by wildcard patterns in scripts
   - Test with `./scripts/build.sh`

### Chart Design Guidelines

- **Single Responsibility**: Each chart should deploy one logical component
- **Composability**: Charts should work independently and together
- **Configuration**: Expose necessary configuration, hide complexity
- **Documentation**: Document all important values and use cases
- **Testing**: Write comprehensive tests for all template logic
- **Compatibility**: Maintain backwards compatibility when possible

## Release Process

### Preparing a Release

Releases are handled through Git tags and automated by GitHub Actions.

#### Using the `bump-version` Script

The `bump-version` script automates version updates across all relevant files:

```bash
# Bump to version 4.16.0
./scripts/bump-version 4.16.0

# Script will:
# 1. Update Chart.yaml files (version and appVersion)
# 2. Update values.yaml files (image tags)
# 3. Update README.md files (documentation)
# 4. Create a git commit
# 5. Create a git tag (v4.16.0)
# 6. Push commit and tag to origin
```

**What it updates**:

- `helm-chart-sources/{logstream-leader,logstream-workergroup,edge,outpost}/Chart.yaml`
  - `version:` field
  - `appVersion:` field
- `helm-chart-sources/{logstream-leader,logstream-workergroup,edge,outpost}/values.yaml`
  - `image.tag:` field
- `helm-chart-sources/{logstream-leader,logstream-workergroup,edge,outpost}/README.md`
  - Version references in documentation

### Release Checklist

Before creating a release:

- [ ] All tests pass locally
- [ ] PR reviews are complete and approved
- [ ] CHANGELOG or release notes are prepared (if applicable)
- [ ] Version numbers are updated consistently
- [ ] Documentation is up to date
- [ ] Breaking changes are clearly documented

### Post-Release

After the release workflow completes:

1. **Verify the release** on GitHub

2. **Test installation** from the public repository:

   ```bash
   helm repo update
   helm search repo cribl
   helm install test-release cribl/logstream-leader --version 1.2.3
   ```

3. **Announce the release** in appropriate channels (Slack, etc.)

## Code Review

### Submitting Pull Requests

1. **Keep PRs focused**: One feature or fix per PR
2. **Write clear descriptions**: Explain what changes and why
3. **Reference issues**: Link to related issues or tickets
4. **Update tests**: Add or update tests for your changes
5. **Update documentation**: Keep READMEs and comments current

### Review Process

All PRs require approval from CODEOWNERS:

- **Default reviewers**: Technical team members
- **Documentation reviewers**: Technical writers for `*.md` changes

See `CODEOWNERS` file for the current list of reviewers.

### Review Criteria

Reviewers will check:

- [ ] Code follows Helm and Kubernetes best practices
- [ ] Tests are adequate and passing
- [ ] Documentation is clear and complete
- [ ] No breaking changes (or clearly documented if necessary)
- [ ] Security implications are considered
- [ ] Performance impact is acceptable

## Getting Help

- **Community Slack**: Join our [Slack Community](https://cribl.io/community/)
- **Issues**: Open an issue on GitHub for bugs or feature requests
- **Documentation**: Check the individual chart READMEs for specific details

## License

By contributing to this repository, you agree that your contributions will be licensed under the same license as the project (see [LICENSE](LICENSE) file).
