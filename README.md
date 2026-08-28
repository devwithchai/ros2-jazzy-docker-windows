# ROS 2 Jazzy + RViz2 + Gazebo on Windows

ROS 2 Jazzy + RViz2 + Gazebo on Windows using Docker, WSL 2 and WSLg — tested on an 8 GB RAM laptop with Intel integrated graphics.

> A practical, reproducible ROS 2 development environment for Windows users who want a Linux-first robotics workflow without dual-booting.

**Stack:** ROS 2 Jazzy · Docker Desktop · WSL 2 · WSLg · RViz2 · Gazebo Harmonic · Windows

## What this project provides

This repository documents a field-tested Docker + WSL 2 setup for running ROS 2 Jazzy on Windows, including:

- ROS 2 CLI, `colcon`, `rosdep` and common development tools
- RViz2 with WSLg GUI forwarding
- Gazebo Harmonic
- ROS ↔ Gazebo integration through `ros_gz`
- A persistent ROS 2 workspace outside the container
- A non-root development user with matching UID/GID
- Hands-on validation of ROS 2 Topics, Services and Actions
- Troubleshooting for Windows/WSL/Docker/GUI issues encountered during setup

## Tested baseline

| Component | Tested |
|---|---|
| Windows | Windows 10/11 + WSL 2 |
| RAM | **8 GB** |
| Storage | **512 GB SSD** |
| GPU | **Intel integrated graphics** |
| Dedicated GPU | None |
| Docker | Docker Desktop, Linux containers |
| ROS 2 | Jazzy |
| Gazebo | Harmonic |
| GUI | WSLg |

This setup targets **learning and lightweight robotics development**. Large simulation worlds, high-resolution sensors, SLAM + Nav2 + Gazebo + RViz combinations, and ML workloads can require substantially more RAM/GPU capacity.

## Architecture

```text
Windows
  |
  +-- WSL 2
  |     |
  |     +-- WSLg (Linux GUI / graphics)
  |     |
  |     +-- Docker CLI
  |
  +-- Docker Desktop
        |
        +-- ROS 2 Jazzy container
              +-- ROS 2 CLI
              +-- RViz2
              +-- Gazebo Harmonic
              +-- ros_gz
              +-- colcon / rosdep
              +-- persistent workspace mount
```

The key design principle is:

> **The container is disposable; your source workspace is persistent.**

The ROS workspace lives in the WSL Linux filesystem and is bind-mounted into the container:

```text
~/ros2_jazzy_dev/ros2_ws
          |
          +---- bind mount ----> /ros2_ws
```

This means the container can be rebuilt or removed without deleting your source code.

## Quick start

### 1. Prerequisites

Install/enable:

- Windows with WSL 2
- Ubuntu running under WSL 2
- Docker Desktop for Windows
- Docker Desktop WSL integration for Ubuntu

Verify from PowerShell:

```powershell
wsl --status
wsl --version
wsl -l -v
docker version
```

Ubuntu should report WSL version `2`.

Verify Docker from Ubuntu too:

```bash
docker version
docker info
```

### 2. Enable Docker → WSL integration

Docker Desktop:

```text
Settings
  -> Resources
  -> WSL Integration
```

Enable:

```text
Enable integration with my default WSL distro
```

and make sure your Ubuntu distro is enabled.

### 3. Create the development workspace

Inside Ubuntu/WSL:

```bash
mkdir -p ~/ros2_jazzy_dev/ros2_ws/src
cd ~/ros2_jazzy_dev
```

Keep the active ROS workspace under `~` rather than `/mnt/c/...` for a better Linux development experience.

### 4. Build the Docker environment

Place the repository's `Dockerfile` and `compose.yaml` in `~/ros2_jazzy_dev/`.

Then:

```bash
docker compose build \
  --build-arg USER_UID=$(id -u) \
  --build-arg USER_GID=$(id -g)

docker compose up -d
```

### 5. Enter the container

From WSL, in `~/ros2_jazzy_dev`:

```bash
docker compose exec ros2 bash
```

Or from any PowerShell window:

```powershell
docker exec -it mastering_ros2_jazzy bash
```

Verify:

```bash
whoami
echo $ROS_DISTRO
```

Expected:

```text
ros
jazzy
```

## GUI validation

### RViz2

Inside the container:

```bash
rviz2
```

A normal RViz2 window should appear on the Windows desktop.

### Gazebo Harmonic

```bash
gz sim
```

Gazebo should open through WSLg.

Verify ROS/Gazebo integration:

```bash
ros2 pkg prefix ros_gz_bridge
ros2 pkg prefix ros_gz_sim
```

Expected prefix:

```text
/opt/ros/jazzy
```

## ROS 2 communication validation

This project also validates the three core ROS 2 communication patterns with a custom example workspace.

### Topics

Publisher ↔ Topic ↔ Subscriber

Example checks:

```bash
ros2 node list
ros2 topic list
ros2 topic info /custom_topic
ros2 topic echo /custom_topic
ros2 topic hz /custom_topic
```

Example custom interface:

```text
master_ros2_interface/msg/CustomMsg

string data
int32 number
```

### Services

Client → Request → Server → Response

Example:

```bash
ros2 service list
ros2 service type /concat_strings
ros2 interface show master_ros2_interface/srv/ConcatStrings
```

Call the service:

```bash
ros2 service call /concat_strings \
  master_ros2_interface/srv/ConcatStrings \
  "{str1: 'Hello ', str2: 'ROS 2'}"
```

### Actions

Client → Goal → Action Server → Feedback → Result

Example:

```bash
ros2 action list
ros2 action info /my_custom_action
```

Send a goal with feedback:

```bash
ros2 action send_goal /my_custom_action \
  master_ros2_interface/action/MyCustomAction \
  "{goal_value: 5}" \
  --feedback
```

## Packt Mastering ROS 2 repository

The environment was validated with the Packt Publishing course repository:

https://github.com/PacktPublishing/Mastering-ROS-2-for-Robotics-Programming

Clone it into the persistent workspace:

```bash
cd ~/ros2_jazzy_dev/ros2_ws/src

git clone \
  https://github.com/PacktPublishing/Mastering-ROS-2-for-Robotics-Programming.git \
  mastering_ros2
```

The repository is organized by chapter. **Do not blindly build the entire repository** because multiple chapters contain packages with repeated names and different dependency sets.

Prefer chapter/package-scoped builds such as:

```bash
colcon list

rosdep check \
  --from-paths src/mastering_ros2/Chapter03 \
  --ignore-src

colcon build \
  --symlink-install \
  --packages-up-to master_ros2_pkg

source install/setup.bash
```

## Why this project exists

ROS 2 is often learned on Linux, but many students have Windows laptops and cannot conveniently dual-boot or afford a dedicated robotics workstation.

This project aims to lower that barrier with a setup that is:

- reproducible
- transparent about trade-offs
- friendly to low-resource hardware
- useful for coursework and experimentation
- easy to troubleshoot

The goal is not to claim that Docker is the only correct ROS 2 setup. It is to provide a practical path for Windows users who want a Linux ROS 2 environment.

## Troubleshooting

The companion troubleshooting documentation captures issues encountered while building the environment, including:

- Docker Desktop ↔ WSL integration failures
- WSL shutdown/restart recovery
- Docker memory/resource confusion
- PowerShell vs Bash line continuation
- Docker image vs container naming
- `docker compose` working-directory issues
- `/mnt/c` vs WSL Linux filesystem performance
- NTFS mounting and permissions
- WSLg `DISPLAY` / X11 socket debugging
- RViz2 Qt/X11 errors
- Intel integrated graphics and WSL graphics
- root-owned files in bind-mounted workspaces

See `docs/troubleshooting.md` as the detailed reference develops.

## Recommended project structure

```text
ros2-jazzy-docker-windows/
├── README.md
├── Dockerfile
├── compose.yaml
├── .dockerignore
├── LICENSE
├── docs/
│   ├── troubleshooting.md
│   ├── windows-wsl2.md
│   ├── rviz2.md
│   ├── gazebo.md
│   └── low-end-hardware.md
├── scripts/
│   ├── build.sh
│   ├── start.sh
│   ├── shell.sh
│   └── stop.sh
└── examples/
    └── ros2-communication/
        ├── topics.md
        ├── services.md
        └── actions.md
```

## Contributing

If you find a Windows, WSL, Docker, graphics, RViz2 or Gazebo issue that is not covered here, please open an issue or pull request.

Useful diagnostics include:

```bash
wsl --version
wsl -l -v
docker version
docker info
```

and from Ubuntu:

```bash
echo $DISPLAY
echo $WAYLAND_DISPLAY
ls -la /tmp/.X11-unix
ls -l /dev/dxg
```

Also include your Windows version, RAM, GPU, Docker Desktop version, ROS 2 distribution, and exact reproduction steps.

## References

- Docker Desktop + WSL 2: https://docs.docker.com/desktop/features/wsl/
- Docker WSL development: https://docs.docker.com/desktop/features/wsl/use-wsl/
- Windows WSL GUI applications: https://learn.microsoft.com/en-us/windows/wsl/tutorials/gui-apps
- ROS 2 Jazzy: https://docs.ros.org/en/jazzy/
- ROS Docker images: https://hub.docker.com/_/ros
- Gazebo: https://gazebosim.org/
- Packt Mastering ROS 2 repository: https://github.com/PacktPublishing/Mastering-ROS-2-for-Robotics-Programming

## License

Choose a license for this project after reviewing the licensing terms of the third-party materials referenced here, including the Packt course repository.
