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
  WEBSITE_DIR='./../website'
fi

if [ ! "$DRUPAL_VERSION" ]; then
  DRUPAL_VERSION='7.28'
fi

if [ ! "$COMMIT" ]; then
  COMMIT=$(git rev-parse HEAD)
else
  COMMIT=$(git rev-parse --verify $COMMIT)
fi

DRUPAL_DIR=./build/drupal-$DRUPAL_VERSION
PROJECT_DRUPAL_DIR=$PROJECT_NAME/build/live

if [ ! -d "$DRUPAL_DIR" ]; then
  echo Build Drupal Core Version "$DRUPAL_VERSION"...
  mkdir -p ./build
  drush dl --verbose --yes drupal-$DRUPAL_VERSION --destination=./build
else
  echo Drupal Core already set to default: "$DRUPAL_VERSION"
fi

if [ ! -d "./build/sites/$COMMIT" ]; then
  echo Build website version: $COMMIT ...
  mkdir -p ./build/sites/$COMMIT
  git archive --format=tgz $COMMIT > website-$COMMIT.tgz
  tar xvf website-$COMMIT.tgz -C ./build/sites/$COMMIT
  rm website-$COMMIT.tgz
else
  echo website already at specified version: $COMMIT
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
ln -s -f ../../../settings.php $DRUPAL_DIR/sites/default/settings.php

rm -f ./build/live
ln -s -f ./drupal-$DRUPAL_VERSION ./build/live

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
