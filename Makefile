.PHONY: all \
	aws gce \
	preflight check-env-var check-env-aws render-ssh-config \
	ansible-galaxy \
	import-gpg-keys recrypt diff-vault \
	check-target-platform-var

VAULT_FIFO = .diff-vault.fifo
VAULT_FILE = group_vars/all/secure

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
	ansible-vault decrypt ${VAULT_FILE} && pwgen -cynC1 15 | \
		gpg --batch --yes --trust-model always -e -o vault_passphrase.gpg \
			$(shell cat gpg.recipients | awk -F: {'printf "-r "$$1" "'}) && \
		ansible-vault encrypt ${VAULT_FILE}

check-target-api-host-var:
	@[ -z "${TARGET_API_HOST}" ] && echo TARGET_API_HOST cannot be empty && exit 2 || true

test: check-env-var check-target-api-host-var load-tsuru-creds
	@bundle install --path vendor/bundle --quiet
	@SSL_CERT_FILE=$(shell python -m certifi) \
	TARGET_API_HOST=${TARGET_API_HOST} \
	TSURU_USER=${TSURU_USER} \
	TSURU_PASS=${TSURU_PASS} \
	bundle exec rake endtoend:all

load-tsuru-creds:
	$(eval TSURU_USER=$(shell \
		ansible-vault view group_vars/all/secure | \
		    awk '/admin_user:/ { print $$2; }'))
	$(eval TSURU_PASS=$(shell \
		ansible-vault view group_vars/all/secure | \
			awk '/admin_password:/ { print $$2; }'))
	@[ -z "${TSURU_USER}" -o -z "${TSURU_PASS}" ] && \
		echo Error loading tsuru credentials from vault && exit 2 || true

set-aws:
	$(eval TARGET_API_HOST=${DEPLOY_ENV}-api.$(shell cat platform-aws.yml | awk -F \" '/domain_name:/ { print $$2 }'))
set-gce:
	$(eval TARGET_API_HOST=${DEPLOY_ENV}-api.$(shell cat platform-gce.yml | awk -F \" '/domain_name:/ { print $$2 }'))
test-aws: set-aws test
test-gce: set-gce test

diff-vault:
	@(mkfifo -m 0600 ${VAULT_FIFO} && \
		git show master:${VAULT_FILE} > ${VAULT_FIFO}; \
		rm -f ${VAULT_FIFO}) &
	@bash -c 'diff -u \
		<(ansible-vault view ${VAULT_FIFO} 2>/dev/null) \
		<(ansible-vault view ${VAULT_FILE} 2>/dev/null) \
		|| [ $$? -eq 1 ]'

start-aws: check-env-var render-ssh-config
	ansible-playbook -i ec2.py ec2-wake.yml -e deploy_env=${DEPLOY_ENV}

start-gce: check-env-var render-ssh-config
	SSL_CERT_FILE=$(shell python -m certifi) ansible-playbook -i gce.py gce-wake.yml -e deploy_env=${DEPLOY_ENV}

suspend-aws: check-env-var render-ssh-config
	ansible all -i ec2.py -a 'sudo poweroff' -l "!~^tag_Name_${DEPLOY_ENV}-tsuru-nat:~^tag_Name_${DEPLOY_ENV}-"
	ansible all -i ec2.py -a 'sudo poweroff' -l "~^tag_Name_${DEPLOY_ENV}-tsuru-nat"

suspend-gce: check-env-var render-ssh-config
	SSL_CERT_FILE=$(shell python -m certifi) \
	ansible all -i gce.py -a 'sudo poweroff' -l "!~^${DEPLOY_ENV}-tsuru-nat:~^${DEPLOY_ENV}-"
	SSL_CERT_FILE=$(shell python -m certifi) \
	ansible all -i gce.py -a 'sudo poweroff' -l "~^${DEPLOY_ENV}-tsuru-nat"
