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
  DRUPAL_CORE='drupal-7.31'
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
  rm ./build/sites/$COMMIT/Makefile
else
  echo website already at specified version: $COMMIT
fi

if [ -d "./build/sites/$COMMIT" ]; then
  echo "Clean up old builds  (Keeping last 5 commits)"
  (ls -d -1 -t ./build/sites/*|head -n 5;ls -d -1 -t ./build/sites/*)|sort|uniq -u|xargs rm -rf
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

rm -f ./build/live
ln -s -f ./$DRUPAL_CORE ./build/live

echo Link  website build...
if [[ -d "$WEBSITE_DIR" && ! -L "$WEBSITE_DIR" ]]; then
  mv -f $WEBSITE_DIR ${WEBSITE_DIR}~
  ln -s -f $PROJECT_DRUPAL_DIR $WEBSITE_DIR
else
  if [[ -L "$WEBSITE_DIR" ]]; then
    rm $WEBSITE_DIR
  fi
  ln -s -f $PROJECT_DRUPAL_DIR $WEBSITE_DIR
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
