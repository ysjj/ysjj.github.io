#!/bin/bash

GITHUB_REPO_NWO=$(git -C "$PUBLISHING_SOURCE" remote -v | sed -ne 's,^origin\s*https://github\.com/\(.*\)\.git\s*(fetch)$,\1,p')

cd
exec env PAGES_REPO_NWO=$GITHUB_REPO_NWO \
  bundle exec jekyll "$@" \
                      --source      "$PUBLISHING_SOURCE" \
                      --destination "$PUBLISHING_SOURCE/_site"

