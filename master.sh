#Master node 
ARBITER_HOST="192.168.187.130"
SLAVE_HOST="192.168.187.129"

while true; do
    ARBITER_STATUS=$(pg_isready -h $ARBITER_HOST)
    SLAVE_STATUS=$(pg_isready -h $SLAVE_HOST)

    if [[ $ARBITER_STATUS != *"accepting connections"* ]] && [[ $SLAVE_STATUS != *"accepting connections"* ]]; then
        echo "$(date): Потеряна связь с остальными узлами. Перезапуск Master."
        sudo systemctl restart postgresql-12
    fi

    sleep 60
done
