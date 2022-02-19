#!/usr/bin/env bash
CURRENT_BRANCH=`git name-rev --name-only HEAD`
TERMINUS_BIN=scripts/bin/terminus

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

echo "Logging into Terminus"
$TERMINUS_BIN auth:login --machine-token=$SECRET_TERMINUS_TOKEN
$TERMINUS_BIN connection:set $PANTHEON_SITE_ID.$PANTHEON_ENV git

echo "Add pantheon repo"
git remote add pantheon $PANTHEON_REPO

echo "Waking Pantheon $PANTHEON_SITE_ID Dev environment."
$TERMINUS_BIN env:wake -n $PANTHEON_SITE_ID.$PANTHEON_ENV

echo "...Run composer install"
composer install

echo "..remove .git dir from menu_block module"
rm -rf web/modules/contrib/menu_block/.git

if [ "$CURRENT_BRANCH" != "$PANTHEON_ENV" ]; then
    # if [ `git branch --list $branch_name` ]
    # then
    # echo "Branch name $branch_name already exists."
    # fi

  echo "...Building Mutlidev ci-$TRAVIS_PULL_REQUEST"
  echo "... delete MD if it already exists"
  $TERMINUS_BIN multidev:delete $PANTHEON_SITE_ID.ci-$TRAVIS_PULL_REQUEST --delete-branch --yes
  $TERMINUS_BIN multidev:create $PANTHEON_SITE_ID.$PANTHEON_ENV ci-$TRAVIS_PULL_REQUEST --yes

  cp hosting/pantheon/* .
  echo "...switch to new ci-$TRAVIS_PULL_REQUEST branch locally"
  git checkout -b ci-$TRAVIS_PULL_REQUEST
  echo "...add the new files"
  quiet_git add -f vendor/* web/* pantheon*
  quiet_git commit -m "Artifacts for build ci-$TRAVIS_PULL_REQUEST"
  echo "...push to pantheon"
  git push pantheon ci-$TRAVIS_PULL_REQUEST --force
  P_ENV="ci-$TRAVIS_PULL_REQUEST"
  sleep 60
else 
  echo "...copy pantheon files to root"
  cp hosting/pantheon/* .
  git checkout $PANTHEON_ENV
  quiet_git add -f vendor web pantheon*
  quiet_git commit -m "TRAVIS JOB: $TRAVIS_JOB_ID - $TRAVIS_COMMIT_MESSAGE"
  git push pantheon $PANTHEON_ENV --force
  P_ENV = $PANTHEON_ENV
fi

#$TERMINUS_BIN drush -n $PANTHEON_SITE_ID.$P_ENV cim -y
$TERMINUS_BIN drush -n $PANTHEON_SITE_ID.$P_ENV updb -y
