FROM ghcr.io/almalinux/10-minimal:10.1-20260129@sha256:a0dad88a01c3ab749a76aa78ddb1f071d5432f9fe5ea01bd2749d31b41d658e6

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
