#!/bin/bash
set -eu

KEYCHAIN_ACCOUNT_NAME="tsuru-ansible-vault"

if which security >/dev/null; then
  >&2 echo "Fetching vault password from account '${KEYCHAIN_ACCOUNT_NAME}' in keychain.."
  security find-generic-password -wa ${KEYCHAIN_ACCOUNT_NAME}
else
  >&2 echo "Keychain not available. Prompting for vault password interatively.."
  >&2 echo -n "Vault password: "
  read -s PASSWORD
  >&2 echo
  echo $PASSWORD
fi
