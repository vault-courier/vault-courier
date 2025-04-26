--===----------------------------------------------------------------------===//
--  Copyright (c) 2025 Javier Cuesta
--
--  Licensed under the Apache License, Version 2.0 (the "License");
--  you may not use this file except in compliance with the License.
--  You may obtain a copy of the License at
--
--  http://www.apache.org/licenses/LICENSE-2.0
--
--  Unless required by applicable law or agreed to in writing, software
--  distributed under the License is distributed on an "AS IS" BASIS,
--  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
--  See the License for the specific language governing permissions and
--  limitations under the License.
--===----------------------------------------------------------------------===//

-- Stop immediately on first error
\set ON_ERROR_STOP on

\set vault_role vault_user
\set initpass 'init_password'
\set db test_database

\set static_role test_static_role_username

CREATE ROLE :vault_role
WITH SUPERUSER LOGIN PASSWORD :'initpass';

-- Grant connection access to vault role to the test database
GRANT CONNECT ON DATABASE :db TO :vault_role;

CREATE ROLE :static_role
LOGIN PASSWORD :'initpass';

GRANT CONNECT ON DATABASE :db TO :static_role;