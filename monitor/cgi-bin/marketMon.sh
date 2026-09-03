#!/bin/bash

org="axonivy-market"

ignored_repos=(
  "market-up2date-keeper"
  "market.axonivy.com"
  "market-monitor"
  "market"
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

  collectRepos |
  while read repo_name; do
    if [[ " ${focused_repos[*]} " == *" $repo_name "* ]]; then
      continue
    fi
    status $repo_name
  done
}

badge() {
  build=$1
  badge="${build}/badge.svg"
  echo "<a href='${build}'><img src='${badge}' onerror='this.style.display=\"none\"'/></a>"
}

status() {
  if [[ " ${ignored_repos[@]} " =~ " $1 " ]]; then
    return
  fi
  repo=$1
  focusIcon=""
  if [[ " ${focused_repos[*]} " == *" $repo "* ]]; then
    focusIcon="🎯️"
  fi
  repoUri="https://github.com/${org}/${repo}"
  actionsUri="${repoUri}/actions"
  ciBadge=$(badge ${actionsUri}/workflows/ci.yml)
  devBadge=$(badge ${actionsUri}/workflows/dev.yml)
  e2eBadge=$(badge ${actionsUri}/workflows/e2e.yml)
  echo "<li>${ciBadge}${devBadge}${e2eBadge} <a href='${actionsUri}'>${repo}${focusIcon}</a></li>"
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