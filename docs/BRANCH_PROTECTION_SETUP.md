# Branch Protection Setup

This document explains how to configure GitHub branch protection rules to enforce the CI/CD pipeline and prevent merging of pull requests that fail checks.

## Required Setup Steps

### 1. Enable Branch Protection Rules

1. Go to your GitHub repository
2. Navigate to **Settings** > **Branches**
3. Click **Add rule** under "Branch protection rules"
4. In "Branch name pattern", enter `main` (or your default branch name)

### 2. Configure Protection Settings

Enable the following options:

#### ✅ Required Settings:
- **Require a pull request before merging**
  - ☑️ Require approvals: 1 (minimum recommended)
  - ☑️ Dismiss stale reviews when new commits are pushed
  - ☑️ Require review from CODEOWNERS (if you have a CODEOWNERS file)

- **Require status checks to pass before merging**
  - ☑️ Require branches to be up to date before merging
  - **Required status checks** (add these exact names):
    - `Flutter Lint & Test`
    - `Go Lint & Test` 
    - `Build Verification`
    - `PR Status Summary`

- **Require conversation resolution before merging**
- **Require signed commits** (recommended for security)
- **Require linear history** (optional, keeps history clean)

#### ⚠️ Admin Settings:
- **Do not allow bypassing the above settings** (unless you're the sole maintainer)
- **Restrict pushes that create files** (optional)

### 3. Verify Configuration

Once configured, the branch protection will:

1. ❌ **Block direct pushes** to the main branch
2. ❌ **Block merging** if any required status check fails
3. ❌ **Block merging** if PR doesn't have required approvals
4. ❌ **Block merging** if there are unresolved conversations
5. ✅ **Allow merging** only when all checks pass

## Status Checks Explained

The pipeline includes these status checks:

### Flutter Lint & Test
- Runs `flutter analyze` with fatal warnings/infos
- Checks code formatting with `dart format`
- Executes all Flutter tests with coverage
- Generates protobuf files

### Go Lint & Test  
- Checks Go code formatting with `gofmt`
- Runs `go vet` for potential issues
- Executes `staticcheck` for additional linting
- Runs Go tests (if any `*_test.go` files exist)

### Build Verification
- Builds Flutter web app
- Builds Android APK (debug)
- Builds Go server binary
- Ensures the entire project compiles successfully

### Security Scan
- Runs Trivy vulnerability scanner
- Uploads results to GitHub Security tab
- Non-blocking (continues on error)

## Pipeline Behavior

### On Pull Request Events:
- **opened**: Runs full pipeline
- **synchronize**: Runs when new commits are pushed
- **reopened**: Runs when PR is reopened

### Concurrency Control:
- Only one pipeline runs per PR at a time
- New pushes cancel previous runs to save resources

### Timeouts:
- Flutter checks: 30 minutes max
- Go checks: 15 minutes max  
- Build verification: 20 minutes max
- Security scan: 10 minutes max

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

## Adding Additional Checks

To add more checks to the pipeline:

1. Add new jobs to `.github/workflows/pr-checks.yml`
2. Update the `needs:` array in the `summary` job
3. Add the new job name to the branch protection required status checks

## Override for Emergencies

Repository administrators can temporarily:
1. Disable branch protection
2. Merge critical hotfixes
3. Re-enable protection immediately after

**⚠️ Always re-enable protection after emergency changes!**