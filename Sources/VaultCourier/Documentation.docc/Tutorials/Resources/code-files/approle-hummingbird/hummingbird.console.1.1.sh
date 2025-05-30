% docker pull postgres:latest

% docker run \
    --detach \
    --name learn-postgres \
    -e POSTGRES_USER=vault_root \
    -e POSTGRES_PASSWORD=root_password \
    -e POSTGRES_DB=postgres \
    -e POSTGRES_HOST_AUTH_METHOD='scram-sha-256' \
    -e POSTGRES_INITDB_ARGS='--auth-host=scram-sha-256' \
    -p 5432:5432 \
    --rm \
    postgres

% docker exec -i \
    learn-postgres \
    psql -U vault_root -d postgres -c "CREATE ROLE \"todos_user\" LOGIN PASSWORD 'todos_user_password';"

docker exec -i \
    learn-postgres \
    psql -U vault_root -d postgres -c "GRANT CONNECT ON DATABASE postgres TO todos_user;"