#!/bin/bash
hugo -F --cleanDestinationDir
git status
git add .
git commit -m "source"
git push
cd public
git status
git add .
git commit -m "public"
git push -u origin/master --force

