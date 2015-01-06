# AppFirst Collector
#
# VERSION	0.0.1

FROM		ubuntu:latest
MAINTAINER	AppFirst Dev <dev@appfirst.com>

RUN apt-get update && apt-get install -y supervisor wget
RUN wget http://wwws.appfirst.com/packages/initial/1/appfirst-x86_64.deb && dpkg -i appfirst-x86_64.deb && rm appfirst-x86_64.deb


COPY appfirst.conf /etc/supervisor/conf.d/appfirst.conf
COPY startup.sh /startup.sh
