% curl -i -X POST localhost:8080/todos -d'{"title": "Book Hotel in Cartagena"}'
HTTP/1.1 201 Created
Content-Type: application/json; charset=utf-8
Content-Length: 156
Server: todos-postgres-tutorial

{"id":"21B6D74B-102F-45D6-B116-40966BC8C4F0","url":"http:\/\/localhost:8080\/todos\/21B6D74B-102F-45D6-B116-40966BC8C4F0","title":"Book Hotel in Cartagena"}%