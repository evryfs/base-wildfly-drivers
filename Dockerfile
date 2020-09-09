# Use latest jboss/base-jdk:8 image as the base
FROM jboss/base-jdk:8

# Set the WILDFLY_VERSION env variable
ENV WILDFLY_VERSION 20.0.1.Final
ENV WILDFLY_SHA1 95366b4a0c8f2e6e74e3e4000a98371046c83eeb
ENV JBOSS_HOME /opt/jboss/wildfly

USER root

# Add the WildFly distribution to /opt, and make wildfly the owner of the extracted tar content
# Make sure the distribution is available from a well-known place
RUN cd $HOME \
    && curl -O https://download.jboss.org/wildfly/$WILDFLY_VERSION/wildfly-$WILDFLY_VERSION.tar.gz \
    && sha1sum wildfly-$WILDFLY_VERSION.tar.gz | grep $WILDFLY_SHA1 \
    && tar xf wildfly-$WILDFLY_VERSION.tar.gz \
    && mv $HOME/wildfly-$WILDFLY_VERSION $JBOSS_HOME \
    && rm wildfly-$WILDFLY_VERSION.tar.gz \
    && chown -R jboss:0 ${JBOSS_HOME} \
    && chmod -R g+rw ${JBOSS_HOME}

# Ensure signals are forwarded to the JVM process correctly for graceful shutdown
ENV LAUNCH_JBOSS_IN_BACKGROUND true

USER jboss

# Expose the ports we're interested in
EXPOSE 8080

# Set the default command to run on boot
# This will boot WildFly in the standalone mode and bind to all interface
#CMD ["/opt/jboss/wildfly/bin/standalone.sh", "-b", "0.0.0.0"]

WORKDIR /opt/jboss/wildfly

# Prepare module directories for Oracle driver and IBM MQ client
RUN mkdir -p modules/oracle/jdbc/main &&\
    mkdir -p modules/com/ibm/mqgetclient/main

# Copy container entrypoint script
COPY --chown=jboss:root ./entrypoint.sh bin/
RUN chmod +x bin/entrypoint.sh

# Install modules
COPY --chown=jboss:root lib/modules/oracle/jdbc/main/* modules/oracle/jdbc/main/
COPY --chown=jboss:root lib/modules/com/ibm/mqgetclient/main/* modules/com/ibm/mqgetclient/main/

# Replace standalone-full.xml file with the one optimized for deployment of TPS components.
# Changes:
# - H2 example datasource and corresponding drivers removed;
# - Oracle example XA datasource with corresponding drivers added;
# - Active MQ configuration removed;
# - IMB Webshere resource adapter added with example connection definitions and admin objects.
COPY --chown=jboss:root standalone/standalone-full.xml standalone/configuration/

# Deploy IBM WebSphere resource adapter
COPY --chown=jboss:root lib/wmq.jmsra.rar standalone/deployments/

# Run container with standalone xml file optimized for deployment of TPS components
CMD ["/opt/jboss/wildfly/bin/standalone.sh", "-c", "standalone-full.xml", "-b", "0.0.0.0"]