#!/bin/bash
set -euo pipefail

image=${1:?Usage: test/docker_healthcheck.sh IMAGE}
container="som-healthcheck-$$"
trap 'docker stop --timeout=1 "$container" >/dev/null 2>&1 || true' EXIT

# Exercise Docker's CMD-SHELL path and Coolify's curl/wget HTTP probe together.
docker run --detach --rm --name "$container" --entrypoint ruby \
  --health-cmd='curl -s -X GET -f http://localhost:3000/ > /dev/null || wget -q -O- http://localhost:3000/ > /dev/null || exit 1' \
  --health-interval=1s --health-timeout=3s --health-retries=3 \
  "$image" -rsocket -e '
    server = TCPServer.new("0.0.0.0", 3000)
    loop do
      client = server.accept
      client.gets
      client.write("HTTP/1.1 200 OK\r\nContent-Length: 2\r\nConnection: close\r\n\r\nok")
      client.close
    end
  ' >/dev/null

for attempt in {1..20}; do
  status=$(docker inspect --format='{{.State.Health.Status}}' "$container")
  case "$status" in
    healthy) echo "Coolify shell HTTP health check passed"; exit 0 ;;
    unhealthy) break ;;
  esac
  sleep 1
done
docker inspect --format='{{json .State.Health}}' "$container"
exit 1
