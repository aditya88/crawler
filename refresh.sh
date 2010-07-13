sudo killall -s 9 postgres
#/etc/init.d/postgresql-8.4 stop
/etc/init.d/postgresql-8.4 restart
dropdb -U crawler crawlerdb 
createdb -W -O crawler -U crawler crawlerdb
psql -f ~/workspace/web\ v0.1/MCrawler_DB.sql -U crawler -d crawlerdb
