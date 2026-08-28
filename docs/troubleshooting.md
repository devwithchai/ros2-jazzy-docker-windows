# Troubleshooting

This page collects the Windows, WSL 2, Docker and ROS 2 problems encountered while building and testing this environment.

The goal is not to hide the rough edges. If a setup issue is common enough to cost a beginner an hour, document it here.

---

## 1. `docker exec` says the container does not exist

Example:

```text
docker exec -it ros2_jazzy_dev bash
Error response from daemon: No such container: ros2_jazzy_dev
```

The argument to `docker exec` is the **container name**, not the image name or project directory.

Check running containers:

```powershell
docker ps
```

Example:

```text
CONTAINER ID   IMAGE                  STATUS       NAMES
...            ros2_jazzy_dev-ros2   Up ...       mastering_ros2_jazzy
```

Then use:

```powershell
docker exec -it mastering_ros2_jazzy bash
```

Or, if you are inside the Compose project directory:

```bash
docker compose exec ros2 bash
```

### Remember

```text
Image name    !=    Container name
ros2_jazzy_dev-ros2       mastering_ros2_jazzy
```

> [Screenshot placeholder: `docker ps` showing image and container name]
>
> `<!-- Add screenshot here -->`

---

## 2. `docker compose exec` says "no configuration file provided"

Example:

```text
docker compose exec ros2 bash
no configuration file provided: not found
```

Docker Compose searches the current directory for `compose.yaml`, `compose.yml`, `docker-compose.yaml` or `docker-compose.yml`.

If you are in:

```text
C:\WINDOWS\system32
```

it will not find the project's Compose file.

Enter WSL and move to the project directory:

```bash
cd ~/ros2_jazzy_dev
docker compose exec ros2 bash
```

Or use the container-name method from any directory:

```powershell
docker exec -it mastering_ros2_jazzy bash
```

---

## 3. `cd ~/ros2_jazzy_dev` fails in PowerShell

This command:

```powershell
cd ~/ros2_jazzy_dev
```

looks reasonable, but PowerShell's `~` points to the Windows user's home directory.

The project is stored in the WSL Linux filesystem, so the WSL path is different.

Use:

```powershell
wsl
```

then:

```bash
cd ~/ros2_jazzy_dev
```

Conceptually:

```text
Windows PowerShell
    ~
    └── C:\Users\<WindowsUser>

WSL Ubuntu
    ~
    └── /home/<LinuxUser>
```

> [Screenshot placeholder: PowerShell path error followed by successful WSL `cd`]
>
> `<!-- Add screenshot here -->`

---

## 4. Container starts as `root` instead of `ros`

Check inside the container:

```bash
whoami
id
```

The expected result for this project is approximately:

```text
ros
uid=1001(ros) gid=1001(ros) groups=1001(ros)
```

The Dockerfile creates a non-root user and sets it as the default user.

If an older image/container still starts as root, rebuild and recreate it:

```bash
docker compose down
docker compose build \
  --build-arg USER_UID=$(id -u) \
  --build-arg USER_GID=$(id -g)
docker compose up -d
docker compose exec ros2 bash
```

Then verify:

```bash
whoami
id
```

### Why this matters

The ROS workspace is bind-mounted from WSL:

```text
./ros2_ws:/ros2_ws
```

Running build tools as root can create files owned by root on the host-side WSL filesystem. Matching the container user's UID/GID with the WSL user avoids that class of permission problem.

> [Screenshot placeholder: `whoami` / `id` showing `ros`]
>
> `<!-- Add screenshot here -->`

---

## 5. Verify the runtime directory

Inside the container:

```bash
echo $XDG_RUNTIME_DIR
```

Expected:

```text
/tmp/runtime-ros
```

Check ownership and permissions:

```bash
ls -ld /tmp/runtime-ros
```

The directory should be writable by the `ros` user and should not be world-writable.

This directory is created in the Docker image because GUI applications and middleware components may require a user runtime directory.

---

## 6. Files in `/ros2_ws` are not writable

Test the bind mount:

```bash
cd /ros2_ws
touch test_write
rm test_write
```

If this succeeds, the container user can write to the workspace.

Also check:

```bash
ls -ld /ros2_ws
```

If files were previously created as root, inspect ownership:

```bash
ls -la /ros2_ws | head
```

Avoid solving ownership problems with `chmod -R 777`. Fix the UID/GID or ownership at the source instead.

---

## 7. ROS 2 is installed, but packages from the workspace cannot be found

First source the ROS installation:

```bash
source /opt/ros/jazzy/setup.bash
```

Then, after building your workspace:

```bash
source /ros2_ws/install/setup.bash
```

Verify:

```bash
echo "ROS_DISTRO=$ROS_DISTRO"
ros2 pkg prefix rclcpp
```

Expected:

```text
ROS_DISTRO=jazzy
/opt/ros/jazzy
```

After building a local package, its prefix should point into `/ros2_ws/install`.

Example:

```bash
ros2 pkg prefix master_ros2_interface
ros2 pkg prefix master_ros2_pkg
```

---

## 8. `rosdep check` reports missing dependencies

For a package tree:

```bash
rosdep check \
  --from-paths src/mastering_ros2/Chapter03 \
  --ignore-src
```

If everything is installed:

```text
All system dependencies have been satisfied
```

If dependencies are missing, update rosdep metadata and install what is required before building:

```bash
rosdep update
rosdep install \
  --from-paths src/mastering_ros2/Chapter03 \
  --ignore-src \
  -r \
  -y
```

A `pkg_resources is deprecated` warning from the installed Python tooling is not, by itself, a ROS dependency failure.

---

## 9. `colcon build` shows warnings on `stderr` but succeeds

A build can print compiler warnings while still completing successfully.

Example:

```text
--- stderr: master_ros2_pkg
... warning: unused parameter ...
---
Finished <<< master_ros2_pkg
```

The important part is the final summary:

```text
Summary: 2 packages finished
```

Warnings such as unused parameters should still be cleaned up eventually, but they do not necessarily mean the build failed.

---

## 10. Duplicate package names appear in `colcon list`

If `colcon list` reports the same package name more than once, inspect the paths.

For example, a large learning workspace can contain multiple chapter examples with packages sharing names:

```text
rosbot_description  .../Chapter04/rosbot_description
rosbot_description  .../Chapter05/rosbot_description
rosbot_description  .../Chapter08/rosbot_description
```

Do not blindly build the entire repository in this situation.

Prefer targeted builds:

```bash
colcon build --symlink-install --packages-up-to <package_name>
```

or build only the chapter you are currently working on.

---

## 11. ROS 2 topic appears and disappears

Check the active graph:

```bash
ros2 node list
ros2 topic list
```

If a publisher exits, its topic disappears.

For a running publisher:

```bash
ros2 topic info /custom_topic
```

For example:

```text
Type: master_ros2_interface/msg/CustomMsg
Publisher count: 1
Subscription count: 1
```

Use:

```bash
ros2 node info /publisher_node
```

to inspect publishers, subscribers, services and actions associated with a node.

---

## 12. Check a topic's actual message rate

Use:

```bash
ros2 topic hz /custom_topic
```

A publisher configured for approximately 1 Hz should report a rate close to:

```text
average rate: 1.000
```

Small timing variations are normal.

---

## 13. RViz2 or Gazebo GUI does not appear

Start by checking WSLg on the host:

```bash
echo $DISPLAY
echo $WAYLAND_DISPLAY
ls -la /tmp/.X11-unix
```

Then check the same environment inside the container:

```bash
echo $DISPLAY
ls -la /tmp/.X11-unix
```

The Compose configuration passes `DISPLAY` into the container and mounts `/tmp/.X11-unix`.

If the host-side WSLg environment is broken, changing the container configuration will not fix it.

> [Screenshot placeholder: WSLg environment on host]
>
> `<!-- Add screenshot here -->`

> [Screenshot placeholder: RViz2 running from the container]
>
> `<!-- Add screenshot here -->`

---

## 14. RViz2 / Qt reports display-related errors

Check:

```bash
echo $DISPLAY
```

and:

```bash
ls -la /tmp/.X11-unix
```

The Compose file includes:

```yaml
environment:
  DISPLAY: ${DISPLAY}
  QT_X11_NO_MITSHM: "1"
```

and:

```yaml
volumes:
  - /tmp/.X11-unix:/tmp/.X11-unix
```

Do not add random X11 variables until the actual error is known. Diagnose the host WSLg environment first, then the container environment.

---

## 15. Gazebo starts but the laptop becomes extremely slow

This project targets low-resource hardware, not high-end simulation workloads.

On an 8 GB RAM laptop with integrated graphics:

- start with small Gazebo worlds;
- avoid running several heavy GUI applications simultaneously;
- close unnecessary Windows applications;
- monitor WSL/Docker memory usage;
- stop unused containers;
- use RViz2 and Gazebo separately while learning when possible.

A successful ROS 2 environment does not mean every large simulation will be comfortable on an 8 GB machine.

> [Screenshot placeholder: Gazebo running on the low-end test laptop]
>
> `<!-- Add screenshot here -->`

---

## 16. Docker Desktop / WSL behaves strangely after sleep or updates

A simple recovery sequence is:

### PowerShell

```powershell
wsl --shutdown
```

Then restart Docker Desktop.

If required:

```powershell
wsl -l -v
```

and terminate only the affected distribution:

```powershell
wsl --terminate Ubuntu
```

Then launch Ubuntu again:

```powershell
wsl
```

and verify:

```bash
docker version
```

> [Screenshot placeholder: WSL recovery sequence]
>
> `<!-- Add screenshot here -->`

---

## 17. Always know which environment you are in

When troubleshooting, check:

```bash
whoami
pwd
hostname
```

and:

```bash
echo $ROS_DISTRO
```

A useful mental model is:

```text
Windows PowerShell
        |
        v
      WSL 2
        |
        v
 Docker Desktop
        |
        v
 ROS 2 container
        |
        v
    /ros2_ws
```

Many seemingly unrelated errors are simply commands being executed in the wrong layer.

---

## 18. Quick health check

Inside the container:

```bash
whoami
echo "ROS_DISTRO=$ROS_DISTRO"
echo "XDG_RUNTIME_DIR=$XDG_RUNTIME_DIR"
ros2 pkg prefix rclcpp
ros2 pkg prefix std_msgs
```

Expected pattern:

```text
ros
ROS_DISTRO=jazzy
XDG_RUNTIME_DIR=/tmp/runtime-ros
/opt/ros/jazzy
/opt/ros/jazzy
```

Then, if the workspace has been built:

```bash
source /ros2_ws/install/setup.bash
ros2 pkg prefix master_ros2_interface
ros2 pkg prefix master_ros2_pkg
```

Expected pattern:

```text
/ros2_ws/install/master_ros2_interface
/ros2_ws/install/master_ros2_pkg
```

---

## 19. When asking for help

Include the output of these commands rather than only saying "ROS 2 doesn't work":

```bash
echo "ROS_DISTRO=$ROS_DISTRO"
whoami
id
pwd
docker ps
ros2 doctor --report
```

For GUI problems also include:

```bash
echo "DISPLAY=$DISPLAY"
echo "WAYLAND_DISPLAY=$WAYLAND_DISPLAY"
ls -la /tmp/.X11-unix
```

For build problems include:

```bash
colcon list
rosdep check --from-paths src --ignore-src
```

This makes troubleshooting substantially faster and avoids guessing.

---

## 20. Controlled reset procedure

If the environment becomes confusing, use a controlled reset rather than randomly changing configuration.

From WSL:

```bash
cd ~/ros2_jazzy_dev
docker compose down
```

From PowerShell, if WSL itself is behaving badly:

```powershell
wsl --shutdown
```

Restart Docker Desktop, then:

```powershell
wsl
```

Back in WSL:

```bash
cd ~/ros2_jazzy_dev
docker compose up -d
docker compose exec ros2 bash
```

Verify:

```bash
echo $ROS_DISTRO
whoami
```

Expected:

```text
jazzy
ros
```

If the workspace itself is corrupted, clean only the generated build outputs first:

```bash
cd /ros2_ws
rm -rf build install log
```

Then rebuild the required packages.

---

## 21. Rule of thumb

When debugging, move from the outside in:

```text
1. Windows
      |
2. WSL 2
      |
3. Docker Desktop
      |
4. Container
      |
5. ROS 2
      |
6. RViz / Gazebo
      |
7. Your application
```

If the layer below is broken, debugging the layer above it is usually wasted effort.
