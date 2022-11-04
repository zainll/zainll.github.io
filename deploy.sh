#!/usr/bin/env bash
# Filename: deploy.sh
#

#### Action 1 ####

echo -e "
===========Building web pages... [HTML]==============="
# Build the project.
#hugo --config ./config/_default/config.toml --gc --minify
hugo -F --cleanDestinationDir

#### Action 2 ####

echo -e "
++++++++++++++++Upload the HUGO site...++++++++++++++
"
# ----------------------------------------------
# Add changes to git.
git status
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
-----------Upload pages to CODING... [HTML]----------
"
# Go To Repository folder
cd public
# ----------------------------------------------
# Add changes to git.
git status
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

echo -e "
===========Upload Successful [HTML]===========
"
