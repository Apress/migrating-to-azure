FROM microsoft/mssql-server-linux

EXPOSE 1433
COPY cdb.sql .

ENV SA_PASSWORD='MyP@ssw0rd!1'
ENV ACCEPT_EULA='Y'
ENV MSSQL_PID='Developer'

RUN /opt/mssql/bin/sqlservr --accept-eula & sleep 15 \
    && /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P ${SA_PASSWORD} -i cdb.sql \
    && pkill sqlservr 

RUN echo 'Processing complete.'