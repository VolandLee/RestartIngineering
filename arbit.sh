#!/bin/bash
#Arbit node
MASTER_HOST="192.168.187.128"
SLAVE_HOST="192.168.187.129"
PORT=8080

check_connections() {
    MASTER_STATUS=$(pg_isready -h $MASTER_HOST)
    SLAVE_STATUS=$(pg_isready -h $SLAVE_HOST)
}

handle_http_requests() {
    while true; do
        echo -e "HTTP/1.1 200 OK\r\nContent-Length: 0\r\n\r\n" | nc -l -p $PORT -q 1 | (
            read REQUEST
            if [[ $REQUEST == *"GET /check_master"* ]]; then
                if [[ $MASTER_STATUS != *"accepting connections"* ]]; then
					#Ответ в случае отсутствия соединения
                    RESPONSE="HTTP/1.1 500 Internal Server Error\r\nContent-Length: 0\r\n\r\n"
                else
                    RESPONSE="HTTP/1.1 200 OK\r\nContent-Length: 0\r\n\r\n"
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
        echo "$(date): Потеряна связь с другими узлами. Перезапуск Арбитра"
        sudo systemctl restart postgresql-12
    fi

    sleep 60
done
