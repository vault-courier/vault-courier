approle-vapor-example % swift run Operations vault-admin --help

OVERVIEW: A sample vault-admin operations tool

USAGE: vault-admin <subcommand>

OPTIONS:
  -h, --help              Show help information.

SUBCOMMANDS:
  provision               Provision vault policies, approles and sets the database secret mount.
  credentials             Generates the approle credentials for the Todo server or migrator app.

approle-vapor-example % swift run Operations provision

Policy 'migrator' written.
Policy 'todos' written.
Database secrets engine enabled at 'database'.
Static role 'static_server_role' created.
Dynamic role 'dynamic_migrator_role' created.
AppRole Authentication enabled.
AppRole 'server_app_role' created.
AppRole 'migrator_app_role' created.

approle-vapor-example % swift run Operations credentials migrator

Generating Approle credentials for 'migrator' app...
SecretID successfully written to ./approle_secret_id.txt
migrator app roleID: 323184a0-7665-f89f-6350-aa2c4005dc4c

approle-vapor-example % ROLE_ID=323184a0-7665-f89f-6350-aa2c4005dc4c SECRET_ID_FILEPATH=./approle_secret_id.txt swift run Migrator

info migrator : [VaultCourier] login authorized
Migration successfull! 'todos' table created.