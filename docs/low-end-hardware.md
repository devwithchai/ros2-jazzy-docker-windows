# Low-End Hardware Guide

## Target system

This project was developed and validated on a Windows laptop with:

| Component | Test system |
|---|---|
| RAM | **8 GB** |
| Storage | **512 GB SSD** |
| GPU | **Intel UHD integrated graphics** |
| Dedicated GPU | None |
| CPU | 64-bit laptop CPU |
| Host | Windows + WSL 2 + Docker Desktop |
| ROS | ROS 2 Jazzy |
| GUI | WSLg |

The objective is to make ROS 2 learning practical on modest student hardware.

> [Screenshot placeholder: Test laptop specifications]
>
> `<!-- Add screenshot here -->`

---

## What works well

Basic development is realistic on an 8 GB machine:

```text
ROS 2 CLI                  ✓
C++ / Python nodes         ✓
Topics                     ✓
Services                   ✓
Actions                    ✓
Custom interfaces          ✓
colcon builds              ✓
RViz2                      ✓
Small Gazebo worlds        ✓
URDF / Xacro               ✓
Basic robot simulation     ✓
```

The practical boundary is workload size rather than whether ROS 2 itself can run.

---

## What becomes expensive

Expect increasing pressure on RAM and integrated graphics when combining several heavy workloads:

```text
Large Gazebo worlds
High-resolution camera simulation
Large point clouds
SLAM + Nav2 + Gazebo + RViz simultaneously
Complex MoveIt 2 scenes
Computer vision pipelines
Machine learning workloads
```

These workloads may still be possible, but performance can become uncomfortable on 8 GB systems.

> [Screenshot placeholder: Gazebo/RViz running on the test machine]
>
> `<!-- Add screenshot here -->`

---

## Why integrated graphics can be enough

A dedicated NVIDIA or AMD GPU is not a prerequisite for basic RViz2 and Gazebo learning.

The graphics path in this setup is approximately:

```text
RViz2 / Gazebo
      |
      v
Docker Linux container
      |
      v
WSL 2
      |
      v
WSLg
      |
      v
Windows graphics stack
      |
      v
Intel integrated graphics
```

On the test machine, RViz2 and Gazebo Harmonic both rendered successfully using Intel integrated graphics.

Check WSL graphics access with:

```bash
ls -l /dev/dxg
ls -l /usr/lib/wsl/lib/libd3d12.so
```

If those paths are present, WSL has the Windows graphics interface available.

The best validation is still the actual application:

```bash
rviz2
gz sim
```

---

## RAM strategy for 8 GB systems

The goal is not to maximize the amount of RAM assigned to Docker. Windows itself needs memory for the desktop, browser, IDE and other applications.

A practical approach is:

```text
8 GB physical RAM
|
+-- Windows + normal applications
|
+-- WSL 2 / Docker
      |
      +-- ROS 2 / RViz / Gazebo
```

The exact split depends on your workflow and WSL configuration.

Check Docker's effective memory view with:

```bash
docker info --format "Memory: {{.MemTotal}}"
```

Do not infer RAM usage from Docker image size. A multi-gigabyte image is mostly disk storage; RAM usage depends on what is running.

---

## Practical low-RAM workflow

### 1. Keep only necessary applications open

A browser with many tabs, an IDE, Docker Desktop, Gazebo and RViz can compete for the same physical memory.

### 2. Run one heavy GUI workload at a time while learning

For example:

```text
RViz2 + ROS nodes
```

or:

```text
Gazebo + ROS nodes
```

Rather than immediately running every visualization and simulation tool together.

### 3. Prefer small simulation worlds

Start with simple robots, simple environments and low-resolution sensors.

### 4. Build only what you need

Large course repositories can contain many independent packages.

Use:

```bash
colcon list
```

and targeted builds such as:

```bash
colcon build \
  --symlink-install \
  --packages-up-to <package_name>
```

### 5. Clean stale build artifacts when necessary

If a workspace has accumulated old outputs:

```bash
rm -rf build install log
```

Then rebuild the required packages.

---

## Storage strategy

A 512 GB SSD is more than enough for the base environment and course source, but Docker images, package caches and simulation data can grow over time.

Useful checks:

```bash
df -h /
docker system df
```

Avoid deleting Docker data blindly. Inspect it first.

For large Windows files or backups, a Windows/NTFS partition can be useful, but keep the active ROS development workspace in the WSL Linux filesystem.

---

## Keep the active workspace inside WSL

Preferred:

```text
~/ros2_jazzy_dev/ros2_ws
```

Avoid making the primary active build workspace:

```text
/mnt/c/Users/<user>/...
```

for day-to-day ROS development.

The WSL Linux filesystem gives Linux-native tooling a more natural environment and avoids unnecessary Windows filesystem translation during development.

---

## What about an even weaker laptop?

The 8 GB Intel UHD test case should not be treated as a minimum specification for every workload.

A machine with:

- 4 GB RAM
- older CPU
- slower disk
- older integrated graphics

will have a substantially harder time with Gazebo/RViz workloads.

However, even on modest hardware, ROS 2 command-line learning can remain useful:

```text
Topics
Services
Actions
Parameters
Launch
TF2 concepts
URDF structure
Nodes and executors
```

This project focuses first on reducing environment/setup friction.

---

## Power-saving and laptop thermals

Simulation can keep a laptop CPU active for long periods. On battery power, expect lower performance and shorter battery life.

For longer Gazebo sessions:

- use AC power where practical;
- keep vents clear;
- avoid unnecessary background workloads;
- monitor system temperature if the laptop runs hot.

This is especially relevant for thin student laptops.

---

## Recommended expectations

### Green zone

```text
Learning ROS 2 CLI
Simple C++/Python nodes
Topics / Services / Actions
Custom messages
Simple URDF
RViz2
Small Gazebo worlds
```

### Yellow zone

```text
Gazebo + RViz simultaneously
Nav2 in a non-trivial world
SLAM
Multiple simulated sensors
Point clouds
MoveIt scenes
```

### Red zone for this hardware class

```text
Large simulation environments
Many high-resolution sensors
Heavy perception + simulation + navigation stacks
ML workloads
```

This is a workload guideline, not a hard technical boundary.

---

## Bottom line

You do not need a high-end gaming PC to start learning ROS 2.

An 8 GB Windows laptop with Intel integrated graphics can provide a useful development environment when the workload is kept realistic and the software stack is designed carefully.

The goal of this project is to make that path straightforward:

```text
Windows
  -> WSL 2
  -> Docker Desktop
  -> ROS 2 Jazzy
  -> WSLg
  -> RViz2 / Gazebo
  -> Learn robotics
```
