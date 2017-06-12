FROM alpine:3.5

# Alpine packages
RUN apk --no-cache \
    add \
        curl \
        bash \
        ca-certificates

# The Consul binary
ENV CONSUL_VERSION=0.7.2
RUN export CONSUL_CHECKSUM=aa97f4e5a552d986b2a36d48fdc3a4a909463e7de5f726f3c5a89b8a1be74a58 \
    && export archive=consul_${CONSUL_VERSION}_linux_amd64.zip \
    && curl -Lso /tmp/${archive} https://releases.hashicorp.com/consul/${CONSUL_VERSION}/${archive} \
    && echo "${CONSUL_CHECKSUM}  /tmp/${archive}" | sha256sum -c \
    && cd /bin \
    && unzip /tmp/${archive} \
    && chmod +x /bin/consul \
    && rm /tmp/${archive}

# The Consul web UI
RUN export CONSUL_UI_CHECKSUM=c9d2a6e1d1bb6243e5fd23338d92f5c71cdf0a4077f7fcc95fd81800fa1f42a9 \
    && export archive=consul_${CONSUL_VERSION}_web_ui.zip \
    && curl -Lso /tmp/${archive} https://releases.hashicorp.com/consul/${CONSUL_VERSION}/${archive} \
    && echo "${CONSUL_UI_CHECKSUM}  /tmp/${archive}" | sha256sum -c \
    && mkdir /ui \
    && cd /ui \
    && unzip /tmp/${archive} \
    && rm /tmp/${archive}

# Add Containerpilot and set its configuration
ENV CONTAINERPILOT_VERSION 2.7.3
ENV CONTAINERPILOT file:///etc/containerpilot.json

RUN export CONTAINERPILOT_CHECKSUM=2511fdfed9c6826481a9048e8d34158e1d7728bf \
    && export archive=containerpilot-${CONTAINERPILOT_VERSION}.tar.gz \
    && curl -Lso /tmp/${archive} \
         "https://github.com/joyent/containerpilot/releases/download/${CONTAINERPILOT_VERSION}/${archive}" \
    && echo "${CONTAINERPILOT_CHECKSUM}  /tmp/${archive}" | sha1sum -c \
    && tar zxf /tmp/${archive} -C /usr/local/bin \
    && rm /tmp/${archive}

# Add Prometheus exporter
RUN curl --fail -sL https://github.com/prometheus/consul_exporter/releases/download/v0.3.0/consul_exporter-0.3.0.linux-amd64.tar.gz |\
    tar -xzO -f - consul_exporter-0.3.0.linux-amd64/consul_exporter > /usr/local/bin/consul_exporter &&\
    chmod +x /usr/local/bin/consul_exporter

# configuration files and bootstrap scripts
COPY etc/containerpilot.json etc/
COPY etc/consul.json etc/consul/
COPY bin/* /usr/local/bin/

# Put Consul data on a separate volume to avoid filesystem performance issues
# with Docker image layers. Not necessary on Triton, but...
VOLUME ["/data"]

# We don't need to expose these ports in order for other containers on Triton
# to reach this container in the default networking environment, but if we
# leave this here then we get the ports as well-known environment variables
# for purposes of linking.
EXPOSE 8300 8301 8301/udp 8302 8302/udp 8400 8500 53 53/udp

#ENV GOMAXPROCS 2
ENV SHELL /bin/bash

CMD /usr/local/bin/containerpilot /bin/consul agent -server -bootstrap-expect ${CONSUL_BOOTSTRAP_EXPECT:-3} -config-dir=/etc/consul -ui-dir=/ui

HEALTHCHECK --interval=60s --timeout=10s --retries=3 CMD curl -f http://127.0.0.1:8500/ || exit 1

LABEL org.label-schema.build-date=$BUILD_DATE \
      org.label-schema.license="MPL-2.0" \
      org.label-schema.vendor="https://bitbucket.org/double16" \
      org.label-schema.name="Consul with the Autopilot Pattern and Prometheus Monitoring" \
      org.label-schema.url="https://bitbucket.org/double16/autopilotpattern-consul" \
      org.label-schema.docker.dockerfile="Dockerfile" \
      org.label-schema.vcs-ref=$SOURCE_REF \
      org.label-schema.vcs-type='git' \
      org.label-schema.vcs-url="https://bitbucket.org/double16/autopilotpattern-consul.git"
