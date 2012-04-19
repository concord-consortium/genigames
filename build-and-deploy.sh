#!/bin/sh

export GIT_REMOTE=origin

if [ -x $1 ]; then
  echo "You must specify which server to install to.\nSupported servers: production, dev\n\nUsage: $0 [server]"
  exit 1
fi

case "$1" in
  # production)
  # export SERVER=genigames.concord.org
  # export SERVER_PATH="/var/www/"
  # export DEPLOY_BRANCH="deploy-production"
  #   ;;
  dev)
    export SERVER=genigames.dev.concord.org
    export SERVER_PATH="/var/www/"
    export DEPLOY_BRANCH="deploy-dev"
    ;;
  *)
    echo "Invalid server!"
    exit 1
    ;;
esac

git diff --exit-code > /dev/null && git diff --staged --exit-code > /dev/null
if [[ $? != 0 ]] ; then
    echo "There are uncommitted changes to the git repo! git status:"
    git status
    exit 1
fi

export COMMIT=`git log -1 --format=%H`
export ORIGINAL_DIR=`pwd`
export ORIGINAL_BRANCH=`git status -sb -uno | cut -d" " -f2`

echo "changing to toplevel directory"
cd $(git rev-parse --show-toplevel)

echo "Updating bundles"
bundle install

echo "Building application... "
rm -rf build
bundle exec rakep build

echo "Updating deploy branch"

git checkout $DEPLOY_BRANCH
rm -rf static
cp -r build static

git add static
git commit -m "$COMMIT"

git diff --exit-code > /dev/null && git diff --staged --exit-code > /dev/null
if [[ $? != 0 ]] ; then
    echo "There is a problem in the deploy branch! git status:"
    git status
    exit 1
fi

echo "Pushing branch"
git push $GIT_REMOTE $DEPLOY_BRANCH
if [[ $? != 0 ]] ; then
    echo "There was a problem pushing the commit!"
    exit 1
fi

echo "Updating on server"
ssh deploy@$SERVER "cd $SERVER_PATH; git pull"

echo "Switching back to original branch and working directory"
git checkout $ORIGINAL_BRANCH
