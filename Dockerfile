FROM ghcr.io/almalinux/10-minimal:10.1-20260407@sha256:347e52cf9191e7fedd908da07782530a2dff3f29f7e6f3d2e8122a29da7aad58

LABEL maintainer="Radio Bern RaBe"

# Add RaBe CA trust anchor
COPY rabe/rabe-ca.crt /etc/pki/ca-trust/source/anchors/

RUN <<-EOR
    set -xe
    update-ca-trust extract
    # ensure we have everything available from repos
    microdnf update -y
    microdnf clean all
EOR
