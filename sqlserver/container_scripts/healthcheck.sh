#!/bin/bash

set -e

# exit if user healthcheck script does not exist or is empty
if [ ! -s "/user_scripts/healthcheck.sql" ]; then
    exit
fi

if [ -e "/run/secrets/sql_server_password" ]; then
	SA_PASSWORD=`< /run/secrets/sql_server_password`
fi

/opt/mssql-tools/bin/sqlcmd -b -S 127.0.0.1 -U sa -P "$SA_PASSWORD" -i /user_scripts/healthcheck.sql