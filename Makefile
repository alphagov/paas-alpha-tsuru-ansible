.PHONY: all aws gce check-env-var render-ssh-config

all:
	$(error Usage: make <aws|gce> DEPLOY_ENV=NAME)

aws: check-env-var render-ssh-config
	ansible-playbook -i ec2.py --vault-password-file vault_password.sh site-aws.yml -e "deploy_env=${DEPLOY_ENV}" -e "@platform-aws.yml"

gce: check-env-var render-ssh-config
	SSL_CERT_FILE=$(shell python -m certifi) ansible-playbook -i gce.py --vault-password-file vault_password.sh site-gce.yml -e "deploy_env=${DEPLOY_ENV}" -e "@platform-gce.yml"

check-env-var:
ifndef DEPLOY_ENV
	$(error Must pass DEPLOY_ENV=<name>)
endif

render-ssh-config: check-env-var
	sed "s/DEPLOY_ENV/${DEPLOY_ENV}/g" ssh.config.template > ssh.config
