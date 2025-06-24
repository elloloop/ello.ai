# GitHub Secrets Configuration for ello.AI Desktop Builds

This document outlines the GitHub Secrets required for signing and distributing desktop applications for ello.AI.

## Overview

The CI/CD pipeline automatically builds and signs desktop applications for macOS, Windows, and Linux when code is pushed to the `main` branch. To enable code signing and notarization, you need to configure the following secrets in your GitHub repository.

## Setting Up Secrets

1. Go to your GitHub repository
2. Navigate to **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. Add each secret listed below

## Required Secrets

### macOS Code Signing

#### `MACOS_CERTIFICATE_BASE64`
**Description**: Base64-encoded Developer ID Application certificate (.p12 file)

**How to get it**:
1. Export your Developer ID Application certificate from Keychain Access
2. Choose "Personal Information Exchange (.p12)" format
3. Set a password for the certificate
4. Convert to base64: `base64 -i certificate.p12 | pbcopy`

#### `MACOS_CERTIFICATE_PASSWORD`
**Description**: Password for the .p12 certificate file

**Example**: `your-certificate-password`

#### `APPLE_ID_EMAIL`
**Description**: Apple ID email for notarization

**Example**: `developer@elloloop.com`

#### `APPLE_ID_PASSWORD`
**Description**: App-specific password for Apple ID (not your regular Apple ID password)

**How to get it**:
1. Go to [appleid.apple.com](https://appleid.apple.com)
2. Sign in with your Apple ID
3. Go to "App-Specific Passwords"
4. Create a new password for "ello.AI Notarization"

#### `APPLE_TEAM_ID`
**Description**: Your Apple Developer Team ID

**How to get it**:
1. Go to [developer.apple.com](https://developer.apple.com)
2. Navigate to "Membership" in your account
3. Find your Team ID (10-character string)

**Example**: `ABCDEF1234`

### Windows Code Signing

#### `WINDOWS_CERTIFICATE_BASE64`
**Description**: Base64-encoded code signing certificate (.pfx file)

**How to get it**:
1. Export your code signing certificate as .pfx file
2. Convert to base64: `certutil -encode certificate.pfx certificate.txt` (Windows) or `base64 -i certificate.pfx | pbcopy` (macOS/Linux)

#### `WINDOWS_CERTIFICATE_PASSWORD`
**Description**: Password for the .pfx certificate file

**Example**: `your-certificate-password`

### Linux Code Signing (Optional)

#### `GPG_PRIVATE_KEY`
**Description**: Base64-encoded GPG private key for signing AppImages

**How to get it**:
1. Generate a GPG key: `gpg --full-generate-key`
2. Export private key: `gpg --armor --export-secret-keys your-email@domain.com`
3. Convert to base64: `gpg --armor --export-secret-keys your-email@domain.com | base64 | pbcopy`

#### `GPG_PASSPHRASE`
**Description**: Passphrase for the GPG private key

**Example**: `your-gpg-passphrase`

## Validation

After setting up the secrets, you can validate they work by:

1. **Testing locally** (if you have the certificates):
   ```bash
   # macOS
   ./scripts/build-macos-dmg.sh --sign "Developer ID Application"
   
   # Windows
   ./scripts/build-windows-msix.sh --sign
   
   # Linux
   ./scripts/build-linux-appimage.sh --sign
   ```

2. **Triggering a build**:
   - Push to the `main` branch
   - Check the Actions tab for build status
   - Verify signed artifacts are created

## Certificate Requirements

### macOS
- **Developer ID Application** certificate (for app signing)
- **Developer ID Installer** certificate (for DMG signing - optional)
- Certificates must be valid and not expired
- Apple Developer Program membership required

### Windows
- **Code Signing Certificate** (Extended Validation recommended)
- Certificate must be trusted by Windows
- Can be from any trusted CA (DigiCert, Sectigo, etc.)

### Linux
- **GPG Key** (any valid GPG key pair)
- Used for AppImage signature verification
- Optional but recommended for security

## Troubleshooting

### Common Issues

1. **Certificate not found**:
   - Verify the base64 encoding is correct
   - Ensure the certificate file is not corrupted
   - Check that the password matches

2. **Notarization fails**:
   - Verify Apple ID credentials are correct
   - Ensure app-specific password is used (not regular password)
   - Check that the certificate is a Developer ID Application certificate

3. **Windows signing fails**:
   - Verify the certificate is valid for code signing
   - Check that the timestamp server is accessible
   - Ensure the certificate chain is complete

4. **Build artifacts not signed**:
   - Check that all required secrets are set
   - Verify secret names match exactly (case-sensitive)
   - Review the GitHub Actions logs for error messages

### Getting Help

If you encounter issues:

1. Check the GitHub Actions logs for detailed error messages
2. Verify your certificates are valid using local tools
3. Test signing locally before pushing to CI
4. Contact the development team with specific error messages

## Security Notes

- **Never commit certificates or passwords to the repository**
- **Use app-specific passwords for Apple ID, not your main password**
- **Regularly rotate certificates and passwords**
- **Limit access to repository secrets to necessary team members**
- **Use least-privilege access for Apple ID and certificate accounts**

## Certificate Renewal

Certificates expire and need to be renewed periodically:

- **Apple Developer ID**: Valid for 5 years
- **Windows Code Signing**: Typically 1-3 years depending on provider
- **GPG Keys**: No expiration by default, but good practice to rotate

Set calendar reminders to renew certificates before they expire to avoid build failures.