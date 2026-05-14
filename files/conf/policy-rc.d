#!/bin/bash
#
# This is a non-package-managed script to define policies for system service
# actions attempted by invoke-rc.d.
# 
# See documentation:  
#
#       `man invoke-rc.d`
#       /usr/share/doc/init-system-helpers/README.policy-rc.d.gz
# 
# Usage:
#
#       /usr/sbin/policy-rc.d [options] <initscript ID> <actions> [<runlevel>]
#       /usr/sbin/policy-rc.d [options] --list <initscript ID> [<runlevel> ...]
#
# Options documented include only "--quiet" and "--list".  I take the synopsis
# to indicate that any options must precede positional paramaters, "--quiet"
# must precede "--list" if specified, and that "--list" changes parsing of
# positional paramaters.


function main() {
  # Deny service start at installation time.
  # Allow service restart at update time.
  declare -A policies
  policies['start']='deny'
  policies['stop']='allow'
  policies['force-stop']='allow'
  policies['restart']='allow'
  policies['reload']='allow'
  policies['force-reload']='allow'
  policies['status']='allow'

  # Parse arguments.
  quiet='no'
  list='no'
  actions=()
  runlevels=()
  if test '--quiet' == "${1}"; then
    quiet='yes'
    shift 1 || usage "Insufficient arguments."
  fi
  if test '--list' == "${1}"; then
    list='yes'
    shift 1 || usage "Insufficient arguments."
  fi
  service="${1}"
  shift 1 || usage "Insufficient arguments."
  if ! test 'yes' == "${list}"; then
    for action in ${1}; do
      actions+=( "${action}" )
    done
    shift 1 || usage "Insufficient arguments."
  fi
  while test "${#@}" -gt 0; do
    runlevels+=( "${1}" )
    shift 1 || usage "Insufficient arguments."
  done

  # List, if requested.
  if test 'yes' == "${list}"; then
    format='%-48s %-15s %-8s %-8s\n'
    printf "${format}" 'service' 'action' 'runlevel' 'policy'
    printf "${format}" '-------' '------' '--------' '------'
    for action in "${!policies[@]}"; do
      printf "${format}" "${service}" "${action}" 'any' "${policies[${action}]}"
    done
    return 0
  fi

  # Validate policy for requested service and actions.
  deny='no'
  unknown='no'
  undefined='no'
  for action in "${actions[@]}"; do
    case "${policies[$action]}" in
      'deny')
        deny='yes'
        ;;
      '')
        unknown='yes'
        ;;
      'allow')
        true
        ;;
      *)
        undefined='yes'
        ;;
    esac
  done
  case 'yes' in
    "${deny}")
      error 'Action denied by policy.'
      return 101
      ;;
    "${undefined}")
      warn 'Action has policy, but policy does not make sense.'
      return 105
      ;;
    "${unknown}")
      warn 'Action has no policy.'
      return 1
      ;;
    *)
      return 0
      ;;
  esac
}


function usage() {
  warn ''
  warn 'Usage:'
  warn '  policy-rc.d [options] <initscript ID> <actions> [<runlevel>]'
  warn '  policy-rc.d [options] --list <initscript ID> [<runlevel> ...]'
  warn ''
  fail "${1}"
}


function output() {
  printf '%s\n' "${1}"
}


function error() {
  output "Error:  ${1}" >&2
}


function warn() {
  output "Warning:  ${1}" >&2
}


function fail() {
  error "${1}"
  exit "${2:-1}"
}


main "${@}"
