#!/usr/bin/env bash

set -euo pipefail

SCRIPTS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
MODULE_DIR="${SCRIPTS_DIR}/.."

source "${MODULE_DIR}/../../tools-and-utils/common-functions/setup.sh"

function ResetModule() {
  # if [ "$FAST_RESET" = "1" ]; then
  #   # Fast reset
  #   Account.destroy_all
  #   Balance.destroy_all
  #   BlockedOperation.destroy_all
  #   CorrespondentAccount.destroy_all
  #   Folder.destroy_all
  #   HeldBalance.destroy_all
  #   Role.destroy_all
  #   Document.destroy_all
  #   RvmExec "bundle exec rake db:seed"
  # else
  #   # Full reset
  #   RvmExec "bundle exec rake db:migrate:reset"
  #   RvmExec "bundle exec rake db:seed"
  # fi
  RvmExec "bundle exec rake db:migrate:reset"
  RvmExec "bundle exec rake db:seed"
}

function AfterModuleSetup() {
  echo "${green}Setuped WalletEngine${reset}"
}

Init "$@"
