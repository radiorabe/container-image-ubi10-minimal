# Agent Instructions: radiorabe/container-image-ubi10-minimal

## Repository Purpose

This repository builds and publishes the **RaBe Universal Base Image 10 Minimal**
(`ghcr.io/radiorabe/ubi10-minimal`), a stripped-down container base image built on
[AlmaLinux 10 UBI10 minimal](https://github.com/AlmaLinux/docker-images). It pre-installs
the RaBe Root CA trust anchor so that downstream images inherit it automatically.

The full documentation is published at
[radiorabe.github.io/container-image-ubi10-minimal](https://radiorabe.github.io/container-image-ubi10-minimal/).

## Repository Structure

```
Dockerfile                  # Single-stage image definition; installs CA trust anchor
rabe/
  rabe-ca.crt               # RaBe Root CA certificate (copied into the image)
docs/
  index.md                  # Home page (template only — content lives in overrides/home.html)
  monitoring.md             # Monitoring guidance; references rabe-zabbix templates
  upgrading.md              # Migration guides from UBI8 and UBI9 to UBI10
  downstream.md             # How downstream repos should align with this base image
  overrides/
    home.html               # Custom home page template (hero + features grid)
  css/
    style.css               # Custom MkDocs theme overrides
  AGENTS.md                 # Agent instructions for the docs/ directory
mkdocs.yml                  # MkDocs configuration (includes llmstxt plugin)
catalog-info.yaml           # Backstage component descriptor
.github/
  workflows/
    release.yaml            # Builds and pushes the image; deploys MkDocs docs
    schedule.yaml           # Daily Trivy vulnerability scan
    semantic-release.yaml   # Automated versioning via go-semantic-release
```

## Conventions

### Dockerfile

- **Base image pin**: The `FROM` line references a specific digest tag
  (`almalinux/10-minimal:<version>`). Update it when a new AlmaLinux release is available.
- **Minimal footprint**: Only add what every downstream image needs. Per-application
  packages belong in downstream images, not here.
- **CA trust**: The RaBe Root CA is the only file copied into the image. Update
  `rabe/rabe-ca.crt` if the CA is rotated.
- **Run layer**: Combine `update-ca-trust extract` and `microdnf update` in a single
  `RUN <<-EOR` heredoc to keep layers minimal.

### GitHub Actions Workflows

- **Reusable workflows**: Both `release.yaml` and `schedule.yaml` delegate to shared
  workflows from `radiorabe/actions`. Pin them to a released version tag
  (e.g. `@v0.41.1`). Dependabot keeps these tags current — do not replace tags with
  commit SHAs.
- **Permissions**: `release.yaml` declares explicit per-job permissions. Do not widen
  them beyond what the called workflow needs.
- **MkDocs deploy**: The `mkdocs` job in `release.yaml` installs dependencies and runs
  `mkdocs gh-deploy` only on pushes to `main`. PRs only run `mkdocs build` to validate.

### Documentation (`docs/`)

- `docs/index.md` contains only YAML front matter (`template: home.html`). All visible
  home page content lives in `docs/overrides/home.html` (hero section + features grid).
- `README.md` at the repository root is for GitHub display only and is not part of the
  docs site.
- Content pages (`monitoring.md`, `upgrading.md`, `downstream.md`) live directly in
  `docs/` and must be registered under `nav:` in `mkdocs.yml`.
- The `llmstxt` plugin auto-generates `/llms.txt` from the pages listed in its `sections:`
  config. Add new pages there when they contain content useful for LLMs.

### Conventional Commits and Versioning

Commit messages follow the [Conventional Commits](https://www.conventionalcommits.org/)
specification. Releases are automated by go-semantic-release on every push to `main`:

- `fix:` – patch bump (e.g. CA certificate rotation, dependency update)
- `feat:` – minor bump (e.g. new feature or meaningful base image change)
- `BREAKING CHANGE:` footer – major bump
- `docs:`, `ci:`, `chore:` – no release

All work happens on feature branches. Open a PR to `main`; do not manually create version tags.

## Making Changes

### Updating the base image version

1. Update the `FROM` line in `Dockerfile` with the new AlmaLinux tag.
2. Commit with `fix: update base image to <version>` or `feat:` if it represents a
   meaningful platform upgrade.

### Rotating the RaBe Root CA

1. Replace `rabe/rabe-ca.crt` with the new certificate.
2. Commit with `fix: rotate RaBe Root CA`.

### Adding a new documentation page

1. Create `docs/<name>.md`.
2. Register it in `mkdocs.yml` under `nav:`.
3. Add it to the `llmstxt` plugin `sections:` in `mkdocs.yml` if it contains
   LLM-relevant content.

### Updating workflow versions

Dependabot opens PRs for workflow version bumps automatically. Review and merge them;
do not pin to `@main` or `@latest`.

## Linting and Testing

There is no automated test suite for the image itself. Validate changes by:

```bash
# Build the image locally (prefer podman; docker also works)
podman build -t ubi10-minimal:local .

# Preview the documentation
python3 -m venv .venv
.venv/bin/pip install mkdocs-material mkdocs-section-index mkdocs-llmstxt
.venv/bin/mkdocs serve
```

The CI pipeline builds the image on every PR via the `release-container` reusable workflow,
which also runs a Trivy vulnerability scan.

## llms.txt

- [radiorabe.github.io/container-image-ubi10-minimal/llms.txt](https://radiorabe.github.io/container-image-ubi10-minimal/llms.txt) – this repo (auto-generated by the `llmstxt` plugin)
- [radiorabe.github.io/actions/llms.txt](https://radiorabe.github.io/actions/llms.txt) – shared CI/CD workflows
- [radiorabe.github.io/rabe-zabbix/llms.txt](https://radiorabe.github.io/rabe-zabbix/llms.txt) – Zabbix monitoring templates
- [docs.docker.com/llms.txt](https://docs.docker.com/llms.txt) – Docker and container image tooling

Tool docs (no llms.txt available):

- [squidfunk.github.io/mkdocs-material](https://squidfunk.github.io/mkdocs-material/) – MkDocs Material theme
- [trivy.dev](https://trivy.dev/) – Trivy security scanner
- [github.com/AlmaLinux/docker-images](https://github.com/AlmaLinux/docker-images) – AlmaLinux UBI10 upstream
