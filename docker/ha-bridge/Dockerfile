FROM anapsix/alpine-java:jre

ENV HABRIDGE_VERSION=1.4.2

RUN apk add --update curl ca-certificates && \
    curl -sLo /ha-bridge.jar \
        https://github.com/bwssytems/ha-bridge/releases/download/v${HABRIDGE_VERSION}/ha-bridge-${HABRIDGE_VERSION}.jar && \ 
    apk del curl ca-certificates  && \
    rm -rf /tmp/* /var/cache/apk/*

ADD data /data

EXPOSE 8080 50000 1900
ENTRYPOINT ["java", "-jar", "/ha-bridge.jar"]
