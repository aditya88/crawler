killall postgres
/etc/init.d/postgresql-8.4 restart
dropdb -U crawler crawlerdb 
createdb -W -O crawler -U crawler crawlerdb
psql -f ~/workspace/web\ v0.1/mediawords.sql -U crawler -d crawlerdb


