# Monitoring

Container images built on `ghcr.io/radiorabe/ubi10-minimal` can be monitored with
[Zabbix](https://www.zabbix.com/) using the templates maintained in
[radiorabe/rabe-zabbix](https://github.com/radiorabe/rabe-zabbix).

## Zabbix Templates

The [rabe-zabbix](https://github.com/radiorabe/rabe-zabbix) repository provides
OS-level and application-level Zabbix templates for Radio Bern RaBe infrastructure.
Hosts running containers built on this image are typically assigned an OS stack template
that covers base system health, and one or more application templates for the workloads
running inside the container.

Relevant template categories:

- **[Stacks: Operating systems](https://github.com/radiorabe/rabe-zabbix/tree/main/Stacks/Operating_systems)** –
  OS-level stack templates (CPU, memory, disk, network) assigned per host.
- **[Templates: Applications](https://github.com/radiorabe/rabe-zabbix/tree/main/Templates/Applications)** –
  Per-application monitoring templates that complement the OS stack.

## See Also

- [rabe-zabbix on GitHub](https://github.com/radiorabe/rabe-zabbix) – full template library
- [Zabbix documentation](https://www.zabbix.com/documentation/current/) – upstream Zabbix docs
