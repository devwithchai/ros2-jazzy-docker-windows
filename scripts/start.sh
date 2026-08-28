#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."

docker compose up -d

echo "Container started."
echo "Enter with: docker compose exec ros2 bash"
