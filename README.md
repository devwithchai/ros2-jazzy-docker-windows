# ROS 2 Jazzy + RViz2 + Gazebo on Windows

> **ROS 2 Jazzy + RViz2 + Gazebo on Windows using Docker, WSL 2 and WSLg — tested on an 8 GB RAM laptop with Intel integrated graphics.**

[![ROS 2 Jazzy](https://img.shields.io/badge/ROS%202-Jazzy-blue)](https://docs.ros.org/en/jazzy/)
[![Docker](https://img.shields.io/badge/Docker-Desktop-2496ED)](https://www.docker.com/products/docker-desktop/)
[![WSL 2](https://img.shields.io/badge/Windows-WSL%202-4D4D4D)](https://learn.microsoft.com/windows/wsl/)
[![RViz2](https://img.shields.io/badge/RViz2-Visualization-orange)](https://docs.ros.org/en/jazzy/p/rviz2/)
[![Gazebo Harmonic](https://img.shields.io/badge/Gazebo-Harmonic-FF6F00)](https://gazebosim.org/)

A practical, reproducible ROS 2 Jazzy development environment for **Windows 10/11** using **Docker Desktop + WSL 2 + WSLg**.

This project focuses on a common problem: *How do I learn and develop with ROS 2 on a Windows laptop without installing a large robotics stack directly into Windows or owning a powerful GPU?*

The setup was built and tested on a modest **8 GB RAM laptop with Intel integrated graphics and no dedicated graphics card**.

---

## What this project provides

- ROS 2 Jazzy CLI, `colcon`, `rosdep` and development tools
- RViz2 with WSLg GUI forwarding
- Gazebo / Gazebo Harmonic integration
- ROS ↔ Gazebo integration through `ros_gz`
- `ros2_control` and common robot-description packages
- Persistent ROS 2 workspace through a bind mount
- Non-root development user with WSL UID/GID mapping
- Hands-on validation of Topics, Services and Actions
- Practical Windows/WSL/Docker/GUI troubleshooting

---

## Hardware target

| Component | Tested baseline |
|---|---|
| OS | Windows 10/11 + WSL 2 |
| RAM | **8 GB** |
| Storage | **512 GB SSD** |
| GPU | **Intel integrated graphics** |
| Dedicated GPU | None |
| Container runtime | Docker Desktop, Linux containers |
| ROS 2 | Jazzy |
| Gazebo | Harmonic |
| GUI | WSLg |

This setup targets **learning and lightweight robotics development**. Large simulation worlds, high-resolution sensors, SLAM + Nav2 + Gazebo + RViz combinations, and ML workloads can require substantially more resources.

---

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
              +-- Gazebo
              +-- ros_gz
              +-- ros2_control
              +-- colcon / rosdep
              +-- persistent workspace mount
```

The key design principle is:

> **The container is disposable; your source workspace is persistent.**

```text
~/ros2_jazzy_dev/ros2_ws
          |
          +---- bind mount ----> /ros2_ws
```

> [Screenshot placeholder: overall Windows → WSL 2 → Docker → ROS 2 architecture]
>
> `<!-- Add screenshot here -->`

---

# Quick start

## 1. Prerequisites

Install/enable:

- Windows 10/11
- WSL 2
- Ubuntu under WSL 2
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

Detailed setup notes will live in `docs/windows-wsl2.md`.

---

## 2. Enable Docker → WSL integration

In Docker Desktop:

```text
Settings
  → Resources
  → WSL Integration
```

Enable integration with your Ubuntu WSL distribution.

> [Screenshot placeholder: Docker Desktop WSL Integration settings]
>
> `<!-- Add screenshot here -->`

---

## 3. Create the development workspace

Inside Ubuntu/WSL:

```bash
mkdir -p ~/ros2_jazzy_dev/ros2_ws/src
cd ~/ros2_jazzy_dev
```

Prefer the WSL Linux filesystem (`~/...`) instead of `/mnt/c/...` for the active ROS workspace.

---

## 4. Build the Docker environment

Place `Dockerfile` and `compose.yaml` in `~/ros2_jazzy_dev/`.

Then:

```bash
docker compose build \
  --build-arg USER_UID=$(id -u) \
  --build-arg USER_GID=$(id -g)
```

Start the container:

```bash
docker compose up -d
```

Check it:

```bash
docker ps
```

Expected container name:

```text
mastering_ros2_jazzy
```

> [Screenshot placeholder: successful Docker build and `docker ps`]
>
> `<!-- Add screenshot here -->`

---

## 5. Enter the container

From WSL, inside `~/ros2_jazzy_dev`:

```bash
docker compose exec ros2 bash
```

Or from any PowerShell/WSL terminal:

```powershell
docker exec -it mastering_ros2_jazzy bash
```

### Important: image name vs container name

Docker commands such as `docker exec` need the **container name**, not the image name.

Check the actual running container with:

```powershell
docker ps
```

For this project the container is:

```text
mastering_ros2_jazzy
```

---

## 6. Verify ROS 2

Inside the container:

```bash
whoami
echo $ROS_DISTRO
```

Expected:

```text
ros
jazzy
```

Check core packages:

```bash
ros2 pkg prefix rclcpp
ros2 pkg prefix std_msgs
ros2 pkg prefix rviz2
ros2 pkg prefix ros_gz_sim
ros2 pkg prefix ros_gz_bridge
ros2 pkg prefix ros2_control
```

ROS-installed packages should resolve under:

```text
/opt/ros/jazzy
```

> [Screenshot placeholder: ROS 2 package verification]
>
> `<!-- Add screenshot here -->`

---

# GUI validation

The compose configuration supports the WSLg GUI path used by this project.

## RViz2

Inside the container:

```bash
rviz2
```

A normal RViz2 window should appear on the Windows desktop.

> [Screenshot placeholder: RViz2 running from Docker]
>
> `<!-- Add screenshot here -->`

## Gazebo

For a basic GUI smoke test:

```bash
gz sim
```

Gazebo should open through WSLg.

Verify ROS/Gazebo integration:

```bash
ros2 pkg prefix ros_gz_bridge
ros2 pkg prefix ros_gz_sim
```

> [Screenshot placeholder: Gazebo Harmonic running from Docker]
>
> `<!-- Add screenshot here -->`

### Low-resource recommendation

On an 8 GB machine:

- Start with small Gazebo worlds.
- Close unnecessary applications while simulating.
- Avoid multiple simultaneous simulations.
- Build only the ROS packages you need.
- Prefer headless simulation when visualization is unnecessary.

---

# Build a ROS 2 workspace

The bind-mounted workspace is:

```text
/ros2_ws
```

List discovered packages:

```bash
cd /ros2_ws
colcon list
```

For large learning repositories, build a focused package and its dependencies:

```bash
colcon build \
  --symlink-install \
  --packages-up-to <package_name>
```

Then:

```bash
source /ros2_ws/install/setup.bash
```

Verify:

```bash
ros2 pkg prefix <package_name>
```

---

# ROS 2 communication validation

This project validates the three core ROS 2 communication patterns.

| Mechanism | Pattern | Typical use |
|---|---|---|
| **Topic** | Publisher → Subscriber | Continuous/asynchronous data |
| **Service** | Client → Request → Response | Short request/response |
| **Action** | Goal → Feedback → Result | Long-running tasks |

The complete hands-on guide is in:

**`docs/ros2-communication.md`**

It includes:

- custom `.msg`, `.srv` and `.action` interfaces
- CLI inspection commands
- C++ publisher/subscriber
- C++ service client/server
- C++ action client/server
- expected output
- troubleshooting

> [Screenshot placeholder: Topics vs Services vs Actions]
>
> `<!-- Add screenshot here -->`

---

# Packt Mastering ROS 2 examples

The environment was validated with the Packt Publishing *Mastering ROS 2 for Robotics Programming* repository.

Clone it into the persistent workspace:

```bash
cd ~/ros2_jazzy_dev/ros2_ws/src

git clone \
  https://github.com/PacktPublishing/Mastering-ROS-2-for-Robotics-Programming.git \
  mastering_ros2
```

### Important: don't build everything blindly

The upstream learning repository is organized by chapter and contains packages with repeated names and different dependency sets.

Use a focused workflow:

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

This project successfully used this approach for Chapter 3 communication examples.

---

# Troubleshooting

This repository is intentionally a **field guide**, not just an installation recipe.

Windows + WSL 2 + Docker + ROS 2 has several layers:

```text
Windows
  │
  ├── PowerShell
  │
  └── WSL 2
       │
       └── Docker CLI
            │
            └── Docker Desktop
                 │
                 └── ROS 2 container
                      ├── DDS networking
                      ├── bind mounts
                      ├── user permissions
                      └── WSLg GUI
```

When something fails, first identify **which layer failed**.

Issues documented/planned include:

- Docker Desktop ↔ WSL integration
- Docker memory/resource constraints
- PowerShell vs Bash command syntax
- Docker image vs container naming
- running `docker compose` from the wrong directory
- WSL Linux filesystem vs `/mnt/c`
- bind-mounted workspace permissions
- non-root UID/GID mapping
- WSLg `DISPLAY` / X11 socket issues
- RViz2 Qt/X11 errors
- Intel integrated graphics
- ROS 2 environment sourcing
- package discovery and `colcon` build scope
- DDS discovery between processes

See the documentation under `docs/` as it develops.

---

# Why Docker?

For a Windows learner, Docker provides a reproducible and isolated Linux-first ROS environment without requiring a native Windows ROS installation or dual boot.

Benefits:

- isolated dependencies
- reproducible setup
- easy environment reset
- clean Windows host
- shareable configuration

Trade-offs:

- GUI forwarding is more involved
- filesystem and permissions need attention
- Docker/WSL adds another layer to debug
- simulation still consumes significant CPU/RAM

This project documents those trade-offs rather than hiding them.

---

# Project structure

```text
ros2-jazzy-docker-windows/
├── README.md
├── Dockerfile
├── compose.yaml
├── .gitignore
├── docs/
│   ├── ros2-communication.md
│   ├── troubleshooting.md
│   ├── windows-wsl2.md
│   ├── rviz2.md
│   ├── gazebo.md
│   └── low-end-hardware.md
└── ros2_ws/
    └── ...
```

Documentation files can be expanded as additional Windows-specific problems are reproduced and validated.

---

# Validation status

```text
Docker image build                    ✓
Container startup                    ✓
Non-root ROS user                    ✓
ROS_DISTRO=jazzy                     ✓
ROS 2 core packages                  ✓
RViz2 package                        ✓
Gazebo ROS integration               ✓
ros_gz_bridge                        ✓
ros2_control                         ✓
colcon workspace                     ✓
Custom message                      ✓
Topic communication                  ✓
Service communication                ✓
Action communication                 ✓
```

> [Screenshot placeholder: final validation montage — Docker + RViz2 + Gazebo + ROS 2 CLI]
>
> `<!-- Add screenshot here -->`

---

# Contributing

Found a Windows, WSL, Docker, graphics, RViz2, Gazebo or ROS 2 issue?

Please open an issue with:

1. Windows version
2. WSL version
3. Docker Desktop version
4. ROS 2 distribution
5. RAM/GPU information
6. Exact command used
7. Complete error output
8. Expected vs actual behavior

Reproducible reports make it much easier to turn problems into reusable documentation.

---

# References

- ROS 2 Jazzy documentation: https://docs.ros.org/en/jazzy/
- Docker Desktop WSL: https://docs.docker.com/desktop/features/wsl/
- Microsoft WSL GUI apps: https://learn.microsoft.com/en-us/windows/wsl/tutorials/gui-apps
- Gazebo: https://gazebosim.org/
- ROS Docker images: https://hub.docker.com/_/ros
- Packt Mastering ROS 2 repository: https://github.com/PacktPublishing/Mastering-ROS-2-for-Robotics-Programming

---

## Project goal

> **Make ROS 2 development on an ordinary Windows laptop approachable, reproducible and understandable.**

If this helps someone learn ROS 2 without needing a dedicated Linux workstation or high-end GPU, the project has done its job.
