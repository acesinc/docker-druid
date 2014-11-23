FROM dockerfile/java:oracle-java7

# Update packages
RUN apt-get update

# Supervisor
RUN apt-get install -y supervisor

# Maven
RUN wget -q -O - http://mirror.olnevhost.net/pub/apache/maven/maven-3/3.2.3/binaries/apache-maven-3.2.3-bin.tar.gz | tar -xzf - -C /usr/local
RUN ln -s /usr/local/apache-maven-3.2.3 /usr/local/apache-maven
RUN ln -s /usr/local/apache-maven/bin/mvn /usr/local/bin/mvn

# git
RUN apt-get install -y git

# Druid system user
RUN adduser --system --group --no-create-home druid
RUN mkdir -p /var/lib/druid
RUN chown druid:druid /var/lib/druid

# Pre-cache Druid dependencies
RUN mvn dependency:get -DremoteRepositories=https://metamx.artifactoryonline.com/metamx/pub-libs-releases-local -Dartifact=io.druid:druid-services:0.6.160

# Druid (from source)
ENV DRUID_VERSION master
RUN git config --global user.email docker@druid.io
# trigger rebuild only if branch changed
ADD https://api.github.com/repos/metamx/druid/git/refs/heads/$DRUID_VERSION druid-version.json
RUN git clone -q --branch $DRUID_VERSION --depth 1 https://github.com/metamx/druid.git /tmp/druid
RUN mkdir -p /usr/local/druid/lib /usr/local/druid/repository
WORKDIR /tmp/druid
# package and install Druid locally
RUN mvn -B release:prepare -DpushChanges=false -DpreparationGoals=clean -DreleaseVersion=$DRUID_VERSION -DdevelopmentVersion=$DRUID_VERSION-SNAPSHOT release:perform -Darguments="-DskipTests=true -Dmaven.javadoc.skip=true" -DlocalCheckout=true -Dgoals=install

RUN cp -f target/checkout/services/target/druid-services-$DRUID_VERSION-selfcontained.jar /usr/local/druid/lib
# pull dependencies for Druid extensions
RUN java "-Ddruid.extensions.coordinates=[\"io.druid.extensions:druid-s3-extensions:$DRUID_VERSION\", \"io.druid.extensions:mysql-metadata-storage:$DRUID_VERSION\",\"io.druid.extensions:druid-kafka-eight:$DRUID_VERSION\"]" -Ddruid.extensions.localRepository=/usr/local/druid/repository "-Ddruid.extensions.remoteRepositories=[\"file:///root/.m2/repository/\",\"http://repo1.maven.org/maven2/\",\"https://metamx.artifactoryonline.com/metamx/pub-libs-releases-local\"]" -cp /usr/local/druid/lib/* io.druid.cli.Main tools pull-deps

WORKDIR /

# Setup supervisord
ADD supervisord.conf /etc/supervisor/conf.d/supervisord.conf
RUN echo $DRUID_VERSION
RUN perl -pi -e "s/[\\$]DRUID_VERSION/$DRUID_VERSION/g" /etc/supervisor/conf.d/supervisord.conf

# Include metadata store init script
ADD init-metadata.sh /var/lib/druid/init-metadata.sh

# Clean up
RUN apt-get clean && rm -rf /tmp/* /var/tmp/*

# Expose ports:
# - 8081: HTTP (coordinator)
# - 8082: HTTP (broker)
# - 8083: HTTP (historical)
EXPOSE 8080
EXPOSE 8081
EXPOSE 8082
EXPOSE 8083
EXPOSE 8084

WORKDIR /var/lib/druid

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
