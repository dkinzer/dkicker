#!/bin/bash

#  @file
#  deploy.sh
#
#  Exit status:
#    3 - Project not saved in same directory level as website

set -e
echo '*************************'
echo '*    DEPLOY CHANGES     *'
echo '*************************'

echo Initialize default configuration...
if [ ! "$PROJECT_NAME" ]; then
  PROJECT_NAME='project'
fi

if [ ! "$WEBSITE_DIR" ]; then
  WEBSITE_DIR='./../public_html'
fi

if [ ! "$DRUPAL_CORE" ]; then
  DRUPAL_CORE='drupal-7.32'
fi

if [ ! "$RETAIN_BUILDS" ]; then
  RETAIN_BUILDS='2'
fi

if [ ! "$COMMIT" ]; then
  COMMIT=$(git rev-parse HEAD)
else
  COMMIT=$(git rev-parse --verify $COMMIT)
fi

DRUPAL_DIR=./build/$DRUPAL_CORE
PROJECT_DRUPAL_DIR=$(pwd)/build/live

if [ ! -d "$DRUPAL_DIR" ]; then
  echo Build Drupal Core Version "$DRUPAL_CORE"...
  mkdir -p ./build
  drush dl --verbose --yes $DRUPAL_CORE --destination=./build
else
  echo Drupal Core already set to default: "$DRUPAL_CORE"
fi

if [ ! -d "./build/sites/$COMMIT" ]; then
  echo Build website version: $COMMIT ...
  mkdir -p ./build/sites/$COMMIT
  git archive --format=tgz $COMMIT > website-$COMMIT.tgz
  tar xvf website-$COMMIT.tgz -C ./build/sites/$COMMIT
  rm website-$COMMIT.tgz
  rm -r ./build/sites/$COMMIT/bin
  rm -r ./build/sites/$COMMIT/config
  if [ -d "./build/sites/$COMMIT/build" ]; then
    rm -r ./build/sites/$COMMIT/build
  fi
  rm -r ./build/sites/$COMMIT/patches
  rm ./build/sites/$COMMIT/Makefile
  rm ./build/sites/$COMMIT/git-push.jpg
  rm ./build/sites/$COMMIT/README.md
  rm ./build/sites/$COMMIT/LICENSE
else
  echo website already at specified version: $COMMIT
fi

if [ -d "./build/sites/$COMMIT" ]; then
  echo "Clean up old builds  (Keeping last $RETAIN_BUILDS commits)"
  (ls -d -1 -t ./build/sites/*|head -n $RETAIN_BUILDS;ls -d -1 -t ./build/sites/*)|sort|uniq -u|xargs rm -rf
fi

if [[ -d "$DRUPAL_DIR/sites" && ! -L "$DRUPAL_DIR/sites" ]]; then
  echo Remove default sites folder.
  rm -fR $DRUPAL_DIR/sites
  ln -s -f ../sites/$COMMIT $DRUPAL_DIR/sites
fi

echo Add symbolic link to website version: $COMMIT
CURRENT_WEBSITE=$(readlink "$DRUPAL_DIR/sites")

if [ "$CURRENT_WEBSITE" != "../sites/$COMMIT" ]; then
  rm -f $DRUPAL_DIR/sites
  ln -s -f ../sites/$COMMIT $DRUPAL_DIR/sites
fi

echo Add symbolic link to settings.php:
ln -s -f $(pwd)/default/settings.php $DRUPAL_DIR/sites/default/settings.php

echo Add symbolic link to files:
ln -s -f $(pwd)/default/files $DRUPAL_DIR/sites/default/files

if [ -L "./build/live" ]; then
  rm ./build/live
fi
ln -s -f ./$DRUPAL_CORE ./build/live

echo Link  website build...
if [[ -d "$WEBSITE_DIR" && ! -L "$WEBSITE_DIR" ]]; then
  mv -f $WEBSITE_DIR ${WEBSITE_DIR}~
  ln -s -f $PROJECT_DRUPAL_DIR $WEBSITE_DIR
else
 if [ -L "$WEBSITE_DIR" ]; then
    rm $WEBSITE_DIR
  fi
  ln -s -f $PROJECT_DRUPAL_DIR $WEBSITE_DIR
fi

if [ $ENV == production ] && [ -f ./default/opcache_reset.php ]; then
  echo "Clearing cache"
  wget  --bind-address 127.0.0.1 -O /dev/null $CACHE_CLEAR
fi

echo Drush specifics..
pushd $WEBSITE_DIR
if [ $(which drush 2>1) ];
then
  if [ "Successful" = "$(drush --pipe status bootstrap)" ];
  then
    drush updb --yes
    drush cc all --yes
  fi
fi
popd

echo '****************************'
echo '*  SUCCESS: Site Deployed  *'
echo '****************************'
