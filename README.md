# Dockerfile for Druid

Modified version of official druid.io Docker image that has the following changes:
 * MySQL runs in it's own container
 * Zookeeper runs in it's own container
 * Added Kafka which runs in it's own container 
 * Upgraded to Druid 0.7.0
 * Each service config is now contained in config files instead of as properties to the JVM

You can now use docker-compose to run the druid cluster. To do so, you can run
the following steps. 

## Getting Started
Getting up and running with our druid cluster using docking is pretty easy.  
### Install Docker
If you haven't already, you need to install Docker.  You can find a quick guide [here](https://github.com/druid-io/docker-druid/blob/master/docker-install.md). 

### Make sure boot2docker is running
I'm using boot2docker on OS X, so we wante to make sure it is running before trying to start our druid cluster. Do the following:

	boot2docker up
	eval "$(boot2docker shellinit)"
	
### Now start our druid cluster

    git clone git@github.com:andrewserff/docker-druid.git
    cd docker-druid
    docker-compose up

If you want the cluster to run in the background, do the following:

    docker-compose up -d

## Testing things out
Assuming `boot2docker ip` returns 192.168.59.103, you should be able to access the [coordinator console](http://192.168.59.103:8081/) at:

    http://192.168.59.103:8081/

The example running inside your cluster is a wikipedia example that expects to 
receive data via a kafka stream. This is the same example found in the druid docs here: 
http://druid.io/docs/latest/Tutorial:-Loading-Streaming-Data.html

You will need to download kafka and have that installed
locally on your machine to produce data for the example.  After you have installed kafka,
we need to set up a queue. Make sure your cluster is running, then run this command:

    ./bin/kafka-topics.sh --create --zookeeper `boot2docker ip`:2181 --replication-factor 1 --partitions 1 --topic wikipedia

Next we are going to start a producer console just for testing:

    ./bin/kafka-console-producer.sh --broker-list `boot2docker ip`:9092 --topic wikipedia

Now you can send some data.  Copy and paste the following data into your producer console:

    {"timestamp": "2013-08-31T01:02:33Z", "page": "Gypsy Danger", "language" : "en", "user" : "nuclear", "unpatrolled" : "true", "newPage" : "true", "robot": "false", "anonymous": "false", "namespace":"article", "continent":"North America", "country":"United States", "region":"Bay Area", "city":"San Francisco", "added": 57, "deleted": 200, "delta": -143}
    {"timestamp": "2013-08-31T03:32:45Z", "page": "Striker Eureka", "language" : "en", "user" : "speed", "unpatrolled" : "false", "newPage" : "true", "robot": "true", "anonymous": "false", "namespace":"wikipedia", "continent":"Australia", "country":"Australia", "region":"Cantebury", "city":"Syndey", "added": 459, "deleted": 129, "delta": 330}
    {"timestamp": "2013-08-31T07:11:21Z", "page": "Cherno Alpha", "language" : "ru", "user" : "masterYi", "unpatrolled" : "false", "newPage" : "true", "robot": "true", "anonymous": "false", "namespace":"article", "continent":"Asia", "country":"Russia", "region":"Oblast", "city":"Moscow", "added": 123, "deleted": 12, "delta": 111}
    {"timestamp": "2013-08-31T11:58:39Z", "page": "Crimson Typhoon", "language" : "zh", "user" : "triplets", "unpatrolled" : "true", "newPage" : "false", "robot": "true", "anonymous": "false", "namespace":"wikipedia", "continent":"Asia", "country":"China", "region":"Shanxi", "city":"Taiyuan", "added": 905, "deleted": 5, "delta": 900}
    {"timestamp": "2013-08-31T12:41:27Z", "page": "Coyote Tango", "language" : "ja", "user" : "stringer", "unpatrolled" : "true", "newPage" : "false", "robot": "true", "anonymous": "false", "namespace":"wikipedia", "continent":"Asia", "country":"Japan", "region":"Kanto", "city":"Tokyo", "added": 1, "deleted": 10, "delta": -9}

When you run this data through, you should see a log message in your druid window like:

    ...
    druid_1     | 2015-03-30T22:52:44,908 INFO [chief-wikipedia] io.druid.server.coordination.BatchDataSegmentAnnouncer - Announcing segment[wikipedia_2013-08-31T00:00:00.000Z_2013-09-01T00:00:00.000Z_2013-08-31T00:00:00.000Z] at path[/druid/segments/localhost:8081/2015-03-30T22:52:44.906Z0]
    ...

Now, you can execute a query against your realtime node like so:

    curl -XPOST -H'Content-type: application/json' "http://192.168.59.103:8084/druid/v2/?pretty" -d'{"queryType":"timeBoundary","dataSource":"wikipedia"}'

And you should get back data like:

    [ {
        "timestamp" : "2013-08-31T01:02:33.000Z",
        "result" : {
            "minTime" : "2013-08-31T01:02:33.000Z",
            "maxTime" : "2013-08-31T12:41:27.000Z"
        }
    } ]

Yay! It works!

## Creating your own processing
If you want to change the realtime processing, you need to either edit the realtime.spec,
or create your own, add it to the Dockerfile, and change the runtime.properties for the 
realtime service to load that file. 

## Troubleshooting
Logging into MySQL:

    mysql --host=`boot2docker ip` --port=3306 -u root -psecret druid
    mysql --host=`boot2docker ip` --port=3306 -u druid -pdruid druid
    
If mysql won't start, you may need to try and remove the .data directory. Our Docker configuration uses a volume mounted from our local filesystem to the Docker Container.  Sometimes, boot2docker won't allow the container to write to that filesytem.  So usually this fixes it:

	cd docker-druid
	rm -rf .data
	docker-compose up
	
I have had to remove and restart it multiple times before to get it to work for some reason as well. 


## Known issues
I have been unable to get MySQL to use a volume that is shared on my OS X filesystem.
So if you destroy your container, then your mysql data will be gone. Anytime I try 
to use a shared, mysql will not start because it doesn't have permissions to write to the directory. 
If anyone know how to fix this, let me know!  I believe it is related to this boot2docker issue: 
https://github.com/boot2docker/boot2docker/issues/581

## Next Steps
* Possibly split each service type out into their own compose groups so you could start multiple instances of say the historical or realtime nodes. 
* Stop using local storage for deep storage.  
* Look over the production cluster guide and see what we can pull into this config