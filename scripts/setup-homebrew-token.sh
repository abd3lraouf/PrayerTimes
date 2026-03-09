#!/bin/bash
# Creates a GitHub PAT with repo scope and sets it as a secret
# on the PrayerTimes repo for the Homebrew cask auto-update.
#
# Prerequisites: gh CLI authenticated with your account

set -euo pipefail

REPO="abd3lraouf/PrayerTimes"
TOKEN_NOTE="homebrew-prayertimes-tap-token"

echo "==> Creating GitHub PAT with repo scope..."
TOKEN=$(gh auth token 2>/dev/null || true)

if [ -z "$TOKEN" ]; then
  echo "Error: Not authenticated with gh CLI. Run 'gh auth login' first."
  exit 1
fi

# Create a fine-grained PAT via the API
echo "==> Creating fine-grained personal access token..."
echo ""
echo "gh CLI cannot create PATs directly. Opening GitHub in your browser."
echo ""
echo "Create a token with these settings:"
echo "  1. Name: ${TOKEN_NOTE}"
echo "  2. Expiration: 1 year (or no expiration)"
echo "  3. Repository access: Only select repositories → homebrew-prayertimes"
echo "  4. Permissions: Contents → Read and write"
echo ""

open "https://github.com/settings/personal-access-tokens/new"

echo "After creating the token, paste it here:"
read -rsp "Token: " NEW_TOKEN
echo ""

if [ -z "$NEW_TOKEN" ]; then
  echo "Error: No token provided."
  exit 1
fi

echo "==> Setting HOMEBREW_TAP_TOKEN secret on ${REPO}..."
gh secret set HOMEBREW_TAP_TOKEN --repo "$REPO" --body "$NEW_TOKEN"

echo "==> Done! HOMEBREW_TAP_TOKEN is set on ${REPO}."
echo "    The release workflow will now auto-update the Homebrew cask."
