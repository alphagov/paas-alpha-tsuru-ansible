.PHONY: all \
	aws gce \
	check-env-var render-ssh-config \
	clean-roles ansible-galaxy \
	import-gpg-keys recrypt

all:
	$(error Usage: make <aws|gce> DEPLOY_ENV=name [ARGS=extra_args])

aws: check-env-var render-ssh-config
ifndef AWS_SECRET_ACCESS_KEY
	$(error Environment variable AWS_SECRET_ACCESS_KEY must be set)
endif
ifndef AWS_ACCESS_KEY_ID
	$(error Environment variable AWS_ACCESS_KEY_ID must be set)
endif
	ansible-playbook -i ec2.py site-aws.yml -e "deploy_env=${DEPLOY_ENV}" -e "@platform-aws.yml" ${ARGS}

gce: check-env-var render-ssh-config
	SSL_CERT_FILE=$(shell python -m certifi) ansible-playbook -i gce.py site-gce.yml -e "deploy_env=${DEPLOY_ENV}" -e "@platform-gce.yml" ${ARGS}

check-env-var:
ifndef DEPLOY_ENV
	$(error Must pass DEPLOY_ENV=<name>)
endif

render-ssh-config: check-env-var
	sed "s/DEPLOY_ENV/${DEPLOY_ENV}/g" ssh.config.template > ssh.config

clean-roles:
	rm -rf -- roles/*

ansible-galaxy:
	ansible-galaxy install -r requirements.yml --force

import-gpg-keys:
	$(foreach var, \
		$(shell cat gpg.recipients | awk -F: '{print $$1}'), \
		gpg --list-public-key $(var) || gpg --keyserver hkp://keyserver.ubuntu.com --search-keys $(var); \
	)

recrypt: import-gpg-keys
	ansible-vault decrypt group_vars/all/secure && pwgen -cynC1 15 | \
		gpg --batch --yes --trust-model always -e -o vault_passphrase.gpg \
			$(shell cat gpg.recipients | awk -F: {'printf "-r "$$1" "'}) && \
		ansible-vault encrypt group_vars/all/secure
