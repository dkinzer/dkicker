.PHONY: default test local deploy clean reset prepare prepare-local
$SHELL := /bin/bash

default: test

test:

prepare:
	bash bin/prepare.sh

local: export ENV := local
local: clean
	source config/env/$$ENV; \
	bash bin/deploy.sh

deploy: export ENV := production
deploy: clean
	source config/env/$$ENV; \
	bash bin/deploy.sh

reset:
	bash bin/reset.sh
