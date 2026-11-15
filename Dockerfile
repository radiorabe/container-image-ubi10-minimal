FROM ghcr.io/almalinux/10-minimal:10.2-20261114@sha256:59186585abee4673468ea8c7167917c76fa7e751206f4903a856d8a23cc3ed5f

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
