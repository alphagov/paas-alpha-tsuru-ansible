# tsuru-ansible

Ansible based project to configure a multi-node tsuru cluster.

### Requirements:

* Python things (you may wish to use [virtualenv](https://virtualenv.pypa.io/en/latest/)):
```
pip install -Ur requirements.txt
```
* Ruby things:
```
bundle install
```

### Instructions:

This repository is using [ansible-vault](https://docs.ansible.com/playbooks_vault.html) to secure sensitive information - If you already know the password you do not need to recreate the 'secure' file.

Encrypt your vault file using `ansible-vault encrypt group_vars/all/secure`

Required contents for group_vars/all/secure (if you don't know the password)

```yaml
---
pg_admin_pass: <your postgres admin password>
pg_apiuser_pass: <password for postgresapi database>
admin_user: <tsuru admin account to create>
admin_password: <tsuru admin password to create>
ssl_key: |
  -----BEGIN RSA PRIVATE KEY-----
  < private key content >
  -----END RSA PRIVATE KEY-----
ssl_crt: |
  -----BEGIN CERTIFICATE-----
  < ssl certificate content >
  -----END CERTIFICATE-----
```

* Update the inventory file to reflect the infrastructure that you want to use for your tsuru cluster.

> Note: can be any number of nodes, but every section in the inventory file has to have at least one node.
> (it is possible to use a node in more that one section).

* Install or update ansible playbooks using [librarian-ansible](https://github.com/bcoe/librarian-ansible):
```
bundle exec librarian-ansible install
```

* Configure the ssh key used to access the nodes:
```{r, engine='bash'}
ssh-add <the-public-ssh-key-file>
```
* Tune any global configuration needed to run your cluster in group_vars/all/globals.yml

### Deploying

Run:
```{r, engine='bash'}
#ansible-playbook -i inventory-<PROVIDER_NAME> site-<PROVIDER_NAME>.yml --vault-password-file vault_password.sh
```

**FIXME**

New format - will update readme properly soon
```
ansible-playbook -i gce.py --vault-password-file=~/.vault_pass.txt site-gce.yml -e "deploy_env=jmtest" -e "domain_name=tsuru2.paas.alphagov.co.uk" -e "ip_field=gce_private_ip"
```

- Something something `~/secrets.py` file for libcloud?
- CA CERT file on OSX?
    RuntimeError: No CA Certificates were found in CA_CERTS_PATH. For information on how to get required certificate files, please visit https://libcloud.readthedocs.org/en/latest/other/ssl-certificate-validation.html

Where:
  - `<PROVIDER_NAME>` is: `aws`, `gce` or `vagrant`
