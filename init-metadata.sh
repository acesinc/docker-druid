#!/bin/sh

java \
  -cp /usr/local/druid/lib/druid-services-*-selfcontained.jar \
  -Ddruid.extensions.coordinates=[\"io.druid.extensions:mysql-metadata-storage:$DRUID_VERSION\"] \
  -Ddruid.metadata.storage.type=mysql \
  io.druid.cli.Main tools metadata-init \
    --connectURI="jdbc:mysql://mysql:$MYSQL_PORT_3306_TCP_PORT/druid" \
    --user=druid --password=druid
