# RestartIngineering
Архитектура
3 ВМ ОС Centos7 с установленным Postgresql_12
1) Arbiter node
2) Master node
3) Slave node

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
