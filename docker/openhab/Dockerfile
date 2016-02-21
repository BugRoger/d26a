FROM develar/java:8u45

ENV OPENHAB_VERSION=1.8.1

RUN apk add --update curl ca-certificates && \
    cd /tmp && \
    mkdir -p /opt/openhab /opt/openhab/addons /opt/openhab/addons-available /opt/openhab/demo && \
    curl -sLo runtime.zip \
        https://bintray.com/artifact/download/openhab/bin/distribution-${OPENHAB_VERSION}-runtime.zip && \
        unzip runtime.zip -d /opt/openhab && \
    curl -sLo addons.zip \
        https://bintray.com/artifact/download/openhab/bin/distribution-${OPENHAB_VERSION}-addons.zip && \
        unzip addons.zip -d /opt/openhab/addons-available && \
    apk del curl ca-certificates  && \
    rm -rf /tmp/* /var/cache/apk/*

COPY entrypoint.sh /opt/openhab/entrypoint.sh
RUN chmod +x /opt/openhab/entrypoint.sh
VOLUME /opt/openhab/configurations
EXPOSE 8080 8443
ENTRYPOINT ["/opt/openhab/entrypoint.sh"]

RUN mkdir /opt/openhab/logs
