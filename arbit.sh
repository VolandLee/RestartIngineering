#!/bin/bash
#Arbit node
MASTER_HOST="192.168.187.128"
SLAVE_HOST="192.168.187.129"
PORT=8080
LOG_FILE="./arbiter.log"
check_connections() {
    MASTER_STATUS=$(pg_isready -h $MASTER_HOST)
    SLAVE_STATUS=$(pg_isready -h $SLAVE_HOST)
    echo "$(date): Master status: $MASTER_STATUS" >> $LOG_FILE
    echo "$(date): Slave status: $SLAVE_STATUS" >> $LOG_FILE
}

handle_http_requests() {
    while true; do
        echo -e "HTTP/1.1 200 OK\r\nContent-Length: 0\r\n\r\n" | nc -l -p $PORT -q 1 | (
            read REQUEST
            if [[ $REQUEST == *"GET /check_master"* ]]; then
                if [[ $MASTER_STATUS != *"accepting connections"* ]]; then
					#Ответ в случае отсутствия соединения
                    RESPONSE="HTTP/1.1 500 Internal Server Error\r\nContent-Length: 0\r\n\r\n"
		    echo "$(date): Sending 500 response to /check_master request" >> $LOG_FILE
                else
                    RESPONSE="HTTP/1.1 200 OK\r\nContent-Length: 0\r\n\r\n"
		    echo "$(date): Sending 200 response to /check_master request" >> $LOG_FILE
                fi
                echo -e $RESPONSE
            fi
        )
    done
}

#Фоновый процесс для прослушивания порта и ответа на запрос Slave
handle_http_requests &

while true; do
    check_connections
	#Случай когда все узлы недоступны
    if [[ $MASTER_STATUS != *"accepting connections"* ]] && [[ $SLAVE_STATUS != *"accepting connections"* ]]; then
        echo "$(date): Потеряна связь с другими узлами. Перезапуск Арбитра" >> $LOG_FILE
        sudo systemctl restart postgresql-12
    fi

    sleep 60
done
