# tsuru-ansible

Ansible based project to configure a multi-node tsuru cluster.

### Requirements:

* Python things (you may wish to use [virtualenv](https://virtualenv.pypa.io/en/latest/)):
```
pip install -Ur requirements.txt
```

* For provisioning on AWS you will need to have your AWS access credentials exported as environment variables for ansible to pick up.
```
export AWS_SECRET_ACCESS_KEY=<your secret access key>
export AWS_ACCESS_KEY_ID=<your access key id>
```

* For provisioning on GCE you will need to create a `secrets.py` file in the
root directory of this repo. The contents are as follows:
```
GCE_PARAMS = ('...@developer.gserviceaccount.com', '/path/to/gce_account.json')
GCE_KEYWORD_PARAMS = {'project': 'project_id'}
```


* [GnuPG](#setting-up-gpg-encrypted-vault-password-support)

#### Setting up GPG-encrypted vault-password support

You will need to have setup [gpg-agent](https://www.gnupg.org/) on your computer before you start.

##### Apple specific

Install the latest [GPG Tools Suite for MacOX](https://gpgtools.org/)

```
brew install pwgen
brew install gpg
brew install gpg-agent
```

##### Ubuntu specific

Install the [GNU Privacy Guard encryption suite](https://www.gnupg.org/):

```
sudo apt-get update
sudo apt-get install pwgen
sudo apt-get install gnupg2
sudo apt-get install gnupg-agent
sudo apt-get install pinentry-curses
```

##### Common

If you haven't already generated your pgp key (it's ok to accept the default options if you never done this before):

```
gpg --gen-key
```

Get your KEYID from your keyring:

```
gpg --list-secret-keys | grep sec
```

This will probably be pre-fixed with 2048R/ and look something like 93B1CD02

Send your public key to pgp key server :

```
gpg --keyserver pgp.mit.edu --send-keys KEYID
```


Create ~/.bash_gpg:

```
envfile="${HOME}/.gnupg/gpg-agent.env"

if test -f "$envfile" && kill -0 $(grep GPG_AGENT_INFO "$envfile" | cut -d: -f 2) 2>/dev/null; then
    eval "$(cat "$envfile")"
else
    eval "$(gpg-agent --daemon --log-file=~/.gpg/gpg.log --write-env-file "$envfile")"
fi
export GPG_AGENT_INFO  # the env file does not contain the export statement
```

Add to ~/.bashrc

```
GPG_AGENT=$(which gpg-agent)
GPG_TTY=`tty`
export GPG_TTY

if [ -f ${GPG_AGENT} ]; then
    . ~/.bash_gpg
fi
```

##### Ubuntu specific

Create ~/.gnupg/gpg-agent.conf

```
default-cache-ttl 600
pinentry-program /usr/bin/pinentry
max-cache-ttl 172800
```

##### Final step

Start a new shell or source your bashrc i.e. `. ~/.bashrc`

### Docker registry on the Google Platform

We use a service account with [Google Application Default Credentials](https://developers.google.com/identity/protocols/application-default-credentials).

[We have scoped the access](https://github.com/alphagov/tsuru-terraform/pull/62) of the service account access token to `storage-rw` to allow docker registry read-write access to the `gcs` bucket, this allows:

* The docker registry to get its authorization credentials by making api calls to google
* The team to provision docker registries with out having to setup their own gcs access and secret keys

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

aws_ssl_key: |
  -----BEGIN RSA PRIVATE KEY-----
  < private key content >
  -----END RSA PRIVATE KEY-----
aws_ssl_crt: |
  -----BEGIN CERTIFICATE-----
  < ssl certificate content >
  -----END CERTIFICATE-----

gce_ssl_key: |
  -----BEGIN RSA PRIVATE KEY-----
  < private key content >
  -----END RSA PRIVATE KEY-----
gce_ssl_crt: |
  -----BEGIN CERTIFICATE-----
  < ssl certificate content >
  -----END CERTIFICATE-----
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

### Smoke test

This will run a basic smoke test against a deployed environment.

#### Dependencies

Based on ruby 2.2.2, it is recommended to use `rbenv` or `rvm`.

#### Run using make
This will install the dependencies, run against the CI environment and use the default tsuru admin credentials stored in the Ansible vault.
```bash
make test-aws
make test-gce
```

You can specify another test environment:
```bash
make test-aws DEPLOY_ENV=...
make test-gce DEPLOY_ENV=...
```

#### Custom run

Install the dependencies:
```bash
bundle install
```

You must pass the `TSURU_USER` and `TSURU_PASS` environment variables, and
optionally the `DEPLOY_ENV` (defaults to `ci` if missing).

```bash
TSURU_USER=... TSURU_PASS=... DEPLOY_ENV=... bundle exec rake endtoend:all
```

#### Troubleshooting

To enable verbose mode set the variable VERBOSE to true.
```bash
make test-aws VERBOSE=TRUE
make test-gce VERBOSE=TRUE
```

#### Known issues

The role in postgres is not deleted when the service is unbound and causes the following error:
```
Error: Failed to bind the instance "sampleapptestdb" to the app "sampleapp": role "sampleapptfc95b7" already exists
```

This is a [know issue](https://github.com/tsuru/postgres-api/issues/1)

Workaround:

 1. Connect to the postgres DB
 2. Run `DROP role sampleapp_3f9ef5`

Quick one-liner:

```
ssh -F ssh.config postgres-host.domain.com "sudo -u postgres psql -c 'DROP role sampleapp_3f9ef5;'"
```
