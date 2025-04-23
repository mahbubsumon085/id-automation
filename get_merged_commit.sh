#!/bin/bash

# Usage: ./get_merged_commit.sh <github_pr_url>
# Example: ./get_merged_commit.sh https://github.com/apache/commons-lang/pull/123

# GitHub Personal Access Token (don't commit this to version control)
PR_URL="$1"

if [ -z "$PR_URL" ]; then
    echo "Usage: $0 <github_pr_url>"
    exit 1
fi

# Extract owner, repo, and PR number
if [[ "$PR_URL" =~ github.com/([^/]+)/([^/]+)/pull/([0-9]+) ]]; then
    OWNER="${BASH_REMATCH[1]}"
    REPO="${BASH_REMATCH[2]}"
    PR_NUMBER="${BASH_REMATCH[3]}"
else
    echo "Error: Invalid PR URL format."
    exit 1
fi

# GitHub API URL for the pull request
API_URL="https://api.github.com/repos/$OWNER/$REPO/pulls/$PR_NUMBER"

# Make the authenticated API request
RESPONSE=$(curl -s \
  -H "Authorization: token $GITHUB_TOKEN" \
  -H "Accept: application/vnd.github.v3+json" \
  "$API_URL")

# Check for API errors
if echo "$RESPONSE" | grep -q "API rate limit exceeded"; then
    echo "Error: GitHub API rate limit exceeded (even with token)"
    exit 1
elif echo "$RESPONSE" | grep -q "Not Found"; then
    echo "Error: Repository or PR not found (or no access)"
    exit 1
elif echo "$RESPONSE" | grep -q "Bad credentials"; then
    echo "Error: Invalid GitHub token"
    exit 1
fi

# Extract merged commit SHA
MERGED_SHA=$(echo "$RESPONSE" | grep '"merge_commit_sha":' | cut -d '"' -f4)

if [ -n "$MERGED_SHA" ] && [ "$MERGED_SHA" != "null" ]; then
    echo "$MERGED_SHA"
else
    echo "Pull request #$PR_NUMBER is not merged or no SHA found." >&2
    exit 1
fi