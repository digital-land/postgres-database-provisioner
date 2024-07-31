#!/usr/bin/env bash

database_name_regex="^((postgres|postgresql)://[^/]+)/(.+)$"

_cmd() {
  if [[ "${DRY_RUN}" = "true" ]]; then
    echo "Dry run cmd: $*"
  else
    "$@"
  fi
}

_create_db() {
  export DB_NAME=$1
  envsubst < createdb.template.sql > /tmp/createdb.sql
  _cmd psql -d "${POSTGRES_ADMIN_URL}" -f /tmp/createdb.sql
}

_create_admin_user() {
  export DB_NAME=$1
  export DB_USER=$2
  export DB_PASS=$3
  export PRIVILEGES=$4
  envsubst < createuser.template.sql > /tmp/createuser.sql

  DATABASE_URL="${POSTGRES_CONNECTION_BASE_URL}/${DB_NAME}"
  _cmd psql -d "${DATABASE_URL}" -f /tmp/createuser.sql
}

_derive_connection_base_url() {
  if ! [[ "$POSTGRES_ADMIN_URL" =~ $database_name_regex ]]; then
      echo "Received invalid postgres Admin connection URL: $POSTGRES_ADMIN_URL, cannot proceed with database provisioning"
      exit 1
  else
      POSTGRES_CONNECTION_BASE_URL="${BASH_REMATCH[1]}"
  fi
}

_load_config() {
  if ! [[ $(stat "$CONFIG_FILE_PATH") ]]; then
    echo "Could not find config file at location $CONFIG_FILE_PATH. Attempting download of config file from S3 bucket."
    export CONFIG_FILE_PATH=/opt/config/config.json
    aws s3 cp "$CONFIG_S3_BUCKET_NAME/config.json" "$CONFIG_FILE_PATH"
  fi
  export DRY_RUN=$(jq -r '.dry_run' < config.json)
}

_main() {
  _load_config
  _derive_connection_base_url

  # Create each database listed in config
  for database_config in $(jq -r '.databases[] | @base64' < "$CONFIG_FILE_PATH"); do
      database_config_decoded=$(echo ${database_config} | base64 -d)
      db_name=$(echo ${database_config_decoded} | jq -r '.name')
      _create_db $db_name

      user=$(echo "$database_config_decoded" | jq -r '.admin.username')
      pass=$(echo "$database_config_decoded" | jq -r '.admin.password')
      _create_admin_user $db_name $user $pass
  done

}}

_main
