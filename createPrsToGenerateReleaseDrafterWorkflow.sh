#!/bin/bash

# Release Drafter Workflow Creator CLI
# ===================================
# This script creates pull requests to add a Release Drafter workflow to each repository
# in the axonivy-market GitHub Organization.
# Using https://cli.github.com/

org="axonivy-market"

ignored_repos=(
  "market-up2date-keeper"
  "market.axonivy.com"
  "market-monitor"
  "market"
  "demo-projects"
)

workflow_file=".github/workflows/release-drafter.yml"
workflow_content='name: Release Drafter

on:
  push:
    branches:
      - master
  pull_request:
    types: [opened, reopened, synchronize]
  workflow_dispatch:

jobs:
  build:
    uses: axonivy-market/github-workflows/.github/workflows/release-drafter.yml@v4'

githubRepos() {
  ghApi="orgs/${org}/repos?per_page=100"
  gh api "${ghApi}"
}

githubReposC(){
  cache="/tmp/gh-${org}.json"
  if [ ! -f "${cache}" ]; then
    githubRepos > "${cache}"
  fi
  cat "${cache}"
}

collectRepos() {
  githubReposC | 
    jq -r '.[] | 
    select(.archived == false) | 
    select(.is_template == false) | 
    select(.default_branch == "master") | 
    select(.language != null) | 
      .name'
}

create_pr() {
  repo_name=$1
  echo "Processing repository $repo_name"
  
  if [[ " ${ignored_repos[@]} " =~ " ${repo_name} " ]]; then
    echo "Ignoring repo ${repo_name}"
    return
  fi

  git clone "https://github.com/${org}/${repo_name}.git"
  cd "${repo_name}"

  # Create a new branch
  branch_name="feature/MARP-620-Add-release-drafter-workflow"
  git checkout -b "$branch_name"

  # Create the .github/workflows directory if it doesn't exist
  mkdir -p .github/workflows

  # Add the workflow file
  echo "$workflow_content" > $workflow_file

  # Commit the changes
  git add .github/workflows/release-drafter.yml
  git commit -m "Add release-drafter workflow"

  # Push the branch
  git push origin "$branch_name"

  # Create a pull request
  pr_title="MARP-620 Add release-drafter workflow"
  gh pr create --title "$pr_title" --body "This PR adds the Release Drafter workflow to the repository." --base master --head "$branch_name"

  # Return to the original directory
  cd ..
  rm -rf "${repo_name}"
}

main() {
  echo "Repositories found:"
  collectRepos | while read -r repo_name; do
    create_pr "$repo_name"
  done
}

main