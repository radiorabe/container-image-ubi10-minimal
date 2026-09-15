FROM ghcr.io/almalinux/10-minimal:10.2-20260902@sha256:ee053be6b73674fdd32ec1dcee1e0b85dc2fa8b2f75976cbf8e72cfda2f718da

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
