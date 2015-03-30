# tsuru-ansible

Ansible based project to configure a multi-node tsuru cluster.

### Requirement:
* ansible 1.4 or higher.

### Instructions:
* Update the inventory file to reflect the infrastructure that you want to use for your tsuru cluster.

> Note: can be any number of nodes, but every section in the inventory file has to have at least one node. 
> (it is possible to use a node in more that one section). 

* Configure the ssh key used to access the nodes:
```{r, engine='bash'}
ssh-add <the-public-ssh-key-file>
```
* Tune any global configuration needed to run your cluster in globals.yml.
* Run ansible to deploy your configuration.
```{r, engine='bash'}
ansible-playbook -i inventory site.yml -e "@globals.yml"
```
