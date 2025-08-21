todos-postgres-tutorial % PKL_EXEC=./pkl swift run Operations provision Sources/Operations/Pkl/Stage/vaultAdminConfig.pkl

Policy 'migrator' written.
Policy 'todos' written.
Database secrets engine enabled at 'database'.
Static role 'static_server_role' created.
Dynamic role 'dynamic_migrator_role' created.
AppRole Authentication enabled.
AppRole 'server_app_role' created.
AppRole 'migrator_app_role' created.

todos-postgres-tutorial % swift run Operations credentials migrator Sources/Operations/Pkl/Stage/vaultAdminConfig.pkl

Generating Approle credentials for 'migrator' app...
SecretID successfully written to ./approle_secret_id.txt
migrator app roleID: 323184a0-7665-f89f-6350-aa2c4005dc4c

todos-postgres-tutorial % ROLE_ID=323184a0-7665-f89f-6350-aa2c4005dc4c SECRET_ID_FILEPATH=./approle_secret_id.txt swift run Migrator

info migrator : [VaultCourier] login authorized
Migration successfull! 'todos' table created.

todos-postgres-tutorial % PKL_EXEC=./pkl swift run Operations credentials todo Sources/Operations/Pkl/Stage/vaultAdminConfig.pkl
Generating Approle credentials for 'todo' app...
SecretID successfully written to ./approle_secret_id.txt
todo app roleID: 8039d04e-f609-2733-fe7a-ef682d709548

todos-postgres-tutorial % PKL_EXEC=./pkl ROLE_ID=8039d04e-f609-2733-fe7a-ef682d709548 SECRET_ID_FILEPATH=./approle_secret_id.txt swift run App 

info todos-postgres-tutorial : [VaultCourier] login authorized
info todos-postgres-tutorial : [HummingbirdCore] Server started and listening on 127.0.0.1:8080


