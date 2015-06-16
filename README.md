Testing framework for Tsuru deployments
=======================================

Acceptance, smoke and integration tests for the tsuru deployment.

How to run it
-------------

Based on ruby 2.2.2, it is recommended to use `rbenv` or `rvm`.

Install the dependencies:

```
bundle install
```

end to end tests
----------------

You must pass the `TSURU_USER` and `TSURU_PASS` environment variables, and
optionally the `DEPLOY_ENV` (defaults to `ci` if missing).

```
TSURU_USER=... TSURU_PASS=... bundle exec rake endtoend:all
```

integration tests
-----------------

Based on an inventory. You can list all the tests with:

```
rake -T
```

In order to run all:

```
rake integration:all
```

Known issues
------------

Role in postgres is not deleted. Needs fixing:

```
Error: Failed to bind the instance "sampleapptestdb" to the app "sampleapp": role "sampleapptfc95b7" already exists
```

Solution:

 1. Connect to the postgres DB
 2. Run `DROP role sampleapp_3f9ef5`

Quick one-liner:

```
ssh -F ssh.config postgres-host.domain.com "sudo -u postgres psql -c 'DROP role sampleapp_3f9ef5;'"
```
