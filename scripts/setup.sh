#!/bin/bash
set -euo pipefail
docker info >/dev/null

lab_image=phamthuongdocker/ubuntu-sshd:22.04
for lab_container in web-server-1 web-server-2 db-server-1; do
  if docker container inspect "$lab_container" >/dev/null 2>&1; then
    echo "Container name already exists: $lab_container" >&2
    exit 1
  fi
done
if docker network inspect ansible-lab >/dev/null 2>&1; then
  echo "Network name already exists: ansible-lab" >&2
  exit 1
fi

docker network create --label devops.lab=lab4-dtc235180104 ansible-lab
docker run -d --platform linux/amd64 --name web-server-1 --label devops.lab=lab4-dtc235180104 --network ansible-lab -p 127.0.0.1:2201:22 -p 127.0.0.1:8081:80 "$lab_image"
docker run -d --platform linux/amd64 --name web-server-2 --label devops.lab=lab4-dtc235180104 --network ansible-lab -p 127.0.0.1:2202:22 -p 127.0.0.1:8082:80 "$lab_image"
docker run -d --platform linux/amd64 --name db-server-1 --label devops.lab=lab4-dtc235180104 --network ansible-lab -p 127.0.0.1:2203:22 "$lab_image"
docker ps --filter label=devops.lab=lab4-dtc235180104
