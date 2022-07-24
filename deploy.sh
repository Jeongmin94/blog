#!/bin/bash

echo -e "\033[0;32mDeploying updates to GitHub...\033[0m"
echo "$#"

# Params
type=$1
message=$2
date=`date`

commitMsg="${type} ${message}, ${date}"
if [ $# -eq 0 ]
    then commitMsg="update blog at ${date}"
fi

echo -e $commitMsg

# Build the project.
hugo -t bh

### Public
cd public

echo "push to Public"
git add .
git commit -m "$commitMsg"

git push origin main


### Root
echo "push to Blog"
cd ..

git add .
git commit -m "$commitMsg"

git push origin master
