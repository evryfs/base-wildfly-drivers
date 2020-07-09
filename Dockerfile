FROM jboss/wildfly:20.0.0.Final

WORKDIR /opt/jboss/wildfly

# Prepare module directories for Oracle driver and IBM MQ client
RUN mkdir -p modules/oracle/jdbc/main &&\
    mkdir -p modules/com/ibm/mqgetclient/main

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