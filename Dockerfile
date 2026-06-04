FROM ghcr.io/almalinux/10-minimal:10.2-20260602@sha256:81cc449abdebd77e91a63e82f2b6ba760c45bfc24f4f6365d2fd72361a82cb4a

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
