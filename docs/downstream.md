# Downstream Image Alignment

This page describes how downstream container image repositories should align their
Dockerfile patterns, documentation, and CI/CD setup with the conventions established
by `ghcr.io/radiorabe/ubi10-minimal`.

Applying these guidelines keeps the RaBe container image ecosystem consistent and
makes it easier to apply cross-cutting changes (CA rotation, base image updates,
security fixes) across all downstream images.

## Dockerfile Conventions

### Use the heredoc `RUN` style

Always combine related shell commands in a single `RUN <<-EOR … EOR` heredoc.
Lead every heredoc with `set -xe`:

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

USER 1001
```

`set -xe` ensures the build fails immediately on any error and prints each command for
easy debugging. See [Upgrading](upgrading.md) for before/after examples when migrating
from older `&&`-chained `RUN` statements.

### Remove build-only dependencies

Remove packages that are only needed during the build (e.g. `shadow-utils` and
its transitive dependency `libsemanage` after running `useradd`) in the same `RUN`
layer to avoid bloating the image.

### Pin the base image

Reference a specific tag and digest so builds are reproducible and updates are
explicit and reviewable:

```dockerfile
FROM ghcr.io/radiorabe/ubi10-minimal:<tag>@sha256:<digest>
```

Use [Dependabot](https://docs.github.com/en/code-security/dependabot) to receive
automated PRs when a new base image version is available.

### Keep the image minimal

Only install packages that the downstream image needs at runtime. Build-time tooling
(compilers, dev headers, etc.) should be installed and removed in a single `RUN`
layer, or handled in a multi-stage build.

## Documentation Conventions

Downstream image repositories should mirror the documentation structure used here:

### `README.md`

The root `README.md` is the single source of truth for user-facing content. It is
copied to `docs/index.md` at MkDocs build time by `docs/gen_ref_pages.py`. Include at
minimum:

- **Features** – what the image provides
- **Usage** – a copy-pasteable `FROM` + `RUN` example
- **Monitoring** – link to `docs/monitoring.md`
- **Release Management** – conventional commits reference
- **Build Process** – link to the release workflow

### `docs/monitoring.md`

Add a monitoring page that links to the relevant
[rabe-zabbix](https://github.com/radiorabe/rabe-zabbix) templates for the workload
running in the image. See this repo's [monitoring page](monitoring.md) as a template.

### `AGENTS.md` and `docs/AGENTS.md`

Add an `AGENTS.md` at the repository root (and `docs/AGENTS.md` for the docs
directory) to help AI coding agents and human maintainers understand the repository
structure, conventions, and how to make changes. See this repo's
[AGENTS.md](https://github.com/radiorabe/container-image-ubi10-minimal/blob/main/AGENTS.md)
as a template.

### `mkdocs.yml` — `llmstxt` plugin

Add the `llmstxt` plugin to make documentation discoverable by LLMs. Ensure
`site_url` is set and add a `sections:` block that lists all documentation pages:

```yaml
plugins:
- llmstxt:
    markdown_description: |
      One-paragraph description of the image and its purpose.
    sections:
      Documentation:
        - index.md
      Monitoring:
        - monitoring.md
```

Install the plugin alongside the other MkDocs dependencies:

```bash
pip install mkdocs mkdocs-material mkdocs-gen-files mkdocs-literate-nav mkdocs-section-index mkdocs-llmstxt
```

## CI/CD Conventions

### Workflow structure

Follow the same three-workflow layout:

| File | Purpose |
|---|---|
| `.github/workflows/release.yaml` | Build, scan, sign, and push the image; deploy MkDocs docs |
| `.github/workflows/schedule.yaml` | Daily Trivy vulnerability scan |
| `.github/workflows/semantic-release.yaml` | Automated versioning via go-semantic-release |

### Use reusable workflows from `radiorabe/actions`

Delegate to the shared reusable workflows pinned to a released version tag:

```yaml
uses: radiorabe/actions/.github/workflows/release-container.yaml@v0.0.0
```

Dependabot keeps version tags up-to-date automatically — do not pin to `@main` or `@latest`.

### MkDocs deploy

Install `mkdocs-llmstxt` in the `mkdocs` job alongside the other pip dependencies and
run `mkdocs build` on every PR (to validate) and `mkdocs gh-deploy` on pushes to
`main` (to publish):

```yaml
- run: pip install mkdocs mkdocs-material mkdocs-gen-files mkdocs-literate-nav mkdocs-section-index mkdocs-llmstxt
- run: mkdocs build
- run: mkdocs gh-deploy
  if: ${{ github.event_name == 'push' && github.ref == 'refs/heads/main' }}
```

## See Also

- [radiorabe/actions](https://github.com/radiorabe/actions) – shared CI/CD reusable workflows
- [radiorabe/rabe-zabbix](https://github.com/radiorabe/rabe-zabbix) – Zabbix monitoring templates
- [Upgrading](upgrading.md) – migration guides from UBI8 and UBI9
