#!/bin/bash

cp -f bin/post-update .git/hooks/post-update
git config receive.denyCurrentBranch ignore
