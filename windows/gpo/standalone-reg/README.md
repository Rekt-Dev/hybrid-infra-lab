# Standalone equivalent — same hardening, no domain

`chrome-harden.reg` applies the **same CIS-aligned Chrome hardening** as the Group Policy in the parent
folder, but for a **standalone, non-domain machine** — the way you'd harden an independent endpoint that
isn't joined to Active Directory.

The GPO and this `.reg` write to the **identical registry location** —
`HKLM\SOFTWARE\Policies\Google\Chrome` — because a GPO's Administrative Templates ultimately just set
registry values. Same end-state, two delivery mechanisms:

| Scenario | Delivery |
|---|---|
| Domain-joined fleet | GPO + Chrome ADMX (centralized, auto-applied) |
| Standalone machine | this `.reg` file (double-click / `regedit /s`) or `reg add` |

Settings applied: block all extensions (`ExtensionInstallBlocklist = *`), enhanced Safe Browsing,
incognito disabled, browser password saving disabled.

Apply:
```cmd
regedit /s chrome-harden.reg
```
