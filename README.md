# tsuru-ansible

Ansible based project to configure a multi-node tsuru cluster.

### Requirement:
* ansible 1.9 or higher.
* librarian-ansible 1.0.6 or higher

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
```

* Update the inventory file to reflect the infrastructure that you want to use for your tsuru cluster.

> Note: can be any number of nodes, but every section in the inventory file has to have at least one node.
> (it is possible to use a node in more that one section).

* Install or update ansible playbooks using [librarian-ansible](https://github.com/bcoe/librarian-ansible):
```
librarian-ansible install
```

* Configure the ssh key used to access the nodes:
```{r, engine='bash'}
ssh-add <the-public-ssh-key-file>
```
* Tune any global configuration needed to run your cluster in globals.yml.
* Run ansible to deploy your configuration.
```{r, engine='bash'}
ansible-playbook -i inventory site.yml -e "@globals.yml" --ask-vault-pass
```
