# Практическое изучение отказоустойчивости, часть 1. Обработка отказа СУБД при помощи физической потоковой репликации.


Посчитал уместным объеденить 2 прктических задания в одну работу, т.к. архитектура идентична.


Архитектура

3 ВМ ОС Centos7 с установленным Postgresql_12
1) Arbiter node (192.168.187.130)
2) Master node (192.168.187.128)
3) Slave node (192.168.187.129)

На ВМ Master и Slave настроена синхронная потоковая репликация с параметром (synchronous_commit=on).
Процедуры обработки отказа строятся на bash-скриптах, которые выполняются на ВМ.



Логика обработки отказов

На Master node запущен скрипт, опрашивающий Arbiter и Slave узлы с переодичностью в 1 минуту.

1.) Если связь с Arbiter и с Slave узлами потеряна - скрипт перезапускает сервер postgres.


На Slave node запущен скрипт, опрашивающий Arbiter и Master узлы с переодичностью в 1 минуту.

1.) Если связь с Arbiter и с Master узлами потеряна - скрипт перезапускает сервер postgres.

2.) Если связь с Master потеряна, то Slave опрашивает Arbiter и если тот подтвердит, что у него связь с Master отсутствует, то происходит promote Slave до Master узла.


На Ariter node запущен скрипт, опрашивающий Master и Slave узлы с переодичностью в 1 минуту.

1.) Если связь с Slave и с Master узлами потеряна - скрипт перезапускает сервер postgres.

2.) Если получен запрос от Slave о недоступности Master, Arbiter проверяет доступность с Master и при её отсутствие, отпрваляет Slave подтверждение отсутствия связи c Master.



Испытание

Было создано 3 скрипта: arbit.sh, master.sh, slave.sh - которые были размещены на соответствующих узлах. После запуска скриптов в случайные моменты времени, командой ifdown <int>, я выключал в разной последовательности сетевые интерфейсы на устройствах и скрипты записывали соответствующие записи в лог файлы - slave.log, master.log, arbit.log.




# Практическое изучение отказоустойчивости, часть 2. Верификация системы обработки отказа СУБД.


В этой работе действующими лицами будут Slave и Master узлы. Скрипт total.sh запущен на Master узле. 


Логика работы скрипта.

В процессе работы скрипт создаёт 4 временных файла-счётчиков (err - количество неудачных вставок, suc - количество успешных вставок, slave.total - количество фактических строк на Slave узле в таблице после востановления связи, master.total - количество фактических строк на Master узле в таблице после востановления связи). Количество неудачных/удачных вставок скрипт определяет по переменной TIMEOUT равной 3 секундам, если ответ от сервера не приходит в течении 3 секунд, то вставка считается неудачной. Асинхронные запросы на вставку происходят примерно каждые 0.1 секунду. После выполнения всех ассинхронных запросов, скрипт выводит статистику состоящую из 4 временных файлов.

Каждое испытание проводилось с различным состоянием параметра synchronous_commit. Ниже приведены результаты.


1.)synchronous_commit=off









