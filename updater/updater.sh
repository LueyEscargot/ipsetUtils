#!/bin/bash

WD=$(dirname $0)

ENV_FILE=.env
HOST_FILE=host.db
DATA_FILE=.data
QUITE=false
SETNAME4=host4
SETNAME6=host6
TTL=3600
HASHSIZE=1024
MAXELEM=256

cmd=$1

Log() {
  if [ ${QUITE} = false -a $# -gt 0 ]; then
    LogStr=''
    while [ $# -gt 0 ]
    do
      LogStr="${LogStr} $1"
      shift 1
    done

    echo ${LogStr}
  fi
}

addr() {
    domain=$1

    result=`host ${domain}`
    OLD_IFS=$IFS
    IFS='$'
    for ip in ${result}
    do
        result4="$(echo ${ip} | grep "has address" | awk '{print $4}')"
        result6="$(echo ${ip} | grep "has IPv6 address" | awk '{print $5}')"
    done

    IFS=${OLD_IFS}

    echo "${result4}"
    echo "${result6}"
}

init() {
  [ -f ${HOST_FILE} ] && . ${WD}/${HOST_FILE}
  [ -f ${ENV_FILE} ] && . ${WD}/${ENV_FILE}

  Log "start update hosts' dynamic ip for ipset"

  Log " HOST_FILE: ${HOST_FILE}"
  Log " SETNAME4: ${SETNAME4}"
  Log " SETNAME4: ${SETNAME4}"
  Log " SETNAME6: ${SETNAME6}"
  Log " TTL:      ${TTL}"
  Log " HASHSIZE: ${HASHSIZE}"
  Log " MAXELEM:  ${MAXELEM}"
  Log " DOMAINS:  ${DOMAINS}"

  # create set v4
  if [ -z "$(ipset list | grep ${SETNAME4})" ]; then
      Log create ipset\'s SET: ${SETNAME4}
      ipset -exist create ${SETNAME4} hash:ip family inet timeout ${TTL} hashsize ${HASHSIZE} maxelem ${MAXELEM} comment
  fi

  # create set v6
  if [ -z "$(ipset list | grep ${SETNAME6})" ]; then
      Log create ipset\'s SET: ${SETNAME6}
      ipset -exist create ${SETNAME6} hash:ip family inet6 timeout ${TTL} hashsize ${HASHSIZE} maxelem ${MAXELEM} comment
  fi
}

backup() {
  ipset save > ${WD}/${DATA_FILE}
}

restore() {
  [ -f ${WD}/${DATA_FILE} ] && `cat ${WD}/${DATA_FILE} | ipset restore`
}

updateIPs() {
  for domain in ${DOMAINS}
  do
      Log --- domain: ${domain} ---

      ips=$(addr ${domain})
      for ip in ${ips}
      do
          if [[ "${ip}" == *":"* ]]; then
              # IPv6
              echo " IPv6: ${ip}"
              ipset -exist add ${SETNAME6} ${ip} comment "${domain}"
          else
              # IPv4
              echo " IPv4: ${ip}"
              ipset -exist add ${SETNAME4} ${ip} comment "${domain}"
          fi
      done
  done
}

if [ -n "${cmd}" ]; then
  case "${cmd}" in
    "backup")
      echo "backup"
      backup
    ;;
    "restore")
      echo "restore"
      restore
    ;;
    *)
      init
      updateIPs
    ;;
  esac
fi
