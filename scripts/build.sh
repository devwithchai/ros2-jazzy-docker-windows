#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."

echo "Building ROS 2 Jazzy Docker image..."

docker compose build \
  --build-arg USER_UID="$(id -u)" \
  --build-arg USER_GID="$(id -g)"

echo "Build complete."
