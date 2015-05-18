.PHONY: all aws gce check-env-var

all:
	$(error Usage: make <aws|gce> DEPLOY_ENV=NAME)

aws: check-env-var
	ansible-playbook -i ec2.py --vault-password-file vault_password.sh site-aws.yml -e "deploy_env=${DEPLOY_ENV}" -e "@platform-aws.yml"

gce: check-env-var
	SSL_CERT_FILE=$(python -m certifi) ansible-playbook -i gce.py --vault-password-file vault_password.sh site-gce.yml -e "deploy_env=${DEPLOY_ENV}" -e "@platform-gce.yml"

check-env-var:
ifndef DEPLOY_ENV
	$(error Must pass DEPLOY_ENV=<name>)
endif
