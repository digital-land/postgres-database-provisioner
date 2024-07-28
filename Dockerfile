FROM alpine:3.18.0

RUN apk add bash postgresql-client envsubst jq

# Copy DB init SQL script template
COPY createdb.template.sql /opt/createdb.template.sql
COPY createuser.template.sql /opt/createuser.template.sql

# Copy DB init bash script
COPY initdb.sh /opt/initdb.sh

WORKDIR /opt

ENTRYPOINT /opt/initdb.sh