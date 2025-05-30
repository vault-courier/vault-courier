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