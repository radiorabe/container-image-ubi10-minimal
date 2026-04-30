# RaBe Universal Base Image 10 Minimal

The RaBe Universal Base Image 10 Minimal is a stripped down image that uses microdnf for package management.

The image is based on the [AlmaLinux 10 UBI10 variant image](https://github.com/AlmaLinux/docker-images)
container provided by AlmaLinux and based on the work from [Red Hat](https://catalog.redhat.com/en/software/containers/ubi10/ubi-minimal/66f1504a379b9c2cf23e145c).

## Features

- Based on UBI10 minimal
- Uses microdnf as a package manager
- Establishes trust with the RaBe Root CA

## Usage

Create a downstream image from `ghcr.io/radiorabe/ubi10-minimal`. Replace `:latest` with a specific version in the example below.

```Dockerfile
FROM ghcr.io/radiorabe/ubi10-minimal:latest

RUN <<-EOR
    set -xe
    microdnf install -y \
         shadow-utils
    microdnf clean all
    useradd -u 1001 -r -g 0 -s /sbin/nologin \
         -c "Default Application User" default
    microdnf remove -y \
         libsemanage \
         shadow-utils
EOR
         
USER 1001
```

Note that `libsemanage` is being removed because it was installed as a dependency of `shadow-utils`. We only need them for
the `useradd` command so the safe solution is to remove both packages after use.

## Version pinning

For reproducible downstream builds, pin to an immutable tag or digest instead of relying on `:latest`.

- **Tags**: This repository publishes versioned tags (e.g. `v1.2.3`) and the `latest` convenience tag.
- **Digests**: Pinning by digest (`@sha256:...`) guarantees the exact same image is used every time.

Example (recommended):

```dockerfile
FROM ghcr.io/radiorabe/ubi10-minimal:<tag>@sha256:<digest>
```

To look up the digest for a tag locally:

```bash
podman pull ghcr.io/radiorabe/ubi10-minimal:latest
podman inspect --format='{{index .RepoDigests 0}}' ghcr.io/radiorabe/ubi10-minimal:latest
```

## What’s inside the image

This image is intentionally minimal. It is built FROM `ghcr.io/almalinux/10-minimal` and only adds the RaBe Root CA trust anchor.

Key characteristics:

- **Base image**: AlmaLinux 10 UBI10 minimal (`ghcr.io/almalinux/10-minimal:<version>`)
- **Package manager**: Includes `microdnf` (no `dnf`/`yum`)
- **CA trust**: Copies `rabe/rabe-ca.crt` into `/etc/pki/ca-trust/source/anchors/` and runs `update-ca-trust extract`
- **No services / agents**: No SSH, no systemd, and no monitoring agent is installed by default (see *Monitoring* section)
- **Minimal footprint**: Keeps the image small by avoiding extra tooling; downstream images should add only what they need

## Downstream Base Images

No specialized downstream images are published at this time. If you need a tailored base image for a particular use case, please open an issue.

> :information_source: We maintain a collection of downstream images in the `ghcr.io/radiorabe/` registry (e.g., application runtimes and tooling images). We plan to update the collection to use UBI10-based images like this one over time.

See the [Downstream Image Alignment](docs/downstream.md) page for guidance on how to align a downstream repository with the conventions used here.

## Upgrading

Migrating from an older RaBe base image? See the [Upgrading](docs/upgrading.md) page for step-by-step guides:

- [From UBI9 Minimal](docs/upgrading.md#from-ubi9-minimal)
- [From UBI8 Minimal](docs/upgrading.md#from-ubi8-minimal)

## Monitoring

This image does not ship a monitoring agent by default. If you run containers based on this image in an environment monitored with [Zabbix](https://www.zabbix.com/), you can use the templates maintained in [radiorabe/rabe-zabbix](https://github.com/radiorabe/rabe-zabbix).

See the [Monitoring](docs/monitoring.md) page for details.

## Advanced Usage

If you need packages from EPEL (like `cowsay`) you have to install an `epel-release` package first:

```Dockerfile
RUN <<-EOR
    set -xe
    microdnf install -y epel-release
    microdnf install -y cowsay
    microdnf clean all
EOR
```

To account for [CIS-DI-0008](https://github.com/goodwithtech/dockle/blob/master/CHECKPOINT.md#cis-di-0008) you may want to
"defang" your image by running something similar to the following `chmod` after installing setuid/setgid binaries.

```Dockerfile
RUN <<-EOR
    set -xe
    microdnf install -y cowsay
    microdnf clean all
    chmod a-s \
         /usr/bin/* \
         /usr/sbin/* \
         /usr/libexec/*/*
EOR
```

## Release Management

The CI/CD setup uses semantic commit messages following the [conventional commits standard](https://www.conventionalcommits.org/en/v1.0.0/).
There is a GitHub Action in [.github/workflows/semantic-release.yaml](./.github/workflows/semantic-release.yaml)
that uses [go-semantic-commit](https://go-semantic-release.xyz/) to create new
releases.

The commit message should be structured as follows:

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

The commit contains the following structural elements, to communicate intent to the consumers of your library:

1. **fix:** a commit of the type `fix` patches gets released with a PATCH version bump
1. **feat:** a commit of the type `feat` gets released as a MINOR version bump
1. **BREAKING CHANGE:** a commit that has a footer `BREAKING CHANGE:` gets released as a MAJOR version bump
1. types other than `fix:` and `feat:` are allowed and don't trigger a release

If a commit does not contain a conventional commit style message you can fix
it during the squash and merge operation on the PR.

## Build Process

The CI/CD setup uses the [Docker build-push Action](https://github.com/docker/build-push-action) to publish container images. This is managed in [.github/workflows/release.yaml](./.github/workflows/release.yaml).

## Security scanning, SBOMs, and attestations

The GitHub Actions pipeline runs Trivy on every build and uploads the results as SARIF to the repository's **Security → Code scanning alerts** page.

On released tags (`refs/tags/v*`) the pipeline additionally:

- Signs the image using **cosign** (keyless GitHub Actions OIDC signing)
- Converts Trivy output into a **CycloneDX SBOM** and attaches it to the image as a cosign attestation (`--type cyclonedx`)
- Converts Trivy output into a **cosign-vuln** report and attaches it as a cosign vulnerability attestation (`--type vuln`)

### Verifying published images + getting the SBOM

The published image in `ghcr.io/radiorabe/ubi10-minimal` is signed and has attestations attached.

#### 1) Verify the image attestation (keyless Cosign)

```bash
cosign verify-attestation \
  --type cyclonedx \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com \
  --certificate-identity-regexp 'https://github.com/radiorabe/actions/.*' \
  ghcr.io/radiorabe/ubi10-minimal:<tag>

cosign verify-attestation \
  --type vuln \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com \
  --certificate-identity-regexp 'https://github.com/radiorabe/actions/.*' \
  ghcr.io/radiorabe/ubi10-minimal:<tag>
```

> Note: Replace `<tag>` with the desired image tag (e.g. `latest` or a release tag).

#### 2) Download and decode the SBOM from the CycloneDX attestation

```bash
cosign download attestation \
  --predicate-type cyclonedx \
  ghcr.io/radiorabe/ubi10-minimal:<tag> \
  | jq -r '.payload' \
  | base64 --decode \
  | jq '.' > bom.json
```

`bom.json` is the CycloneDX SBOM for the published image.

#### 3) Count vulnerabilities from the vuln attestation

```bash
cosign download attestation \
  --predicate-type vuln \
  ghcr.io/radiorabe/ubi10-minimal:<tag> \
  | jq -s -r 'map(.payload) | map(@base64d | fromjson | .predicate.scanner.result.Results[].Vulnerabilities | length) | add'
```

This prints the total number of vulnerabilities found by the scan.

#### 4) Pretty-print the vuln list (if any)

```bash
cosign download attestation \
  --predicate-type vuln \
  ghcr.io/radiorabe/ubi10-minimal:<tag> \
  | jq -s 'map(.payload) | map(@base64d | fromjson | .predicate.scanner.result.Results[].Vulnerabilities) | add' \
  | jq '.'
```

This prints the full list of vulnerabilities (it will generally be `[]` when no issues are found).

### Where to look in GitHub

- **Actions** tab → **Publish Container Images** workflow (builds & scan)
- **Actions** tab → **Scheduled tasks** workflow (daily Trivy scan + attestation)
- **Security** tab → **Code scanning alerts** (Trivy SARIF upload)

## License

This application is free software: you can redistribute it and/or modify it under
the terms of the GNU Affero General Public License as published by the Free
Software Foundation, version 3 of the License.

## Copyright

Copyright (c) 2022 [Radio Bern RaBe](http://www.rabe.ch)
