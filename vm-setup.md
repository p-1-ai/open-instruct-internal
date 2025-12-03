# System Setup Instructions

This document contains all the setup requests and their corresponding solutions/workarounds for the GCP VM instance.

## 1. Docker Permission Fix

**Request**: Run `docker ps` without sudo

**Solution**:
- Added user to docker group: `sudo usermod -aG docker hieu_p_1_ai`
- Created a wrapper function in `~/.bashrc` to handle cases where the session doesn't see the docker group (common in Jupyter/managed environments):

```bash
# Docker wrapper for Jupyter/managed environments where group membership may not be refreshed
# This allows running docker commands without sudo even if the current session doesn't see the docker group
docker() {
    if groups | grep -q docker 2>/dev/null; then
        command docker "$@"
    else
        sg docker -c "docker $*"
    fi
}
```

**Files Modified**: `~/.bashrc`

**Note**: After adding user to docker group, new terminal sessions will automatically have docker access. The wrapper function ensures it works even in managed environments like Jupyter.

---

## 2. Local SSD Mounting

**Request**: Mount the 375GB local SSD disk that was configured in GCP console but not showing up in `df -h`

**Solution**:
1. Identified the disk: `nvme0n1` (375GB) was detected but not formatted or mounted
2. Formatted with ext4: `sudo mkfs.ext4 -F /dev/nvme0n1`
3. Created mount point: `sudo mkdir -p /mnt/disks/ssd`
4. Mounted the disk: `sudo mount -o discard,defaults /dev/nvme0n1 /mnt/disks/ssd`
5. Set permissions: `sudo chmod 777 /mnt/disks/ssd`
6. Added to `/etc/fstab` for automatic mounting on reboot:

```
UUID=b5a7176c-f407-4fa3-8582-00887bf2819c /mnt/disks/ssd ext4 discard,defaults 0 2
```

**Files Modified**: `/etc/fstab`

**Note**: The UUID may differ - verify with `sudo blkid /dev/nvme0n1` before adding to fstab.

**Important**: Local SSDs on GCP are ephemeral - data is lost if the VM is stopped or restarted. Use for temporary data, caches, or scratch space.

---

## 3. Docker Data Directory on SSD

**Request**: Configure Docker to store all data (including build cache) on the SSD instead of root filesystem

**Solution**:
1. Created Docker data directory on SSD: `sudo mkdir -p /mnt/disks/ssd/docker`
2. Created Docker daemon configuration: `/etc/docker/daemon.json`:

```json
{
  "data-root": "/mnt/disks/ssd/docker"
}
```

3. Stopped Docker: `sudo systemctl stop docker.socket docker.service`
4. Reloaded systemd: `sudo systemctl daemon-reload`
5. Started Docker: `sudo systemctl start docker.socket docker.service`

**Files Created**: `/etc/docker/daemon.json`

**Verification**: Run `docker info | grep "Docker Root Dir"` - should show `/mnt/disks/ssd/docker`

**Note**: All Docker data (images, containers, volumes, build cache) will now be stored on the SSD, freeing up space on the root filesystem.

---

## 4. Install uv Package Manager

**Request**: Install `uv` (Python package installer)

**Solution**:
1. Installed using official installer: `curl -LsSf https://astral.sh/uv/install.sh | sh`
2. Added to PATH in `~/.bashrc`:

```bash
# Add uv to PATH
export PATH="$HOME/.local/bin:$PATH"
```

**Files Modified**: `~/.bashrc`

**Installation Location**: `~/.local/bin/uv`

**Note**: After installation, either restart the shell or run `source ~/.bashrc` to use `uv` immediately.

---

## Summary of All Changes

### Files Modified:
1. `~/.bashrc` - Added docker wrapper function and uv PATH
2. `/etc/fstab` - Added SSD mount entry
3. `/etc/docker/daemon.json` - Created Docker data-root configuration

### Commands to Run (in order):

```bash
# 1. Add user to docker group
sudo usermod -aG docker hieu_p_1_ai

# 2. Format and mount SSD
sudo mkfs.ext4 -F /dev/nvme0n1
sudo mkdir -p /mnt/disks/ssd
sudo mount -o discard,defaults /dev/nvme0n1 /mnt/disks/ssd
sudo chmod 777 /mnt/disks/ssd

# 3. Get UUID for fstab
sudo blkid /dev/nvme0n1

# 4. Add to fstab (replace UUID with actual value from step 3)
echo "UUID=<UUID_FROM_STEP_3> /mnt/disks/ssd ext4 discard,defaults 0 2" | sudo tee -a /etc/fstab

# 5. Setup Docker on SSD
sudo mkdir -p /mnt/disks/ssd/docker
echo '{"data-root": "/mnt/disks/ssd/docker"}' | sudo tee /etc/docker/daemon.json
sudo systemctl stop docker.socket docker.service
sudo systemctl daemon-reload
sudo systemctl start docker.socket docker.service

# 6. Install uv
curl -LsSf https://astral.sh/uv/install.sh | sh

# 7. Update .bashrc (see file contents above)
# Add docker wrapper function and uv PATH export
```

### Verification Steps:

```bash
# Verify docker group membership
groups | grep docker

# Verify SSD is mounted
df -h | grep nvme0n1

# Verify Docker is using SSD
docker info | grep "Docker Root Dir"

# Verify uv is installed
uv --version
```

---

## Additional Notes

- The docker wrapper function is necessary because Jupyter/managed environments may cache group memberships
- The SSD mount persists across reboots due to `/etc/fstab` entry
- Docker configuration persists across reboots due to `/etc/docker/daemon.json`
- All changes to `~/.bashrc` will be available in new shell sessions

