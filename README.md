# Hybrid Enterprise Infrastructure Lab

A hands-on lab standing up a **hybrid Windows + Linux enterprise environment** — Active Directory,
PKI, DNS/DHCP, Linux app stacks, **Ansible automation**, and **cloud-based MDM/UEM (Intune)** —
built to mirror a real mixed-fleet estate.

> Built as a working reference environment: identity, provisioning, configuration management,
> and endpoint management across both OS families.

---

## Architecture

| Layer | Component | Role |
|-------|-----------|------|
| Identity | `Svr_22_Eval` (DC) | AD DS + DNS + DHCP — the domain's source of truth |
| Security | `CA01` (member) | AD CS — Enterprise Root CA (PKI) |
| Files / DR | `FS01` / `DC02` (member) | File services + second DC (replication, failover) |
| Linux | `ubuntusvr` + cloned nodes | Ansible control node + managed fleet, app stacks |
| Endpoint mgmt | Microsoft Intune | MDM/UEM — device enrollment, compliance, remote wipe |

*(Diagram to be added — see `docs/images/`.)*

---

## Networking design

All lab machines sit on a **single isolated virtual network** (VirtualBox *Host-Only* / *Internal
Network*) — **not** NAT, **not** Bridged. This is a deliberate choice driven by the DC owning
DHCP/DNS:

| Mode | Verdict | Why |
|------|---------|-----|
| NAT (default) | ❌ | Per-VM NAT isolates each guest — VMs can't see each other, so no domain, no Ansible |
| Bridged | ⚠️ | Puts VMs on the real LAN → the DC's DHCP **collides with the home router's DHCP** |
| **Host-Only / Internal** | ✅ | Isolated switch: the DC cleanly owns DHCP/DNS on `192.168.1.0/24`; fully portable/offline |

- **The whole `192.168.1.x` scheme assumes the DC (`192.168.1.111`) controls the subnet** — only an
  isolated network lets it serve DHCP/DNS without fighting the physical router.
- **Every lab machine must use the same network type**, or they can't reach each other.
- **Dual-adapter pattern** for boxes that need internet (guest `apt` / Windows Update):
  Adapter 1 = Host-Only/Internal (domain traffic), Adapter 2 = NAT (outbound internet).
- **DNS on every domain member must point at the DC (`192.168.1.111`)** — domain join is a DNS SRV
  lookup; any other resolver = "domain could not be contacted."

---

## What this demonstrates (mapped to enterprise sysadmin work)

- **Active Directory** — forest/domain build, GPO, replication, delegation
- **PKI** — Enterprise Root CA, certificate templates, auto-enrollment
- **Provisioning at scale** — golden images, PXE/network imaging, sysprep/unattend domain join,
  Linux cloning with identity reset (machine-id, SSH host keys)
- **Configuration management** — Ansible (agentless, idempotent) across a Linux fleet
- **App stacks** — NGINX / Apache / Tomcat on Linux
- **MDM / UEM** — Intune enrollment + compliance policy, real mobile-device PoC
- **Backup / DR** — dual-DC, snapshot discipline

---

## Repo layout

```
docs/        Walkthroughs + screenshots (the story)
ansible/     Inventory, playbooks, roles
windows/     PowerShell for AD CS, domain join, config
linux/       App-stack configs
```

See [`docs/artifacts-log.md`](docs/artifacts-log.md) for the running build log.
