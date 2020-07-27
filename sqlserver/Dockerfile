FROM mcr.microsoft.com/mssql/server:2017-CU8-ubuntu as build
RUN apt-get update && apt-get -y install netcat
COPY ["container_scripts", "/container_scripts/"]
COPY ["custom_entrypoint.sh", "/container_scripts/wait-for.sh", "/bin/"]
RUN chmod +x /bin/custom_entrypoint.sh
EXPOSE 32112
HEALTHCHECK --start-period=4m --interval=60s --retries=2 CMD /container_scripts/healthcheck.sh || exit 1
ENTRYPOINT [ "custom_entrypoint.sh" ]
ENV ACCEPT_EULA=Y SA_PASSWORD=Qwerty1234 MSSQL_AGENT_ENABLED=False

FROM build
COPY ["user_scripts", "/user_scripts/"]