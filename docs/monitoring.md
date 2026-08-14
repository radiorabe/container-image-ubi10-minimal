# Monitoring

Container images built on `ghcr.io/radiorabe/ubi10-minimal` can be monitored with
[Zabbix](https://www.zabbix.com/) using the templates maintained in
[radiorabe/rabe-zabbix](https://github.com/radiorabe/rabe-zabbix).

## Zabbix Templates

The [rabe-zabbix](https://github.com/radiorabe/rabe-zabbix) repository provides
OS-level and application-level Zabbix templates for Radio Bern RaBe infrastructure.

**Note:** This image is a minimal container base image and does not include a Zabbix agent or monitoring stack. Monitoring is typically done at the host/cluster level (e.g., using a node-local Zabbix agent or the Kubernetes node exporter), but you can also run a Zabbix agent inside a container and apply application templates to it.

When monitoring containers, we prefer using application-level metrics (e.g., OpenMetrics / Prometheus endpoints) and meaningful service checks over basic "is process running" probes. If an application exposes an OpenMetrics endpoint, it is usually more reliable and less prone to false positives than OS-level checks, and it enables deeper insight into application health (latency, error rates, resource utilization, etc.).

In deployments where you run a Zabbix agent on the host, the host is typically assigned an OS stack template that covers base system health (CPU, memory, disk, network) and one or more application templates for the workloads running in containers.

Relevant template categories:

- **[Stacks: Operating systems](https://github.com/radiorabe/rabe-zabbix/tree/main/Stacks/Operating_systems)** –
  OS-level stack templates (CPU, memory, disk, network) assigned per host.
- **[Templates: Applications](https://github.com/radiorabe/rabe-zabbix/tree/main/Templates/Applications)** –
  Per-application monitoring templates that complement the OS stack.

## See Also

- [rabe-zabbix on GitHub](https://github.com/radiorabe/rabe-zabbix) – full template library
- [Zabbix documentation](https://www.zabbix.com/documentation/current/) – upstream Zabbix docs
