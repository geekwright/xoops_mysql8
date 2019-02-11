# XoopsCore25 via Docker for testing

Features
- geekwright/XoopsCore25 mysql8
- Apache
- PHP 7.3
- MySQL 8.0

```
docker build -t xoopstest .
docker-compose up
```

Apache is exposed on localhost:8080
phpMyAdmin is available on localhost:8181

When installing XOOPS using this image, in the Database setup use these values:
- Server hostname: "db" (not localhost)
- User name: "admin"
- Password: "password"

- Database name: "xoops"
