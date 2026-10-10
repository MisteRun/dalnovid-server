# Dalnovid server image. Binaries come from the Release workflow,
# staged as bin/<arch>/{hbbs,hbbr} (amd64, arm64), built against glibc.
FROM debian:bookworm-slim
ARG TARGETARCH
COPY bin/${TARGETARCH}/hbbs /usr/bin/hbbs
COPY bin/${TARGETARCH}/hbbr /usr/bin/hbbr
WORKDIR /root
ENV HOME=/root
VOLUME /root
