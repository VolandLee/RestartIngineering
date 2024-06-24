#!/bin/bash

# Время ожидания ответа в секундах
TIMEOUT=3

# Временные файлы для подсчета успешных и ошибочных запросов
echo 0 > suc
echo 0 > err
#Очистка таблицы в slave
ssh -t -l root 192.168.187.129 sudo -u postgres psql -d test1 -c "delete from test;"
#Очистка таблицы в master
psql -d test1 -c "delete from test;"

execute_query() {
    # Выполнение запроса и измерение времени выполнения, если время ответа вревышает TIMEOUT, то запрос считается неудачным
    START_TIME=$(date +%s)
    psql -d test1 -c "insert into test(date) values (now());" &>/dev/null
    END_TIME=$(date +%s)
    ELAPSED_TIME=$((END_TIME - START_TIME))

    # Проверка времени выполнения запроса
    if [ $ELAPSED_TIME -le $TIMEOUT ]; then
        echo $(($(cat suc)+1)) > suc
    else
        echo $(($(cat err)+1)) > err
    fi
}

# Цикл для выполнения 1 000 000 асинхронных запросов
for ((i=1; i<=6000; i++)); do
    execute_query &
    # Случайный промежуток времени от 0 до 1 секунды
    sleep $((RANDOM % 1000))e-3
    #echo "Total successful queries: $SUCCESS_COUNT"
    #echo "Total error queries: $ERROR_COUNT"


done

# Ожидание завершения всех фоновых процессов
wait
#Подсчёт фактически вставленных строк master
psql -d test1 -c "select count(*) from test;" >> master.total   #master
#Подсчёт фактически вставленных строк slave
sh -t -l root 192.168.187.129 sudo -u postgres psql -d test1 -c "select count(*) from test;" >> slave.total


# Вывод итоговой статистики.

echo "Количество успешных запросов: $(cat suc)"
echo "Количество неудачных запросов: $(cat err)"
echo "Фактическое количество строк в Master: $(cat master.total)"
echo "Фактическое количество строк в Slave: $(cat slave.total)"


