#!/bin/bash

echo -e "\033[0;32mDeploying updates to GitHub...\033[0m"

# Params
type=$1
message=$2
date=`date`

commitMsg="${type} ${message}, ${date}"
if [ $# -eq 0 ]
    then commitMsg="update blog at ${date}"
fi

echo -e $commitMsg
echo $#

# Build the project.
hugo -t bh

### Public
cd public

git add .
git commit -m "$commitMsg"

git push origin main


### Root
cd ..

git add .
git commit -m "$commitMsg"

git push origin master