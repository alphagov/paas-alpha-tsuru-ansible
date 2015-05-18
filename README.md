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

* For provisioning on AWS you will need to have your AWS access credentials exported as environment variables for ansible to pick up.
```
export AWS_SECRET_ACCESS_KEY=<your secret access key>
export AWS_ACCESS_KEY_ID=<your access key id>
```

* For provisioning on GCE you will need to create a ~/.secrets.py file in your home directory.
The contents of ~/.secrets.py are as follows:
```
GCE_PARAMS = ('...@developer.gserviceaccount.com', '/path/to/gce_account.pem')
GCE_KEYWORD_PARAMS = {'project': 'project_id'}
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
s3_access_key: <docker-registry s3 bucket access key id>
s3_secret_key: <docker-registry s3 bucket access secret>

ssl_key: |
  -----BEGIN RSA PRIVATE KEY-----
  < private key content >
  -----END RSA PRIVATE KEY-----
ssl_crt: |
  -----BEGIN CERTIFICATE-----
  < ssl certificate content >
  -----END CERTIFICATE-----
```

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

Use the `Makefile`. Run without any arguments for more information:
```
make
```
