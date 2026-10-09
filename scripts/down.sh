#!/usr/bin/env bash
set -euo pipefail
kind delete cluster --name meshery-a || true
kind delete cluster --name meshery-b || true
rm -rf "$(dirname "$0")/../out"
