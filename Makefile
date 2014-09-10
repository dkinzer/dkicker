.PHONY: default test  deploy clean reset prepare

default: test

test:

prepare:
	bash bin/prepare.sh

deploy: clean
	bash bin/deploy.sh

reset:
	bash bin/reset.sh
