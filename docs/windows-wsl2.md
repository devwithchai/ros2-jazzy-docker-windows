# Windows + WSL 2 + Docker Setup

This document explains the host-side architecture and setup before starting the ROS 2 container.

## Architecture

```text
Windows
  |
  +-- WSL 2
  |     |
  |     +-- Ubuntu
  |     +-- WSLg (Linux GUI applications)
  |     +-- Docker CLI
  |
  +-- Docker Desktop
         |
         +-- Linux container engine
                |
                +-- ROS 2 Jazzy
```

The active ROS 2 workspace is kept inside the WSL Linux filesystem:

```text
~/ros2_jazzy_dev/ros2_ws
```

and bind-mounted into the container as:

```text
/ros2_ws
```

This keeps source code independent of the container lifecycle.

> [Screenshot placeholder: Windows/WSL/Docker architecture diagram]
>
> `<!-- Add screenshot here -->`

---

## 1. Check WSL

Open a normal Windows PowerShell and run:

```powershell
wsl --status
wsl --version
wsl -l -v
```

Your Ubuntu distribution should use WSL 2:

```text
NAME      STATE      VERSION
Ubuntu    Running    2
```

> [Screenshot placeholder: `wsl --version` and `wsl -l -v`]
>
> `<!-- Add screenshot here -->`

If Ubuntu is not version 2, follow Microsoft's WSL documentation before continuing.

---

## 2. Check Docker Desktop

From PowerShell:

```powershell
docker version
docker info
```

You should see a Docker **Client** and **Server** section. The Server should identify Docker Desktop and the Linux engine.

From Ubuntu/WSL, Docker should also work:

```bash
docker version
docker info
```

If WSL reports that it cannot connect to `/var/run/docker.sock`, Docker Desktop's WSL integration is not correctly enabled yet.

> [Screenshot placeholder: Docker Desktop version / `docker version`]
>
> `<!-- Add screenshot here -->`

---

## 3. Enable Docker Desktop WSL integration

In Docker Desktop, open:

```text
Settings
  -> Resources
  -> WSL Integration
```

Enable:

```text
Enable integration with my default WSL distro
```

and enable your Ubuntu distribution.

Apply the changes and allow Docker Desktop to restart if requested.

Then verify again from Ubuntu:

```bash
docker version
```

The command should now return both Client and Server information.

> [Screenshot placeholder: Docker Desktop WSL Integration page]
>
> `<!-- Add screenshot here -->`

---

## 4. WSLg and Linux GUI support

WSLg allows Linux GUI applications such as RViz2 and Gazebo to appear as normal Windows desktop windows.

From Ubuntu:

```bash
echo "DISPLAY=$DISPLAY"
echo "WAYLAND_DISPLAY=$WAYLAND_DISPLAY"
```

A typical WSLg session has values similar to:

```text
DISPLAY=:0
WAYLAND_DISPLAY=wayland-0
```

Check the X11 socket:

```bash
ls -la /tmp/.X11-unix
```

You should see an `X0` socket.

> [Screenshot placeholder: WSLg environment variables and `/tmp/.X11-unix`]
>
> `<!-- Add screenshot here -->`

### Optional graphics checks

Check whether WSL exposes the Windows graphics device:

```bash
ls -l /dev/dxg
```

and:

```bash
ls -l /usr/lib/wsl/lib/libd3d12.so
```

A working WSLg stack can use the Windows graphics path even when the laptop has only integrated graphics.

This project was validated on Intel UHD integrated graphics with no dedicated GPU.

---

## 5. Resource planning for 8 GB RAM systems

On an 8 GB laptop, avoid treating Docker as a separate full virtual machine with a permanently reserved block of RAM.

WSL 2 and Docker Desktop manage memory dynamically, subject to the configured WSL/resource limits.

A practical starting point for this project is around 4 GB available to WSL/Docker while leaving the remainder for Windows and normal applications.

Check the effective Docker memory from Ubuntu:

```bash
docker info --format "Memory: {{.MemTotal}}"
```

For an 8 GB machine, keep the active workload modest. Basic ROS 2 nodes, RViz2, small Gazebo worlds, URDF work and course examples are the primary target.

> [Screenshot placeholder: Docker memory/resource settings]
>
> `<!-- Add screenshot here -->`

---

## 6. Keep ROS workspaces in the WSL filesystem

Create the workspace under your WSL home directory:

```bash
mkdir -p ~/ros2_jazzy_dev/ros2_ws/src
```

Prefer:

```text
/home/<user>/ros2_jazzy_dev
```

rather than:

```text
/mnt/c/Users/<user>/...
```

for active ROS 2 development.

The WSL Linux filesystem avoids unnecessary filesystem translation for tools such as Git, CMake and `colcon` and is the preferred location for the active development tree.

Use Windows/NTFS storage for backups or archives when appropriate, but keep the active build workspace in WSL.

---

## 7. Docker Compose project layout

The final project directory used by this guide is:

```text
~/ros2_jazzy_dev/
├── Dockerfile
├── compose.yaml
└── ros2_ws/
    └── src/
```

Start the container from this directory:

```bash
cd ~/ros2_jazzy_dev
docker compose up -d
```

Enter it with:

```bash
docker compose exec ros2 bash
```

Or, from any PowerShell/WSL location, use the container name:

```bash
docker exec -it mastering_ros2_jazzy bash
```

---

## 8. Common command-context mistake

PowerShell and Bash use different line continuation syntax.

### PowerShell

```powershell
docker run -it `
  --name example `
  ubuntu
```

### Bash / WSL

```bash
docker run -it \
  --name example \
  ubuntu
```

Do not paste PowerShell backticks into a Bash terminal. In Bash, backticks have a different meaning and can turn a multi-line command into a series of unrelated commands.

---

## 9. WSL shutdown/recovery

If Docker Desktop reports that WSL integration unexpectedly stopped, first stop WSL cleanly:

```powershell
wsl --shutdown
```

Check the state:

```powershell
wsl -l -v
```

If a specific Ubuntu instance remains running, it can be terminated safely:

```powershell
wsl --terminate Ubuntu
```

These commands stop the WSL instance; they do **not** unregister or delete Ubuntu.

Restart Docker Desktop, ensure Ubuntu integration is enabled, and test:

```powershell
wsl
```

then inside Ubuntu:

```bash
docker version
```

---

## 10. NTFS drives and Windows storage

Windows NTFS partitions can be mounted in Ubuntu, for example:

```text
/media/<user>/New Volume
```

Before using an NTFS partition for important backups, verify it from elevated Windows tools when necessary:

```powershell
chkdsk C: /scan
chkdsk D: /scan
```

A healthy result reports that Windows found no problems.

If Linux reports that an NTFS volume is already exclusively opened, check whether it is already mounted:

```bash
lsblk -o NAME,LABEL,MOUNTPOINTS
```

Do not force filesystem repair operations against an actively mounted NTFS volume.

---

## 11. Recommended workflow

Once the host-side setup is healthy:

```bash
cd ~/ros2_jazzy_dev
docker compose up -d
docker compose exec ros2 bash
```

Inside the container:

```bash
echo $ROS_DISTRO
```

Expected:

```text
jazzy
```

Then continue with the ROS 2 setup and validation documented in the main README.

---

## References

- Microsoft WSL documentation: https://learn.microsoft.com/windows/wsl/
- Microsoft WSL GUI applications: https://learn.microsoft.com/windows/wsl/tutorials/gui-apps
- Docker Desktop WSL 2 integration: https://docs.docker.com/desktop/features/wsl/
- Docker WSL development guidance: https://docs.docker.com/desktop/features/wsl/use-wsl/
