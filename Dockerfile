FROM alpine:3.8

ARG SOURCE_COMMIT
ARG DOCKERFILE_PATH
ARG SOURCE_TYPE

ENV CONSUL="consul" \
    CONSUL_VERSION="1.2.2" \
    CONTAINERPILOT_VER="3.8.0" CONTAINERPILOT="/etc/containerpilot.json5" \
    NODE_EXPORTER_VERSION="0.16.0" \
    CONSUL_EXPORTER_VERSION="0.3.0" \
    SHELL="/bin/bash"

# Alpine packages
RUN apk --no-cache add curl bash ca-certificates jq \
# The Consul binary
    && export CONSUL_CHECKSUM=7fa3b287b22b58283b8bd5479291161af2badbc945709eb5412840d91b912060 \
    && export archive=consul_${CONSUL_VERSION}_linux_amd64.zip \
    && curl -Lso /tmp/${archive} https://releases.hashicorp.com/consul/${CONSUL_VERSION}/${archive} \
    && echo "${CONSUL_CHECKSUM}  /tmp/${archive}" | sha256sum -c \
    && cd /bin \
    && unzip /tmp/${archive} \
    && chmod +x /bin/consul \
    && rm /tmp/${archive} \
# Add Containerpilot and set its configuration
    && export CONTAINERPILOT_CHECKSUM=84642c13683ddae6ccb63386e6160e8cb2439c26 \
    && curl -Lso /tmp/containerpilot.tar.gz \
         "https://github.com/joyent/containerpilot/releases/download/${CONTAINERPILOT_VER}/containerpilot-${CONTAINERPILOT_VER}.tar.gz" \
    && echo "${CONTAINERPILOT_CHECKSUM}  /tmp/containerpilot.tar.gz" | sha1sum -c \
    && tar zxf /tmp/containerpilot.tar.gz -C /usr/local/bin \
    && rm /tmp/containerpilot.tar.gz \
# Add Prometheus exporter
    && curl --fail -sL https://github.com/prometheus/consul_exporter/releases/download/v${CONSUL_EXPORTER_VERSION}/consul_exporter-${CONSUL_EXPORTER_VERSION}.linux-amd64.tar.gz |\
    tar -xzO -f - consul_exporter-${CONSUL_EXPORTER_VERSION}.linux-amd64/consul_exporter > /usr/local/bin/consul_exporter \
    && chmod +x /usr/local/bin/consul_exporter \
    && curl --fail -sL https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VERSION}/node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz |\
    tar -xzO -f - node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64/node_exporter > /usr/local/bin/node_exporter \
    && chmod +x /usr/local/bin/node_exporter

# configuration files and bootstrap scripts
COPY etc/containerpilot.json5 /etc/
COPY etc/consul.hcl /etc/consul/consul.hcl.orig
COPY bin/* /usr/local/bin/

# Put Consul data on a separate volume to avoid filesystem performance issues
# with Docker image layers. Not necessary on Triton, but...
VOLUME ["/data"]

# We don't need to expose these ports in order for other containers on Triton
# to reach this container in the default networking environment, but if we
# leave this here then we get the ports as well-known environment variables
# for purposes of linking.
EXPOSE 8300 8301 8301/udp 8302 8302/udp 8400 8500 53 53/udp

CMD ["/usr/local/bin/containerpilot"]

HEALTHCHECK --interval=60s --timeout=10s --retries=3 --start-period=15m CMD curl -sf http://127.0.0.1:8500/v1/status/peers || exit 1

LABEL maintainer="Patrick Double <pat@patdouble.com>" \
      org.label-schema.license="MPL-2.0" \
      org.label-schema.vendor="https://bitbucket.org/double16" \
      org.label-schema.name="Consul ${CONSUL_VERSION} with the Autopilot Pattern and Prometheus Monitoring" \
      org.label-schema.url="https://bitbucket.org/double16/autopilotpattern-consul" \
      org.label-schema.docker.dockerfile="${DOCKERFILE_PATH}/Dockerfile" \
      org.label-schema.vcs-ref=$SOURCE_COMMIT \
      org.label-schema.vcs-type=$SOURCE_TYPE \
      org.label-schema.vcs-url="https://bitbucket.org/double16/autopilotpattern-consul.git"
