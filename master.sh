#Master node 
ARBITER_HOST="192.168.187.130"
SLAVE_HOST="192.168.187.129"
LOG_FILE="./master.log"

while true; do
    ARBITER_STATUS=$(pg_isready -h $ARBITER_HOST)
    SLAVE_STATUS=$(pg_isready -h $SLAVE_HOST)
    echo "$(date): Arbiter status: $ARBITER_STATUS" >> $LOG_FILE
    echo "$(date): Slave status: $SLAVE_STATUS" >> $LOG_FILE

    if [[ $ARBITER_STATUS != *"accepting connections"* ]] && [[ $SLAVE_STATUS != *"accepting connections"* ]]; then
        echo "$(date): Потеряна связь с остальными узлами. Перезапуск Master." >> $LOG_FILE
        sudo systemctl restart postgresql-12
    fi

    sleep 60
done
