#!/bin/bash

org="axonivy-market"

ignored_repos=(
  "market-up2date-keeper"
  "market.axonivy.com"
  "market-monitor"
  "market"
  "github-repo-manager"
)

focused_repos=(
  "smart-workflow"
  "persistence-utils"
  "docuware-connector"
  "doc-factory"
  "portal"
  "pattern-demos"
  "msgraph-connector"
  "idp-utils"
  "docusign-connector"
  "deepl-connector"
  "db-utils"
  "mailstore-utils"
)

devBranch="dev/14.0"
dev_master=(
  "smart-workflow"
)

githubRepos() {
  ghApi="https://api.github.com/orgs/${org}/repos?per_page=100"
  headers=(--header "Accept: application/vnd.github+json")
  if [ ! -z "$GH_TOKEN" ]; then
    headers+=(--header "Authorization: Bearer $GH_TOKEN")
  fi
  curl --url "${ghApi}" "${headers[@]}"
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

print() {
  for repo_name in "${focused_repos[@]}"; do
    status "$repo_name"
  done
  collectRepos | sort |
  while read -r repo_name; do
    if [[ " ${focused_repos[*]} " == *" $repo_name "* ]]; then
      continue
    fi
    status "$repo_name"
  done
}

badge() {
  local build=$1
  local branch=${2:-master}
  local badge="${build}/badge.svg?branch=${branch}&refresh=$(date -u +%Y%m%d%H)"
  echo "<a href='${build}'><img src='${badge}' onerror='this.style.display=\"none\"'/></a>"
}

status() {
  if [[ " ${ignored_repos[@]} " =~ " $1 " ]]; then
    return
  fi
  local repo=$1
  local focusIcon=""
  local repoClass=""
  if [[ " ${focused_repos[*]} " == *" $repo "* ]]; then
    focusIcon=" ⭐️"
    repoClass=" class='focused'"
  fi
  local repoUri="https://github.com/${org}/${repo}"
  local actionsUri="${repoUri}/actions"
  local ciBadge=$(badge ${actionsUri}/workflows/ci.yml)
  local repoDevBranch="${devBranch}"
  if [[ " ${dev_master[*]} " == *" $repo "* ]]; then
    repoDevBranch="master"
  fi
  local devBadge=$(badge ${actionsUri}/workflows/dev.yml "${repoDevBranch}")
  local e2eBadge=$(badge ${actionsUri}/workflows/e2e.yml)
  echo "<li${repoClass}><a href='${repoUri}'>${repo}${focusIcon}</a> ${ciBadge}${devBadge}${e2eBadge}</li>"
}

page() {
  title="Action Monitor 4"
  head="<link type='text/css' rel='stylesheet' href='/monitor.css'>"
  head+="<link rel='icon' href='https://avatars.githubusercontent.com/u/65916846?v=4'>"
  echo "<!DOCTYPE html><html><head><meta charset='UTF-8'><title>${title} ${org}</title>${head}</head>"
  echo "<body>"
  echo "<h3>${title} <a href='https://github.com/${org}'>${org}</a></h3>"
  echo "<div class='github-ribbon'><a target='_blank' href='https://github.com/axonivy-market/market-monitor'>Fork me on GitHub</a></div>"
  echo "<ul>"
  print
  echo "</ul>"
  echo "</body>"
  echo "</html>"
}

localFile() {
  html="/tmp/marketmon.html"
  if [ ! -z "$1" ]; then
    html="$1"
  fi
  page > $html
}

localPage() {
  echo "Content-type: text/html; charset=UTF-8"
  echo ""
  page
}