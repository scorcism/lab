# Simple HomeLab tools scripts and config files

## Local fileserver like google cloud

```yml
version: '3.9'

services:
  nextcloud:
    image: nextcloud
    container_name: nextcloud
    restart: unless-stopped
    ports:
      - "8082:80"
    volumes:
      - ~/files:/var/www/html/data 
    environment:
      - MYSQL_DATABASE=files
      - MYSQL_USER=scor32k
      - MYSQL_PASSWORD=abhishek
      - MYSQL_HOST=db
      - REDIS_HOST=redis
    depends_on:
      - db
      - redis

  db:
    image: mariadb
    container_name: nextcloud_db
    restart: unless-stopped
    environment:
      - MYSQL_DATABASE=files
      - MYSQL_USER=scor32k
      - MYSQL_PASSWORD=abhishek
      - MYSQL_ROOT_PASSWORD=abhishek
    volumes:
      - db_data:/var/lib/mysql

  redis:
    image: redis:alpine
    container_name: nextcloud_redis
    restart: unless-stopped

volumes:
  db_data:
```

## Real-Time metrics 

Light weight and easy setup

```sh
wget -O /tmp/netdata-kickstart.sh https://get.netdata.cloud/kickstart.sh && sh /tmp/netdata-kickstart.sh --disable-telemetry
```

