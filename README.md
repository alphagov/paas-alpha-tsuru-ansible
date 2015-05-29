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
