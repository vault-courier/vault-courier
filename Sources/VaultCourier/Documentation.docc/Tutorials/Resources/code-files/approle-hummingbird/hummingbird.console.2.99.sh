todos-postgres-tutorial % swift run Operations vault-admin --help

OVERVIEW: A sample vault-admin operations tool

USAGE: vault-admin <subcommand>

OPTIONS:
  -h, --help              Show help information.

SUBCOMMANDS:
  provision               Provision vault policies, approles and sets the database secret mount.
  credentials             Generates the approle credentials for the Todo server or migrator app.

todos-postgres-tutorial % swift run Operations provision

Policy 'migrator' written.
Policy 'todos' written.
Database secrets engine enabled at 'database'.
Static role 'static_server_role' created.
Dynamic role 'dynamic_migrator_role' created.
AppRole Authentication enabled.
AppRole 'server_app_role' created.
AppRole 'migrator_app_role' created.

todos-postgres-tutorial % swift run Operations credentials migrator

Generating Approle credentials for 'migrator' app...
SecretID successfully written to ./approle_secret_id.txt
migrator app roleID: 323184a0-7665-f89f-6350-aa2c4005dc4c

todos-postgres-tutorial % ROLE_ID=323184a0-7665-f89f-6350-aa2c4005dc4c SECRET_ID_FILEPATH=./approle_secret_id.txt swift run Migrator

info migrator : [VaultCourier] login authorized
Migration successfull! 'todos' table created.

todos-postgres-tutorial % swift run Operations credentials todo
Generating Approle credentials for 'todo' app...
SecretID successfully written to ./approle_secret_id.txt
todo app roleID: 8039d04e-f609-2733-fe7a-ef682d709548

todos-postgres-tutorial % ROLE_ID=8039d04e-f609-2733-fe7a-ef682d709548 SECRET_ID_FILEPATH=./approle_secret_id.txt swift run App

info todos-postgres-tutorial : [VaultCourier] login authorized
info todos-postgres-tutorial : [HummingbirdCore] Server started and listening on 127.0.0.1:8080


curl -i -X POST localhost:8080/todos -d'{"title": "Book Hotel in Cartagena"}'
HTTP/1.1 201 Created
Content-Type: application/json; charset=utf-8
Content-Length: 156
Server: todos-postgres-tutorial

{"id":"21B6D74B-102F-45D6-B116-40966BC8C4F0","url":"http:\/\/localhost:8080\/todos\/21B6D74B-102F-45D6-B116-40966BC8C4F0","title":"Book Hotel in Cartagena"}%