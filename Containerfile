ARG SOURCE_DISTRO
ARG SOURCE_TAG
ARG USERNAME=${USERNAME:-duo}
ARG UID=${UID:-40001}

# builder stage
FROM docker.io/${SOURCE_DISTRO}:${SOURCE_TAG} AS builder

ARG USERNAME=${USERNAME:-duo}
ARG UID=${UID:-40001}

SHELL ["/bin/bash", "-c"]

RUN     DEBIAN_FRONTEND=noninteractive apt-get -y update && \
        DEBIAN_FRONTEND=noninteractive apt-get -y upgrade  && \
        DEBIAN_FRONTEND=noninteractive apt-get -y install tzdata

RUN     DEBIAN_FRONTEND=noninteractive apt-get -y update && \
        DEBIAN_FRONTEND=noninteractive apt-get install  build-essential \
						        libffi-dev \
						        perl \
						        zlib1g-dev \
							wget -y

RUN useradd -u $UID $USERNAME

RUN cd /tmp && \
	wget https://dl.duosecurity.com/duoauthproxy-latest-src.tgz && \
	tar xfvz duoauthproxy-latest-src.tgz && \
	rm duoauthproxy-latest-src.tgz && \
	cd duoauthproxy-* && \
	make && \
	cd duoauthproxy-build && \
	./install --install-dir /opt/duoauthproxy --service-user duo --log-group duo --create-init-script yes

# Final stage
FROM docker.io/${SOURCE_DISTRO}:${SOURCE_TAG}
ARG USERNAME=${USERNAME:-duo}
ARG UID=${UID:-40001}

COPY --from=builder /opt/duoauthproxy /opt/duoauthproxy

RUN useradd -u $UID $USERNAME

RUN DEBIAN_FRONTEND=noninteractive apt-get -y update && apt-get install net-tools

ENV PATH="${PATH}:/opt/duoauthproxy/bin"
ENV RESOLVER=

EXPOSE 1812/udp
WORKDIR /scripts
ADD scripts /scripts
ADD README.md /README.md

RUN chown $USERNAME:$USERNAME /scripts && chown $USERNAME:$USERNAME /opt/duoauthproxy/conf -R
USER $USERNAME:$USERNAME

ENTRYPOINT ["/scripts/entrypoint.sh"]

HEALTHCHECK CMD netstat -ulpen | grep 1812 > /dev/null; if [ 0 != $? ]; then exit 1; fi;

LABEL org.opencontainers.image.title="Duo Auth Proxy"
LABEL org.opencontainers.image.description="Duo RADIUS Auth Proxy packaged to run as a Docker container."
LABEL org.opencontainers.image.ref.name="learningtopi/duo-proxy"
LABEL org.opencontainers.image.version="$BUILD_VERSION"
LABEL org.opencontainers.image.source="https://github.com/LearningToPi/vsftpd_docker"
LABEL org.opencontainers.image.vendor="LearningToPi.com"
LABEL org.opencontainers.image.base.name="docker.io/$SOURCE_DISTRO:$SOURCE_TAG"
LABEL org.opencontainers.image.documentation="/README.md"

LABEL org.label-schema.docker.cmd='docker run --name duo-proxy -d -p 1812:1812 -v [path]/authproxy.cfg:/opt/duoauthproxy/conf/authproxy.cfg -v [path]/log/:/opt/duoauthproxy/log/ learningtopi/duo-proxy'
