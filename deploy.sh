#!/usr/bin/env bash
# Filename: deploy.sh
#

#### Action 1 ####

echo -e "
33[0;34;1m1) Building web pages... [HTML]33[0m"
# Build the project.
#hugo --config ./config/_default/config.toml --gc --minify
hugo -F --cleanDestinationDir

#### Action 2 ####

echo -e "
33[0;32;1m3) Upload the HUGO site...33[0m
"
# ----------------------------------------------
# Add changes to git.
git add .
# Commit changes.
msg="Update $(date +"[%x %T]")"
if [ -n "$*" ]; then
    msg="$*"
fi
git commit -m "$msg"
# Push source and build repos.
git push origin br_hugo
# ----------------------------------------------


#### Action 3 ####

echo -e "
33[0;32;1m2) Upload pages to CODING... [HTML]33[0m
"
# Go To Repository folder
cd public
# ----------------------------------------------
# Add changes to git.
git add .
# Commit changes.
msg="Update $(date +"[%x %T]")"
if [ -n "$*" ]; then
    msg="$*"
fi
git commit -m "$msg"
# Push source and build repos.
git push origin master
# ----------------------------------------------
# Come Back up to the Project Root
cd ..


