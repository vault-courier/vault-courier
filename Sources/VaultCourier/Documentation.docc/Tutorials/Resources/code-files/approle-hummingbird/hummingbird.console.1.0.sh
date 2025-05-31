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