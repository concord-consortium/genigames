#!/bin/sh

export GIT_REMOTE=origin

if [ -x $1 ]; then
  echo "You must specify which server to install to.\nSupported servers: production, dev\n\nUsage: $0 [server]"
  exit 1
fi

case "$1" in
  heroku)
    export DEPLOY_TYPE=heroku
    export DEPLOY_BRANCH="heroku-dev"
    ;;
  dev)
    export DEPLOY_TYPE=ssh_git
    export SERVER=genigames.dev.concord.org
    export SERVER_PATH="/var/www/public/"
    export DEPLOY_BRANCH="deploy-dev"
    export PUSH_REFSPEC="$DEPLOY_BRANCH"
    ;;
  staging)
    export DEPLOY_TYPE=ssh_git
    export SERVER=genigames.staging.concord.org
    export SERVER_PATH="/var/www/public/"
    export DEPLOY_BRANCH="deploy-staging"
    export PUSH_REFSPEC="$DEPLOY_BRANCH"
    ;;
  production)
    export DEPLOY_TYPE=ssh_git
    export SERVER=genigames.concord.org
    export SERVER_PATH="/var/www/public/"
    export DEPLOY_BRANCH="deploy-production"
    export PUSH_REFSPEC="$DEPLOY_BRANCH"
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
export ORIGINAL_BRANCH=`git symbolic-ref HEAD 2>/dev/null | cut -d"/" -f 3`

echo "changing to toplevel directory"
cd $(git rev-parse --show-toplevel)

echo "Updating bundles"
bundle install

echo "Building application... "
rm -rf build
bundle exec rakep build

echo "Updating deploy branch"

git checkout $DEPLOY_BRANCH
git pull origin $DEPLOY_BRANCH
rm -rf static
cp -r build static

git add -A static
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
case "$DEPLOY_TYPE" in
  heroku)
    git push heroku $DEPLOY_BRANCH:master
    ;;
  ssh_git)
    ssh deploy@$SERVER "cd $SERVER_PATH; git pull"
    ;;
  *)
    echo "Invalid deploy type: $DEPLOY_TYPE"
    exit 1
    ;;
esac

echo "Switching back to original branch and working directory"
git checkout $ORIGINAL_BRANCH
