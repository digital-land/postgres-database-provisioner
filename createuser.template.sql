do
$$
begin
  if not exists (select * from pg_user where usename = '${DB_USER}') then
    CREATE role "${DB_USER}" LOGIN password '${DB_PASS}';
end if;
end
$$
;
SET search_path = "${DB_NAME}";
GRANT ALL ON DATABASE "${DB_NAME}" TO "${DB_USER}";
GRANT ALL ON SCHEMA public TO "${DB_USER}";