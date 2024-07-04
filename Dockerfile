ARG USERNAME
ARG UID

# builder stage
FROM ubuntu:22.04 AS builder
ENV USERNAME=${USERNAME:-duo}
ENV UID=${UID:-40001}

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

RUN adduser --disabled-password --gecos '' $USERNAME -u $UID

RUN cd /tmp && \
	wget https://dl.duosecurity.com/duoauthproxy-latest-src.tgz && \
	tar xfvz duoauthproxy-latest-src.tgz && \
	rm duoauthproxy-latest-src.tgz && \
	cd duoauthproxy-* && \
	make && \
	cd duoauthproxy-build && \
	./install --install-dir /opt/duoauthproxy --service-user duo --log-group duo --create-init-script yes

# Final stage
FROM ubuntu:22.04
COPY --from=builder /opt/duoauthproxy /opt/duoauthproxy

LABEL ubuntu="22.04"

ARG USERNAME
ARG UID
ENV USERNAME=${USERNAME:-duo}
ENV UID=${UID:-40001}
ENV PATH="${PATH}:/opt/duoauthproxy/bin"
ENV RESOLVER=

RUN adduser --disabled-password --gecos '' $USERNAME -u $UID

RUN DEBIAN_FRONTEND=noninteractive apt-get -y update && apt-get install net-tools

EXPOSE 1812/udp
WORKDIR /scripts
ADD scripts /scripts
ADD README.md /README.md

RUN chown $USERNAME:$USERNAME /scripts && chown $USERNAME:$USERNAME /opt/duoauthproxy/conf -R
USER $USERNAME:$USERNAME

ENTRYPOINT ["/scripts/entrypoint.sh"]

HEALTHCHECK CMD netstat -ulpen | grep 1812 > /dev/null; if [ 0 != $? ]; then exit 1; fi;

LABEL description="Install Duo RADIUS Proxy"


LABEL org.label-schema.schema-version="1.0"
LABEL org.label-schema.name="Duo Auth Proxy"
LABEL org.label-schema.vendor="LearningToPi.com"
LABEL org.label-schema.description="Duo RADIUS Auth Proxy packaged to run as a Docker container."
LABEL org.label-schema.usage="/README.md"
LABEL org.label-schema.url="https://www.learningtopi.com/"
LABEL org.label-schema.vcs-url="https://github.com/LearningToPi/duo-proxy"
LABEL org.label-schema.vcs-ref="0965349"
LABEL org.label-schema.version="1.0.3"
LABEL org.label-schema.release="duoproxy-6.3.0"
LABEL org.label-schema.architecture="aarch64"
LABEL org.label-schema.changelog-url="https://github.com/LearningToPi/duo-proxy/blob/main/release_notes/v1.0.1.md"

LABEL org.label-schema.docker.cmd='docker run --name duo-proxy -d -p 1812:1812 -v [path]/authproxy.cfg:/opt/duoauthproxy/conf/authproxy.cfg -v [path]/log/:/opt/duoauthproxy/log/ learningtopi/duo-proxy'
