FROM ghcr.io/almalinux/10-minimal:10.3-20261116@sha256:37494fde965664316a6ce8579baec3bd9830ce150278ac1d39a94a06fbd35243

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
