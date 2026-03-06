# Release Process Documentation

## Overview

PrayerTimes uses automated GitHub Actions workflows for building and releasing the app. This document explains how the release process works and how to create new releases.

## Version Management

### Current Version
- **Version**: 1.0.0
- **Build Number**: Incremented automatically by GitHub Actions

### Updating Version Numbers

Use the provided script to update version numbers across all files:

```bash
./scripts/bump-version.sh <version> [build_number]
```

Example:
```bash
./scripts/bump-version.sh 1.1.0 2
```

This updates:
- `PrayerTimes/Info.plist` (CFBundleShortVersionString and CFBundleVersion)
- `PrayerTimes.xcodeproj/project.pbxproj` (MARKETING_VERSION and CURRENT_PROJECT_VERSION)

## Creating a Release

### Automated Release (Recommended)

1. **Update version and changelog**:
   ```bash
   # Update version
   ./scripts/bump-version.sh 1.1.0
   
   # Update CHANGELOG.md with your changes
   # Commit changes
   git add .
   git commit -m "Bump version to 1.1.0"
   git push
   ```

2. **Create and push a tag**:
   ```bash
   git tag -a v1.1.0 -m "Release version 1.1.0"
   git push origin v1.1.0
   ```

3. **GitHub Actions will automatically**:
   - Build the app
   - Create a DMG installer
   - Generate SHA256 checksum
   - Create a GitHub Release
   - Upload the DMG and checksum

4. **Monitor the build**:
   - Visit: https://github.com/abd3lraouf/PrayerTimes/actions
   - Look for the "Release" workflow

5. **Edit the release** (optional):
   - Go to: https://github.com/abd3lraouf/PrayerTimes/releases
   - Click "Edit" on the new release
   - Add detailed release notes
   - Mark as pre-release if needed

### Manual Release (Testing)

For local testing without GitHub Actions:

```bash
./scripts/build-dmg.sh 1.0.0 1
```

This creates:
- `release/PrayerTimes-1.0.0.dmg`
- `release/PrayerTimes-1.0.0.dmg.sha256`

## GitHub Actions Workflow

### Trigger
The workflow is triggered when you push a tag starting with `v`:
- `v1.0.0` ✅
- `v1.1.0-beta` ✅
- `v2.0.0-rc1` ✅

### Build Process
1. **Checkout** code
2. **Setup Xcode** 15.0
3. **Extract version** from tag
4. **Update Info.plist** with version and build number
5. **Build app** (unsigned, for distribution)
6. **Create DMG** installer
7. **Generate checksum**
8. **Create GitHub Release**
9. **Upload artifacts**

### Build Configuration
- **Configuration**: Release
- **Code Signing**: Disabled (uses `-` identity)
- **Sandbox**: Enabled (from entitlements)
- **Architecture**: Universal (Intel + Apple Silicon)

## Release Checklist

Before creating a release:

- [ ] Update version number with `./scripts/bump-version.sh`
- [ ] Update `CHANGELOG.md` with changes
- [ ] Test build locally: `./scripts/build-dmg.sh <version>`
- [ ] Commit all changes
- [ ] Push commits to GitHub
- [ ] Create and push tag
- [ ] Monitor GitHub Actions build
- [ ] Review release on GitHub
- [ ] Update release notes if needed
- [ ] Test DMG download and installation

## Version Numbering

We follow [Semantic Versioning](https://semver.org/):

- **MAJOR** (X.0.0): Breaking changes
- **MINOR** (1.X.0): New features, backward compatible
- **PATCH** (1.0.X): Bug fixes, backward compatible

Examples:
- `1.0.0` → `1.0.1`: Bug fix release
- `1.0.1` → `1.1.0`: New feature release
- `1.1.0` → `2.0.0`: Breaking changes

## Troubleshooting

### Build Fails
1. Check GitHub Actions logs
2. Test build locally with `./scripts/build-dmg.sh`
3. Ensure Xcode project builds successfully
4. Check for missing dependencies

### DMG Creation Fails
1. Install `create-dmg`: `brew install create-dmg`
2. Test locally first
3. Check file permissions

### Code Signing Issues
The workflow builds unsigned apps. For signed releases:
1. Add signing certificates to GitHub Secrets
2. Update workflow to use signing identity
3. Enable notarization

## Distribution

### Unsigned App (Current)
- Users must right-click → Open on first launch
- macOS will show security warning
- Users must approve in System Settings

### Signed App (Future)
- Requires Apple Developer account
- Code signing certificate needed
- Notarization required for distribution
- No security warnings for users

## Files and Locations

- **Workflow**: `.github/workflows/release.yml`
- **Build Script**: `scripts/build-dmg.sh`
- **Version Script**: `scripts/bump-version.sh`
- **Changelog**: `CHANGELOG.md`
- **Info.plist**: `PrayerTimes/Info.plist`
- **Project**: `PrayerTimes.xcodeproj`
- **Releases**: https://github.com/abd3lraouf/PrayerTimes/releases
- **Actions**: https://github.com/abd3lraouf/PrayerTimes/actions

## Support

For issues with releases:
1. Check GitHub Actions logs
2. Review this documentation
3. Open an issue on GitHub
4. Check existing issues for solutions
