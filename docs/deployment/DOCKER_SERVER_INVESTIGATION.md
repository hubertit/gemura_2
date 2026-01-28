# Docker on Server – Investigation Summary

**Server:** 159.198.65.38 (server2.brainae.org)  
**OS:** AlmaLinux 8.10  
**Date:** 2026-01-27  

## What Happened (Timeline)

1. **Earlier deployment**  
   - Deploy script ran; Docker build hit **exit 137** (OOM) during `npm ci`.  
   - While cleaning up, removal of the old backend container hit **overlay2 "device or resource busy"** (filesystem in use).  

2. **Reboot**  
   - Server was rebooted to clear the overlay2 / “device or resource busy” state.  

3. **After reboot (17:07 UTC)**  
   - Docker is **enabled** at boot, so `docker.service` started automatically.  
   - **First start failed** with:
     ```text
     iptables failed: iptables --wait -I FORWARD -o docker0 -j DOCKER:
     iptables v1.8.5 (nf_tables): Chain 'DOCKER' does not exist
     ```
     So Docker tried to program iptables for `docker0`, but the **DOCKER chain did not exist yet** (normal at early boot). Docker had already created/registered the default bridge; then it exited on this iptables error and left **docker0** (and later **br-e7f96f3519ff**) on the host.

4. **Second and third restarts (17:07:36, 17:07:40)**  
   - Docker read its **persisted network state** in `/var/lib/docker/network/files/` (network `06da...` with bridge name `docker0`).  
   - It also tried to create a **new** default “bridge” network.  
   - The kernel still had the **docker0** interface from the failed first start.  
   - Error:
     ```text
     cannot create network ... (docker0): conflicts with network 06da... (docker0): networks have same bridge name
     ```
   - After a few rapid retries, systemd reported **“Start request repeated too quickly”** and Docker stopped trying.

5. **Later manual/scripted start attempts (e.g. 22:17)**  
   - Same “conflicts with network … (docker0)” error: stale bridge + stale network DB.

So **Docker has not been running** since that first failed boot.

---

## Root Causes (Chain of Events)

| # | Cause | Explanation |
|---|--------|--------------|
| 1 | **iptables at boot** | On first start after reboot, Docker programs FORWARD/nat rules and needs a DOCKER chain. With AlmaLinux 8 and `iptables (nf_tables)`, at early boot that chain may not exist yet, so Docker fails after partially bringing up the default bridge. |
| 2 | **Stale docker0 / br-*** | That failed start left **docker0** (and **br-e7f96f3519ff**) on the host. |
| 3 | **Stale network state** | Docker’s DB in `/var/lib/docker/network/files/local-kv.db` still has network `06da...` for bridge name `docker0`. On every later start, Docker tries to create a *new* default bridge with the same name and hits “conflicts with network … (docker0)” because the name is already taken (both in kernel and in its own persisted state). |
| 4 | **Overlay2 “device or resource busy” (earlier)** | Unrelated to the *current* “Docker won’t start” issue, but it was the reason for the reboot. It came from the old backend container’s rootfs being in use during deploy/removal. |

So: **Docker fails at boot due to iptables ordering**, leaves bridges and network state behind, and every subsequent start fails on **“conflicts … same bridge name”**.

---

## Current Server State (When Checked)

- **Docker daemon:** not running (`Active: failed`).
- **Docker unit:** `enabled` (starts on boot).
- **docker0:** present, DOWN (`ip link show docker0`).
- **br-e7f96f3519ff:** present (custom Docker network).
- **/var/lib/docker/network/files/:** contains `local-kv.db` with old network IDs.
- **iptables:** by the time of investigation, `Chain DOCKER` existed (e.g. later manual run or different boot); firewalld was inactive.

---

## Fix: Recover Docker on the Server

Do this **on the server** (e.g. SSH as root).

### Option A: Remove stale bridges and reset Docker network state (recommended)

Docker is stopped, so it’s safe to remove its bridges and clear its network DB so it recreates default networks on next start.

```bash
# 1. Ensure Docker is stopped
systemctl stop docker

# 2. Remove stale bridges (Docker’s default + one custom)
ip link set docker0 down
ip link delete docker0
ip link set br-e7f96f3519ff down
ip link delete br-e7f96f3519ff

# 3. Clear Docker’s persisted network state so it can recreate “default bridge” cleanly
rm -f /var/lib/docker/network/files/local-kv.db

# 4. Start Docker
systemctl start docker

# 5. Confirm
docker info
docker ps
```

Then rerun your deploy from your machine; no script change required for this.

### Option B: Only remove bridges (if you prefer not to touch DB)

If you don’t want to delete `local-kv.db`, try only removing the bridges. Sometimes that’s enough for Docker to reconcile on start:

```bash
systemctl stop docker
ip link set docker0 down && ip link delete docker0
ip link set br-e7f96f3519ff down && ip link delete br-e7f96f3519ff
systemctl start docker
docker info
```

If Docker still fails with “conflicts … same bridge name”, use Option A.

---

## Reducing the Chance of This Happening Again

1. **Docker after network/iptables**  
   Make Docker start after the network and any firewall that might create chains Docker uses:
   ```bash
   # Example: ensure docker starts after network-online
   mkdir -p /etc/systemd/system/docker.service.d
   cat > /etc/systemd/system/docker.service.d/after-network.conf << 'EOF'
   [Unit]
   After=network-online.target
   Wants=network-online.target
   EOF
   systemctl daemon-reload
   ```

2. **Use iptables-legacy for Docker (if you see nf_tables vs legacy conflicts)**  
   AlmaLinux 8 can use nftables backend for iptables. If Docker and the system disagree on which backend to use, you can force Docker to use legacy:
   - In `/etc/docker/daemon.json` (create if missing):
     ```json
     { "iptables": true }
     ```
   - And ensure Docker is started with the legacy iptables stack (often via systemd/override or `alternatives`).  
   Only do this if you still see “Chain 'DOCKER' does not exist” at boot after applying the “after-network” ordering above.

3. **After any “device or resource busy” or unclean shutdown**  
   Before rebooting, try: `systemctl stop docker` and wait a few seconds so Docker can remove bridges and cleanup. If you already rebooted and Docker won’t start, use the recovery steps above.

---

## Related Scripts / Docs

- **Deploy script:** `scripts/deployment/deploy-to-server.sh`  
  - Step 1.5 checks if Docker is up and tries `systemctl start docker` once.  
  - It cannot fix “conflicts … same bridge name” or iptables ordering; that requires the server-side steps above.
- **Overlay2 “device or resource busy”:** Caused by the old backend container’s rootfs being in use during deploy; reboot was a reasonable way to clear it, but it led to the boot-time Docker/iptables/bridge conflict described here.

---

## Short One-Liner (Recovery)

Run on the server as root:

```bash
systemctl stop docker; ip link set docker0 down 2>/dev/null; ip link delete docker0 2>/dev/null; ip link set br-e7f96f3519ff down 2>/dev/null; ip link delete br-e7f96f3519ff 2>/dev/null; rm -f /var/lib/docker/network/files/local-kv.db; systemctl start docker; docker info
```

If `docker info` succeeds, Docker is running again and you can redeploy.
