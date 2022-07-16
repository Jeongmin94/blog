#!/bin/bash

echo -e "\033[0;32mDeploying updates to GitHub...\033[0m"

# Params
type=$0
message=$1
date=`date`

echo -e "${type} - ${message}, ${date}"

# Build the project.
hugo -t bh

### Public

# Go To Public folder
cd public
# Add changes to git.
git add .

# Commit changes.
msg="rebuilding site `date`"
if [ $# -eq 1 ]
  then msg="$1"
fi
git commit -m "$msg"

# Push source and build repos.
## master 대신 각자 연결한 branch 명으로 수정하면 된다.
git push origin main


### Root
# Come Back up to the Project Root
cd ..

# blog 저장소 Commit & Push
git add .

msg="rebuilding site `date`"
if [ $# -eq 1 ]
  then msg="$1"
fi
git commit -m "$msg"

## master 대신 각자 연결한 branch 명으로 수정하면 된다.
git push origin master