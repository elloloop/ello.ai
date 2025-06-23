# Branch Protection Setup Guide

This document provides step-by-step instructions for configuring GitHub branch protection rules to enforce the CI/CD pipeline and prevent merging of pull requests that fail checks.

## Current Repository Status

- **Default Branch**: `main`
- **CI/CD Pipeline**: `.github/workflows/pr-checks.yml`
- **Status Checks**: 4 required checks configured
- **CODEOWNERS**: Created with `@iarunsaragadam` as the primary owner

## Required Setup Steps

### 1. Enable Branch Protection Rules

1. Go to your GitHub repository: `https://github.com/[your-username]/ello.ai`
2. Navigate to **Settings** > **Branches**
3. Click **Add rule** under "Branch protection rules"
4. In "Branch name pattern", enter `main`

### 2. Configure Protection Settings

Enable the following options:

#### ✅ Required Settings:

**Require a pull request before merging**

- ☑️ Require approvals: **1** (minimum recommended)
- ☑️ Dismiss stale reviews when new commits are pushed
- ☑️ Require review from CODEOWNERS (enabled via CODEOWNERS file)

**Require status checks to pass before merging**

- ☑️ Require branches to be up to date before merging
- **Required status checks** (add these exact names):
  - `Flutter Lint & Test`
  - `Go Lint & Test`
  - `Build Verification`
  - `PR Status Summary`

**Additional Settings**

- ☑️ Require conversation resolution before merging
- ☑️ Require signed commits (recommended for security)
- ☑️ Require linear history (optional, keeps history clean)

#### ⚠️ Admin Settings:

- ☑️ Do not allow bypassing the above settings
- ☑️ Restrict pushes that create files (optional)

### 3. Click "Create" to Save

## Status Checks Explained

The pipeline includes these status checks:

### Flutter Lint & Test

- Runs `flutter analyze` with fatal warnings/infos
- Checks code formatting with `dart format`
- Executes all Flutter tests with coverage
- Generates protobuf files
- **Timeout**: 30 minutes

### Go Lint & Test

- Checks Go code formatting with `gofmt`
- Runs `go vet` for potential issues
- Executes `staticcheck` for additional linting
- Runs Go tests (if any `*_test.go` files exist)
- **Timeout**: 15 minutes

### Build Verification

- Builds Flutter web app
- Builds Android APK (debug)
- Builds Go server binary
- Ensures the entire project compiles successfully
- **Timeout**: 20 minutes

### PR Status Summary

- Aggregates results from all other checks
- Provides final pass/fail status
- **Timeout**: 5 minutes

### Security Scan (Non-blocking)

- Runs Trivy vulnerability scanner
- Uploads results to GitHub Security tab
- **Non-blocking** (continues on error)
- **Timeout**: 10 minutes

## Pipeline Behavior

### On Pull Request Events:

- **opened**: Runs full pipeline
- **synchronize**: Runs when new commits are pushed
- **reopened**: Runs when PR is reopened

### Concurrency Control:

- Only one pipeline runs per PR at a time
- New pushes cancel previous runs to save resources

## Verification Steps

Once configured, test the branch protection:

1. **Create a test branch**:

   ```bash
   git checkout -b test-branch-protection
   ```

2. **Make a small change** and commit:

   ```bash
   echo "# Test" >> README.md
   git add README.md
   git commit -m "test: branch protection"
   git push origin test-branch-protection
   ```

3. **Create a PR** from `test-branch-protection` to `main`

4. **Verify** that:
   - ✅ All status checks run automatically
   - ✅ PR cannot be merged until checks pass
   - ✅ CODEOWNERS review is required
   - ✅ Direct push to main is blocked

## Troubleshooting Common Issues

### Pipeline Fails on Flutter Analyze

```bash
# Run locally to fix issues:
flutter analyze --fatal-infos --fatal-warnings
dart format --set-exit-if-changed .
```

### Pipeline Fails on Go Formatting

```bash
# Fix Go formatting issues:
cd server
gofmt -s -w .
go vet ./...
```

### Build Failures

```bash
# Test builds locally:
flutter build web --no-pub
flutter build apk --debug --no-pub

cd server
go build -v .
```

### Status Check Names Don't Match

If the status check names in GitHub don't match exactly, check the job names in `.github/workflows/pr-checks.yml`:

- `flutter-checks` → `Flutter Lint & Test`
- `go-checks` → `Go Lint & Test`
- `build-check` → `Build Verification`
- `summary` → `PR Status Summary`

## Adding Additional Checks

To add more checks to the pipeline:

1. Add new jobs to `.github/workflows/pr-checks.yml`
2. Update the `needs:` array in the `summary` job
3. Add the new job name to the branch protection required status checks

## Emergency Override

Repository administrators can temporarily:

1. Go to **Settings** > **Branches**
2. Click on the `main` branch rule
3. Uncheck "Do not allow bypassing the above settings"
4. Merge critical hotfixes
5. Re-enable protection immediately after

**⚠️ Always re-enable protection after emergency changes!**

## Security Best Practices

1. **Signed Commits**: Enable GPG signing for all commits
2. **Two-Factor Authentication**: Require 2FA for all contributors
3. **Regular Security Scans**: Monitor Trivy results in Security tab
4. **Dependency Updates**: Regularly update dependencies
5. **Access Control**: Limit admin access to trusted maintainers

## Monitoring and Maintenance

### Regular Tasks:

- Review and update CODEOWNERS as team changes
- Monitor pipeline performance and adjust timeouts
- Review security scan results monthly
- Update branch protection rules as needed

### Metrics to Track:

- PR merge time
- Pipeline success rate
- Security vulnerabilities found
- Code review coverage

---

**Note**: This setup ensures code quality, security, and collaboration while maintaining development velocity. Adjust settings based on your team size and project requirements.
