FROM alpine:3.18.0

RUN apk add bash postgresql-client envsubst jq aws-cli

# Copy DB init SQL script template
COPY createdb.template.sql /opt/createdb.template.sql
COPY createuser.template.sql /opt/createuser.template.sql

# Copy DB init bash script
COPY initdb.sh /opt/initdb.sh

WORKDIR /opt

ENV CONFIG_FILE_PATH=/opt/config/config.json

ENTRYPOINT /opt/initdb.sh