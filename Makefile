.PHONY: all \
	aws gce \
	preflight check-env-var check-env-aws render-ssh-config \
	ansible-galaxy \
	import-gpg-keys recrypt

ANSIBLE_PLAYBOOK_CMD = ansible-playbook \
	-i $(1) \
	site-$(2).yml \
	-e "@platform-$(2).yml" \
	-e "deploy_env=${DEPLOY_ENV}" ${ARGS}

all:
	$(error Usage: make <aws|gce> DEPLOY_ENV=name [ARGS=extra_args])

aws: preflight check-env-aws
	$(call ANSIBLE_PLAYBOOK_CMD,ec2.py,aws)

gce: preflight
	SSL_CERT_FILE=$(shell python -m certifi) $(call ANSIBLE_PLAYBOOK_CMD,gce.py,gce)

preflight: check-env-var render-ssh-config ansible-galaxy

check-env-aws:
ifndef AWS_SECRET_ACCESS_KEY
	$(error Environment variable AWS_SECRET_ACCESS_KEY must be set)
endif
ifndef AWS_ACCESS_KEY_ID
	$(error Environment variable AWS_ACCESS_KEY_ID must be set)
endif

check-env-var:
ifndef DEPLOY_ENV
	$(error Must pass DEPLOY_ENV=<name>)
endif

render-ssh-config: check-env-var
	sed "s/DEPLOY_ENV/${DEPLOY_ENV}/g" ssh.config.template > ssh.config

ansible-galaxy: .ansible-galaxy.check
.ansible-galaxy.check: requirements.yml
	rm -rf -- roles/*
	ansible-galaxy install -r requirements.yml --force
	touch .ansible-galaxy.check

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
