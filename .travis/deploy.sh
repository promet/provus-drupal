#!/usr/bin/env bash

quiet_git() {
  stdout=$(tempfile)
  stderr=$(tempfile)

  if ! git "$@" </dev/null >$stdout 2>$stderr; then
      cat $stderr >&2
      rm -f $stdout $stderr
      exit 1
  fi

  rm -f $stdout $stderr
}

# #If not the defined branch - IE: PR submissions.. create a new MD and push there... ya? 

# echo "Logging into Terminus"
$TERMINUS_BIN auth:login --machine-token=$SECRET_TERMINUS_TOKEN
$TERMINUS_BIN connection:set $PANTHEON_SITE_ID.$PANTHEON_ENV git

echo "Add pantheon repo"
git remote add pantheon $PANTHEON_REPO

# echo "Waking Pantheon $PANTHEON_SITE_ID Dev environment."
$TERMINUS_BIN env:wake -n $PANTHEON_SITE_ID.$PANTHEON_ENV

echo "...Run composer install"
composer install

if [ "$CURRENT_BRANCH" != "$PANTHEON_ENV" ]; then
    # if [ `git branch --list $branch_name` ]
    # then
    # echo "Branch name $branch_name already exists."
    # fi
  echo "...Pushing code to pantheon repo"


  echo "...Building Mutlidev"
  $TERMINUS_BIN multidev:create $PANTHEON_SITE_ID.$PANTHEON_ENV ci-$TRAVIS_PULL_REQUEST --yes

  quiet_git checkout ci-$TRAVIS_PULL_REQUEST
  quiet_git add -f vendor web
  quiet_git commit -m "Artifacts for build ci-$TRAVIS_PULL_REQUEST"
  git push pantheon ci-$TRAVIS_PULL_REQUEST
 
 #determine if develop branch and merge from what PR ID
 #$TERMINUS_BIN multidev:delete $PANTHEON_SITE_ID.ci-$SOME_PR_ID --delete-branch
else 
  quiet_git checkout $PANTHEON_ENV
  quiet_git add -f vendor web
  quiet_git commit -m "TRAVIS JOB: $TRAVIS_JOB_ID - $TRAVIS_COMMIT_MESSAGE"
  git push pantheon $PANTHEON_ENV
fi

 

# echo "Setting site to git mode."
# $TERMINUS_BIN connection:set $PANTHEON_SITE_ID.$PANTHEON_ENV git

# echo "Add pantheon repo"
# git remote add pantheon $PANTHEON_REPO

# echo "Changing to develop branch"
# git checkout $PANTHEON_ENV

# echo "Set git to REBfast forwardASE"
# git config pull.ff only

# echo "Pull in from Pantheon"
# # git pull pantheon develop

# echo "run composer install"
# composer install

# echo "Force add web and vendor directories"
#  quiet_git  add --force -A web/* 
#  quiet_git  add --force -A vendor/*

# echo "Sync with Pantheon site " $PANTHEON_SITE_ID
#  quiet_git  pull pantheon $PANTHEON_ENV
#  quiet_git  commit -m "Build for $1"
# git push pantheon $PANTHEON_ENV

# echo "Import config"
# if [ -z "$(ls -A /config/default)" ]; then
#  echo "Nothing to import"
# else
#   $TERMINUS_BIN drush -n $PANTHEON_SITE_ID.$PANTHEON_ENV cim -y
# fi
# echo "Running Updates"
# $TERMINUS_BIN drush -n $PANTHEON_SITE_ID.$PANTHEON_ENV -- updatedb -y