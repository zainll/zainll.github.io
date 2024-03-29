#!/usr/bin/env bash
# Filename: deploy.sh
#

#### Action 1 ####

echo -e "
===========Building web pages... [HTML]==============="
# Build the project.
#hugo --config ./config/_default/config.toml --gc --minify
hugo -F --cleanDestinationDir --panicOnWarning

#### Action 2 ####

echo -e "
++++++++++++++++Upload the HUGO br_hugo site...++++++++++++++
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
echo -e "
++++++++++++++++Upload HUGO br_hugo end...++++++++++++++
"

#### Action 3 ####

echo -e "
-----------Upload pages to master CODING... [HTML]----------
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
#git push origin master 
git push -u origin master --force 
# ----------------------------------------------
# Come Back up to the Project Root
cd ..

echo -e "
===========Upload Successful [HTML]===========
"
