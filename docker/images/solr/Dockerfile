# Image for Solr configured for CKAN

FROM solr:8.11
LABEL org.opencontainers.image.authors="Yoda team"

ENV CKAN_VERSION=2.11.2
ENV SOLR_CONFIG_DIR="/opt/solr/server/solr/configsets"

# Create a CKAN configset based on the default one
USER root
RUN cp -R $SOLR_CONFIG_DIR/_default $SOLR_CONFIG_DIR/ckan

# Install basic components
RUN apt update && \
    apt install -y git vim && \
    apt-get -q clean && \
    rm -rf /var/lib/apt/lists/*

# Download CKAN (for the schema)
RUN cd /usr/lib && \
    git clone https://github.com/ckan/ckan.git && \
    cd ckan && \
    git checkout "ckan-$CKAN_VERSION"

# Change the CKAN configset to use the CKAN schema, and enable Query Elevation
USER root
ADD solrconfig.xml /opt/solr-8.11.4/server/solr/configsets/ckan/conf/solrconfig.xml
RUN ln -s /usr/lib/ckan/ckan/config/solr/schema.xml $SOLR_CONFIG_DIR/ckan/conf/schema.xml && \
    perl -n -i.bak -e 'print unless /defaultSearchField/ or /solrQueryParser/' $SOLR_CONFIG_DIR/ckan/conf/schema.xml && \
    cp $SOLR_CONFIG_DIR/ckan/conf/schema.xml $SOLR_CONFIG_DIR/ckan/conf/managed-schema && \
    cp /opt/solr/server/solr/configsets/sample_techproducts_configs/conf/elevate.xml $SOLR_CONFIG_DIR/ckan/conf/elevate.xml

USER solr
CMD ["sh", "-c", "solr-precreate ckan $SOLR_CONFIG_DIR/ckan"]
