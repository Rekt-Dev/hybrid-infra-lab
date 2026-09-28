# Complete command log — every command run, end to end

Chronological record so the build is reproducible and recallable. GUI/portal steps are noted **[GUI]**.
Replace `<...>` with your own values. Domain: `corp.forestova.local`.

---

## Fleet reference
- **DC01** — `192.168.1.111` (bridged, RDP) + `10.0.2.3` (NAT-Network, domain), DNS `127.0.0.1`. AD DS / DNS.
- **Member1** — `10.0.2.15` (NAT-Network). **Hosts the Enterprise Root CA `Forestova-Root-CA`.** (Old bridged IP was `.112` before the NAT-Network move — same box.)
- **Member2** — Intune/UEM endpoint (offline until E5 tenant).
- **.113** — Linux box (locked out; GRUB root-reset pending; not needed yet).

---

## Session 2026-09-19 (eve) — network verify + PKI autoenrollment

### 1. Network sanity — run on each box (PowerShell, NOT cmd)
Confirm a box can see the domain after the NAT-Network rebuild:
```powershell
ipconfig /all | Select-String -Pattern "IPv4","Gateway","DNS Servers"
ipconfig /flushdns; nslookup corp.forestova.local        # expect ONLY 10.0.2.3, no stale records
Test-NetConnection 10.0.2.3 -Port 389                     # LDAP to DC → TcpTestSucceeded : True
Get-Date                                                  # confirm correct date+time (drift check)
```
Expected per box:
- **Member1:** IPv4 `10.0.2.15`, GW `10.0.2.1`, DNS `10.0.2.3`, 389 = True.
- **DC01:** IPv4 `10.0.2.3` (+ `192.168.1.111`), DNS `127.0.0.1`.

### 2. Confirm the CA is alive (run on Member1 = the CA)
```powershell
hostname                          # → Member1
Get-Service CertSvc               # → Running (Active Directory Certificate Services)
certutil -CAInfo name             # → CA name: Forestova-Root-CA
```
> If `certutil` says "No local Certification Authority" you're on the WRONG box (that was DC01). The CA is Member1.

### 3. Clock fix (drift = fatal for Kerberos >5min + cert timestamps)
```powershell
w32tm /resync /force
w32tm /query /status
Get-Date                          # verify correct date, not future
```
> Durable fix (TODO): install **VBox Guest Additions** on each VM (Devices → Insert Guest Additions CD image → run VBoxWindowsAdditions.exe → reboot) so time re-syncs after pause/resume.

### 4. Autoenrollment build — the fix for `CERTSRV_E_TEMPLATE_DENIED`
**Root cause:** a machine enrolls in the **computer account's** identity; the template ACL didn't grant it **Enroll**, so it was denied. Fix = grant Domain Computers Enroll+Autoenroll, publish, GPO, pulse.

**[GUI] on Member1 (the CA):**
```powershell
certtmpl.msc      # Certificate Templates console
```
- Right-click **Computer** → **Duplicate Template**.
- **General** tab → Display name = `Computer Autoenroll`.
- **Security** tab → select **Domain Computers** → Allow **Read + Enroll + Autoenroll**.  ← the missing permission
- **Subject Name** tab → "Build from this Active Directory information" + **DNS name** (default). → OK.

```powershell
certsrv.msc       # Certification Authority console
```
- Expand **Forestova-Root-CA** → right-click **Certificate Templates** → **New → Certificate Template to Issue** → pick **Computer Autoenroll**.
  (A template must be explicitly *issued* by the CA, not just defined.)

**[GUI] on DC01:**
```powershell
gpmc.msc          # Group Policy Management
```
- **Default Domain Policy** → **Edit** → Computer Configuration → Policies → Windows Settings → Security Settings → **Public Key Policies** → **Certificate Services Client – Auto-Enrollment**.
- Configuration Model = **Enabled**; tick BOTH: *Renew expired…* and *Update certificates that use certificate templates*. → OK.

### 5. Trigger + verify (on Member1)
```powershell
gpupdate /force
certutil -pulse                   # forces the autoenrollment engine NOW (no 90-min wait)
Get-ChildItem Cert:\LocalMachine\My | Format-List Subject, Issuer, Thumbprint, NotAfter
certutil -store My <THUMBPRINT>   # full detail
```
**Success proof (2026-09-19 7:16 PM):**
```
Issuer: CN=Forestova-Root-CA, DC=corp, DC=forestova, DC=local
NotBefore: 9/19/2026 7:16 PM   NotAfter: 9/19/2027 7:16 PM
Subject: EMPTY (DNS Name=Member1.corp.forestova.local)
Template: ComputerAutoenroll, Computer Autoenroll
Private key is NOT exportable   Encryption test passed
```
Machine auto-pulled the cert — zero manual `certreq`. Autoenrollment working end-to-end.

### The 3 cert consoles (don't confuse)
- `certtmpl.msc` = templates (domain-wide blueprints + permissions)
- `certsrv.msc`  = the CA (what THIS CA issues / issued / revoked)
- `certlm.msc`   = a machine's local store (what a box actually holds)

---

## Earlier PKI work (manual cert, pre-autoenrollment) — see windows/pki/README.md
```powershell
Get-Service CertSvc; certutil -CAInfo name
Get-WindowsFeature Web-Server, Web-Mgmt-Console
# certreq manual issue WITH SAN (workaround before autoenrollment):
certreq -new  C:\web-san.inf C:\web-san.req
certreq -submit C:\web-san.req C:\web-san.cer     # pick Forestova-Root-CA
certreq -accept C:\web-san.cer
```
