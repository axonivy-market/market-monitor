#!/bin/bash

# Action Workflow Enabler CLI
# ===================================
# This script enables all CI+DEV action pipelines in the axonivy-market org.
# Using https://cli.github.com/

org="axonivy-market"

ignored_repos=(
  "market-up2date-keeper"
  "market.axonivy.com"
  "market-monitor"
  "market"
)

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

enableAll() {
  echo "enabling repos actions on ${org}"
  collectRepos |
  while read repo_name; do
    enableWfs $repo_name
  done
}

workflows() {
  repo=$1
  wfName=$2
  gh api "repos/${org}/${repo}/actions/workflows"
}

enableWfs() {
  if [[ " ${ignored_repos[@]} " =~ " $1 " ]]; then
    return
  fi
  repo=$1
  where="${org}/${repo}"
  echo "processing $where"
  gh workflow enable -R "$where" ci.yml
  gh workflow enable -R "$where" dev.yml
}

enableAll
