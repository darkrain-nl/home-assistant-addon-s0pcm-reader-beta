#!/bin/bash
set -e

# S0PCM Reader Release Script
# Automates the dev -> beta release cycle.

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Starting release process...${NC}"

# 1. Safety Checks
CURRENT_BRANCH=$(git branch --show-current)
if [ "$CURRENT_BRANCH" != "dev" ]; then
    echo -e "${RED}Error: You must be on the 'dev' branch to start a release.${NC}"
    exit 1
fi

if [[ -n $(git status --porcelain) ]]; then
    echo -e "${RED}Error: You have uncommitted changes. Please commit or stash them first.${NC}"
    exit 1
fi

# 2. Push Dev
echo -e "${YELLOW}Pushing latest 'dev' changes to origin...${NC}"
git push origin dev

# 3. Beta Merge
echo -e "${YELLOW}Switching to 'beta' and merging 'dev'...${NC}"
git checkout beta
git pull origin beta
git merge dev --no-edit

# 4. Push Beta
echo -e "${YELLOW}Pushing to 'beta' to trigger CI release...${NC}"
git push origin beta

# 5. Wait for CI
echo -e "${YELLOW}Waiting for GitHub Actions release pipeline to start...${NC}"
sleep 10 # Give the API a moment to register the new run

RUN_ID=$(gh run list --branch beta --workflow "Tests" --limit 1 --json databaseId,status --jq 'if .[0].status == "queued" or .[0].status == "in_progress" or .[0].status == "waiting" then .[0].databaseId else empty end')

if [ -z "$RUN_ID" ]; then
    echo -e "${YELLOW}Could not find an active 'Tests' run for beta. It might have finished very quickly or haven't started yet.${NC}"
    echo -e "${YELLOW}Attempting to watch the latest run regardless...${NC}"
    RUN_ID=$(gh run list --branch beta --workflow "Tests" --limit 1 --json databaseId --jq '.[0].databaseId')
fi

echo -e "${GREEN}Watching CI Run: https://github.com/darkrain-nl/home-assistant-addon-s0pcm-reader/actions/runs/$RUN_ID${NC}"
gh run watch "$RUN_ID"

# 6. Sync Beta
echo -e "${YELLOW}CI finished. Pulling latest 'beta' changes (including CI updates)...${NC}"
git pull origin beta

# 7. Sync Dev
echo -e "${YELLOW}Switching back to 'dev' and pulling CI sync-back...${NC}"
git checkout dev
git pull origin dev

echo -e "${GREEN}Release process complete!${NC}"
