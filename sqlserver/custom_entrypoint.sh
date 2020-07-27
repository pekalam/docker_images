#!/bin/bash

set -e
WAIT_FOR_TIMEOUT=240
MSSQL_AGENT_RETRIES=10

# set password if stored as secret 
if [ -e "/run/secrets/sql_server_password" ]; then
	SA_PASSWORD=`< /run/secrets/sql_server_password`
fi

if [ "$MSSQL_AGENT_ENABLED" = "" ]; then
    MSSQL_AGENT_ENABLED="False"
fi

# start SQLServer as background process 
SA_PASSWORD=$SA_PASSWORD MSSQL_AGENT_ENABLED=$MSSQL_AGENT_ENABLED /opt/mssql/bin/sqlservr &

# wait for 1433 port
echo "Waiting for 1433 port"
/container_scripts/wait-for.sh 0.0.0.0:1433 -t $WAIT_FOR_TIMEOUT

# if mssql agent is enabled
if [ "$MSSQL_AGENT_ENABLED" = "True" ]; then

    # manually start mssql agent
    echo "Starting mssql agent"
    /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P $SA_PASSWORD -i /container_scripts/start_agent.sql

    
    retry=$MSSQL_AGENT_RETRIES
    while [ $retry -gt 0 ]; do
        result=$(/opt/mssql-tools/bin/sqlcmd -b -S localhost -U sa -P $SA_PASSWORD -Q "exec msdb.dbo.sp_is_sqlagent_starting" 1>/dev/null 2>/dev/null && echo $? || echo $?)
        if [ $result -eq 0 ]; then
            break
        fi
        retry=$(($retry-1))
        echo "mssql agent is not running (retries left: "$retry")"
        sleep 5
    done

    if [ $retry -eq 0 ]; then
        echo "sql agent is not running"
        exit 128
    fi

    echo "mssql agent started"
fi


if [ -s "/user_scripts/startup.sql" ]; then
    echo "Running startup sql script /user_scripts/startup.sql"

    /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P $SA_PASSWORD -i /user_scripts/startup.sql
    sleep 5
fi

if [ -d "/user_scripts/startup" ]; then
    echo "Running following scripts from /user_scripts/startup directory: " /user_scripts/startup/startup*.sql

    for f in /user_scripts/startup/startup*.sql
    do
        echo "Executing $f script"
        /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P $SA_PASSWORD -i "$f"
    done
    sleep 5
fi


echo "Listening on health port"
/container_scripts/listen_on_health_port.sh &

echo "SQLServer container successfully started"
wait