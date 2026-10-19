#!/bin/bash
set -e

exec xcrun swift "$(dirname "$0")/seed.swift" "$@"
