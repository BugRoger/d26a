FROM ubuntu:trusty
MAINTAINER BugRoger

RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections && \
  apt-get install -qy software-properties-common && \
  add-apt-repository ppa:deluge-team/ppa && \
  apt-get update -q && \
  apt-get install -qy deluged deluge-web deluge-console && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ADD deluge-config /usr/bin/ 

RUN mkdir -p /config /data 

VOLUME /config
VOLUME /data

# Torrent port
EXPOSE 53160
EXPOSE 53160/udp

# WebUI
EXPOSE 80 

# Daemon
EXPOSE 58846

CMD ["deluged", "-d", "-c", "/config"]
