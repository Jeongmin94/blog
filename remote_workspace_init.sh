#!/bin/bash

echo -e "\033[0;32mInitializing remote workspcae...\033[0m"

# setting submodule
git submodule init
git submodule update

# update submoudle
# move blog/public

echo "update - blog/public"
cd public
git fetch origin
git pull origin main

# move blog

echo "update - blog"
cd ../
git fetch origin
git pull origin master
