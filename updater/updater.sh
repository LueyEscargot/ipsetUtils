#!/bin/bash

HOST_DB_FILE=host.db
SETNAME=hostDynamicIpList
INTERVAL=600

TIMEOUT=`echo "$(( ${INTERVAL} * 150 / 100 ))"`

echo "start update hosts' dynamic ip for ipset"

# create ipset's SET
ipset create ${SETNAME} hash:ip timeout ${TIMEOUT} comment --exist

while [ true ]
do
  hostList=`cat ${HOST_DB_FILE}`
  for host in ${hostList}
  do
    # update IPs
    ips=`getent hosts ${host} | awk '{ print $1 }'`
    for ip in ${ips}
    do
      ipset add ${SETNAME} ${ip} -exist comment "${host}"
    done
  done

  sleep ${INTERVAL}
done
