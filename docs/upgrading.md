# Upgrading

This guide covers how to migrate a downstream image from an older RaBe base image to
`ghcr.io/radiorabe/ubi10-minimal`.

## From UBI9 Minimal

Migrating from `ghcr.io/radiorabe/ubi9-minimal` is straightforward because both images
share the same heredoc-based `RUN` convention and AlmaLinux packaging.

### 1. Update the `FROM` line

```dockerfile
# Before
FROM ghcr.io/radiorabe/ubi9-minimal:latest

# After
FROM ghcr.io/radiorabe/ubi10-minimal:latest
```

Pin to a specific tag and digest for reproducible builds:

```dockerfile
FROM ghcr.io/radiorabe/ubi10-minimal:<tag>@sha256:<digest>
```

### 2. Verify package availability

EL10 ships with updated package versions compared to EL9. Run a quick test build to
confirm every package your image installs is available in the EL10 repos:

```bash
podman build --no-cache -t test-ubi10-migration .
```

If `microdnf` reports a package as unavailable, check whether it has been renamed or
split upstream (e.g. search `https://packages.almalinux.org/`).

### 3. No other Dockerfile changes required

Both UBI9 and UBI10 base images use the `<<-EOR` heredoc syntax and the same
`microdnf` package manager. Your existing `RUN` blocks should work as-is.

---

## From UBI8 Minimal

UBI8 images used `registry.access.redhat.com/ubi8/ubi-minimal` as the upstream and
the older `RUN cmd1 && cmd2` chaining style. Both need updating.

### 1. Update the `FROM` line

```dockerfile
# Before
FROM ghcr.io/radiorabe/ubi8-minimal:latest

# After
FROM ghcr.io/radiorabe/ubi10-minimal:latest
```

### 2. Migrate `RUN` statements to heredoc syntax

The preferred style since UBI9 is a single `RUN <<-EOR … EOR` heredoc per logical
group of commands. This keeps the layer count low, makes diffs cleaner, and avoids
shell-escaping issues with `&&`-chained commands.

**Before (UBI8 style):**

```dockerfile
RUN microdnf install -y \
         shadow-utils \
    && microdnf clean all \
    && useradd -u 1001 -r -g 0 -s /sbin/nologin \
         -c "Default Application User" default
```

**After (UBI10 style):**

```dockerfile
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
```

Key improvements in the heredoc style:

- `set -xe` makes the shell exit immediately on any error (`-e`) and print each
  command before running it (`-x`), which greatly simplifies debugging.
- Each logical step is its own line — no trailing `\` or `&&` required.
- `libsemanage` (pulled in as a dependency of `shadow-utils`) is removed after use to
  keep the layer lean. Apply the same pattern to any transitive dependency you only
  need during image build.

### 3. Apply the same heredoc pattern to `EPEL` and `chmod` blocks

**Before (UBI8 style):**

```dockerfile
RUN    microdnf install -y epel-release \
    && microdnf install -y cowsay \
    && microdnf clean all \
    && chmod a-s \
         /usr/bin/* \
         /usr/sbin/* \
         /usr/libexec/*/*
```

**After (UBI10 style):**

```dockerfile
RUN <<-EOR
    set -xe
    microdnf install -y epel-release
    microdnf install -y cowsay
    microdnf clean all
    chmod a-s \
         /usr/bin/* \
         /usr/sbin/* \
         /usr/libexec/*/*
EOR
```

### 4. Verify package availability

EL8 → EL10 is a two-major-version jump. Some packages have been renamed, split, or
removed. Validate your full package list against the EL10 repositories before
shipping:

```bash
podman build --no-cache -t test-ubi10-migration .
```

Common changes to look for:

| EL8 package | EL10 equivalent |
|---|---|
| `python3` (3.6) | `python3` (3.12+) |
| `platform-python` | Use `python3` directly |
| Older `nodejs` streams | Use `nodejs` from AppStream |

### 5. Check for EL8-only EPEL packages

Some packages available in EPEL 8 may not yet be in EPEL 10. If a build fails on
`microdnf install -y <package>` after adding `epel-release`, check
[https://packages.fedoraproject.org/](https://packages.fedoraproject.org/) for
availability or open an issue in the relevant upstream package repository.

## See Also

- [UBI9 Minimal](https://github.com/radiorabe/container-image-ubi9-minimal)
- [UBI8 Minimal](https://github.com/radiorabe/container-image-ubi8-minimal)
- [AlmaLinux 10 packages](https://packages.almalinux.org/)
