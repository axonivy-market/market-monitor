#!/bin/bash

# Action Workflow Enabler CLI
# ===================================
# This script enables all CI+DEV action pipelines in the axonivy-market org.
# 
# Run it as follows:
# 1. lease a Github token with 'workflow' permissions:  
#    Github.com > Account > Developer Setttings > Classic Token
# 2. store the token in your terminal environment `export GH_TOKEN=ghYourToken123`
# 3. run this script `./enabler.sh`

org="axonivy-market"

ignored_repos=(
  "market-up2date-keeper"
  "market.axonivy.com"
  "market-monitor"
  "market"
)

githubRepos() {
  ghApi="https://api.github.com/orgs/${org}/repos?per_page=100"
  headers=(--header "Accept: application/vnd.github+json")
  if [ ! -z "$GH_TOKEN" ]; then
    headers+=(--header "Authorization: Bearer $GH_TOKEN")
  fi
  curl -v --url "${ghApi}" "${headers[@]}"
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
  curl -L \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer ${GH_TOKEN}" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  https://api.github.com/repos/${org}/${repo}/actions/workflows
}

wfUrl() {
  name=$1
  jq -r ".workflows[] | 
    select(.name == \"${name}\") | 
    select(.state != \"active\") |
      .url"
}

enableWfs() {
  if [[ " ${ignored_repos[@]} " =~ " $1 " ]]; then
    return
  fi
  repo=$1
  echo "processing ${repo}"
  workflows=$(workflows ${repo})
  ciUri=$(echo $workflows | wfUrl "CI-Build")
  enable $ciUri
  devUri=$(echo $workflows | wfUrl "Dev-Build")
  enable $devUri
}

enable() {
  wfUri=$1
  echo "enabling: $wfUri"
  curl -L \
  -X PUT \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer ${GH_TOKEN}" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  ${wfUri}/enable
}

enableAll
