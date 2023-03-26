#!/bin/bash

PLINKO=./build/plinko
SCRIPT=./scripts/escape-2-r0-pos.json.var
CMDS=/tmp/list.txt
LOG=/tmp/plinko.log

rm ${CMDS} 2> /dev/null
rm ${LOG} 2> /dev/null
touch ${CMDS}

i=0
for v in $(seq 0.3 0.002 0.7)
do
    t=`printf "count=%06d,p=%s" "$i" "$v"`
    cmd="${SCRIPT} ${t}"
    echo "${cmd}" >> ${CMDS}
    (( i++ ))
done

parallel --colsep ' ' -j `nproc` -a ${CMDS} ${PLINKO} {1} {2} >> ${LOG}
