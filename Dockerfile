FROM ghcr.io/almalinux/10-minimal:10.1-20260509@sha256:0e981e616a7b05ad82838c9902cf3109fb321b9610c382b87e05060111dcb1c4

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
