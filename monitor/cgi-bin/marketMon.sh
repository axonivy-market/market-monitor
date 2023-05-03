#!/bin/bash

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
  collectRepos |
  while read repo_name; do
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
  actionsUri="https://github.com/${org}/${repo}/actions"
  ciBadge=$(badge ${actionsUri}/workflows/ci.yml)
  devBadge=$(badge ${actionsUri}/workflows/dev.yml)
  echo "<li>${ciBadge}${devBadge} <a href='${actionsUri}'>${repo}</a></li>"
}

page() {
  title="Action Monitor 4"
  head="<link type='text/css' rel='stylesheet' href='/monitor.css'>"
  head+="<link rel='icon' href='https://avatars.githubusercontent.com/u/65916846?v=4'>"
  echo "<!DOCTYPE html><html><head><title>${title} ${org}</title>${head}</head>"
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
  echo "Content-type: text/html"
  echo ""
  page
}