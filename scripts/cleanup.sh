#!/bin/bash
set -euo pipefail
docker info >/dev/null

for lab_container in web-server-1 web-server-2 db-server-1; do
  if docker container inspect "$lab_container" >/dev/null 2>&1; then
    lab_owner=$(docker container inspect --format '{{index .Config.Labels "devops.lab"}}' "$lab_container")
    test "$lab_owner" = lab4-dtc235180104 || { echo "Refusing to remove unrelated container: $lab_container" >&2; exit 1; }
  fi
done
if docker network inspect ansible-lab >/dev/null 2>&1; then
  lab_owner=$(docker network inspect --format '{{index .Labels "devops.lab"}}' ansible-lab)
  test "$lab_owner" = lab4-dtc235180104 || { echo "Refusing to remove unrelated network" >&2; exit 1; }
fi

for lab_container in web-server-1 web-server-2 db-server-1; do
  if docker container inspect "$lab_container" >/dev/null 2>&1; then
    docker rm -f "$lab_container"
  fi
done
if docker network inspect ansible-lab >/dev/null 2>&1; then
  docker network rm ansible-lab
fi
lab_remaining=$(docker ps -a --filter label=devops.lab=lab4-dtc235180104 --format '{{.Names}}')
test -z "$lab_remaining" || { echo "Lab containers still exist" >&2; exit 1; }
lab_remaining=$(docker network ls --filter label=devops.lab=lab4-dtc235180104 --format '{{.Name}}')
test -z "$lab_remaining" || { echo "Lab network still exists" >&2; exit 1; }
rm -f "$HOME/.ssh/known_hosts_devops_lab4"
echo "Lab containers and network removed."
