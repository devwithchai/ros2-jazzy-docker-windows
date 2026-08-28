FROM osrf/ros:jazzy-desktop

ENV DEBIAN_FRONTEND=noninteractive
ENV ROS_DISTRO=jazzy

RUN apt-get update && apt-get install -y \
    git \
    build-essential \
    cmake \
    python3-colcon-common-extensions \
    python3-rosdep \
    python3-vcstool \
    python3-pip \
    ros-dev-tools \
    ros-jazzy-ros-gz \
    ros-jazzy-ros2-control \
    ros-jazzy-ros2-controllers \
    ros-jazzy-xacro \
    ros-jazzy-joint-state-publisher \
    ros-jazzy-joint-state-publisher-gui \
    ros-jazzy-robot-state-publisher \
    ros-jazzy-tf2-tools \
    && rm -rf /var/lib/apt/lists/*

# Build arguments supplied by docker compose. Matching the WSL user's UID/GID
# prevents bind-mounted workspace files from becoming owned by root.
ARG USERNAME=ros
ARG USER_UID=1001
ARG USER_GID=1001

RUN groupadd --gid ${USER_GID} ${USERNAME} && \
    useradd --uid ${USER_UID} --gid ${USER_GID} \
    --create-home --shell /bin/bash ${USERNAME}

# WSLg/GUI applications need a writable runtime directory for the container user.
RUN mkdir -p /tmp/runtime-ros && \
    chown ${USERNAME}:${USERNAME} /tmp/runtime-ros && \
    chmod 700 /tmp/runtime-ros

ENV XDG_RUNTIME_DIR=/tmp/runtime-ros

RUN echo "source /opt/ros/jazzy/setup.bash" >> /home/${USERNAME}/.bashrc

WORKDIR /ros2_ws

USER ${USERNAME}
