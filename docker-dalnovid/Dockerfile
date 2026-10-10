# Dalnovid server image. Binaries come from the Release workflow,
# staged as bin/<arch>/{hbbs,hbbr} (amd64, arm64, armv7).
FROM scratch
ARG TARGETARCH
ARG TARGETVARIANT
COPY bin/${TARGETARCH}${TARGETVARIANT}/hbbs /usr/bin/hbbs
COPY bin/${TARGETARCH}${TARGETVARIANT}/hbbr /usr/bin/hbbr
WORKDIR /root
ENV HOME=/root
VOLUME /root
