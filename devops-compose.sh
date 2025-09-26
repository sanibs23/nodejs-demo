#!/bin/bash
# devops-compose.sh
# Usage: ./devops-compose.sh [up|down|restart]
# Controls Jenkins, GitLab, and SonarQube+PostgreSQL compose stacks

set -e

COMPOSE_FILES=(
  "docker-compose.jenkins.yml"
  "docker-compose.gitlab.yml"
  "docker-compose.sonarqube.yml"
)

case "$1" in
  up)
    for f in "${COMPOSE_FILES[@]}"; do
      echo "Bringing up $f..."
      docker-compose -f "$f" up -d
    done
    ;;
  down)
    for f in "${COMPOSE_FILES[@]}"; do
      echo "Bringing down $f..."
      docker-compose -f "$f" down
    done
    ;;
  restart)
    for f in "${COMPOSE_FILES[@]}"; do
      echo "Restarting $f..."
      docker-compose -f "$f" restart
    done
    ;;
  remove)
    for f in "${COMPOSE_FILES[@]}"; do
      echo "Removing containers and volumes for $f..."
      docker-compose -f "$f" down -v
    done
    ;;
  *)
    echo "Usage: $0 [up|down|restart|remove]"
    exit 1
    ;;
esac
