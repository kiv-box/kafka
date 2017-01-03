#!/bin/bash
#

TOPIC_LIST=$(/usr/lib/kafka/bin/kafka-topics.sh --list --zookeeper 127.0.0.1 | grep -v '__consumer_offsets'| grep -v 'for deletion' )

echo '{'
echo '  "topics": ['
    for TOPIC in ${TOPIC_LIST}
    do
        if [ ${TOPIC} == "$( echo ${TOPIC_LIST} | awk '{ print $NF }' )" ]
        then
            echo "              { \"topic\" : \"${TOPIC}\" }"
        else
            echo "              { \"topic\" : \"${TOPIC}\" },"
    fi
    done
echo '            ],'
echo '  "version":1'
echo '}'
