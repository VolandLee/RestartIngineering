#!/bin/bash

#Slave node
ARBITER_HOST="192.168.187.130"
MASTER_HOST="192.168.187.128"
LOG_FILE="./slave.log"

while true; do
    ARBITER_STATUS=$(pg_isready -h $ARBITER_HOST)
    MASTER_STATUS=$(pg_isready -h $MASTER_HOST)
    echo "$(date): Arbiter status: $ARBITER_STATUS" >> $LOG_FILE
    echo "$(date): Master status: $MASTER_STATUS" >> $LOG_FILE
    if [[ $ARBITER_STATUS != *"accepting connections"* ]] && [[ $MASTER_STATUS != *"accepting connections"* ]]; then
        echo "$(date): Потеряна связь с другими узлами. Перезапуск Slave." >> $LOG_FILE
        sudo systemctl restart postgresql-12
    elif [[ $MASTER_STATUS != *"accepting connections"* ]]; then
        HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://$ARBITER_HOST:8080/check_master?host=$MASTER_HOST)
        if [ "$HTTP_CODE" -eq 500 ]; then
            echo "$(date): Получено подтверждение от Арбитра об отсутствии связи с Mster. Promoting Slave to Master." >> $LOG_FILE
            sudo -u postgres pg_ctlcluster 12 main promote
        fi
    fi

    sleep 60
done
