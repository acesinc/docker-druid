Dockerfile for Druid

Modified version of official druid.io Docker image that remove MySQL and
Zookeeper and expects them to be provided by external containers instead.

This image expects the MySQL database to be initialized with the Druid
metadata tables.  You can accomplish this by starting up your MySQL container, then running:

    docker run --link <mysql-container-name>:mysql worrel/docker-druid ./init-metadata.sh
