FROM ghcr.io/almalinux/10-minimal:10.1-20260104

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
