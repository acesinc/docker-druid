Dockerfile for Druid

Modified version of official druid.io Docker image that has the following changes:
 * MySQL runs in it's own container
 * Zookeeper runs in it's own container
 * Added Kafka which runs in it's own container 
 * Upgraded to Druid 0.7.0

You can now use docker-compose to run the druid cluster. To do so, you can run
the following steps. 

    git clone git@github.com:andrewserff/docker-druid.git
    cd docker-druid
    docker-compose up -d mysql
    
This image expects the MySQL database to be initialized with the Druid
metadata tables.  You can accomplish this by starting up your MySQL container, then running:

    docker run --link dockerdruid_mysql_1:mysql dockerdruid_druid ./init-metadata.sh

After you have configured mysql, you can start the rest of the cluster
  
    docker-compose up

If you want the cluster to run in the background, do the following:

    docker-compose up -d

