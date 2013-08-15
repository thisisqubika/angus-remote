#!/usr/bin/env bash

load() {
  URL="https://raw.github.com/gist/3715020/5d78385a21487d4cae66f5406483c2539e933ca0/conditions.sh"
  TMP_FILE="/tmp/5d78385a21487d4cae66f5406483c2539e933ca0_conditions.sh"
  [ -f "$TMP_FILE" ] ||
    curl "$URL" 2>/dev/null -o "$TMP_FILE"
  source "$TMP_FILE"
}; load

req_exec "gem"
req_exec "bundle" gem install bundler

run bundle install

req_exec rspec

run bundle exec rake -f Rakefile_CI ci:setup:rspec spec