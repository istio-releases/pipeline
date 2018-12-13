#!/bin/bash

# Exit immediately for non zero status
set -e
# Print commands
set -x

./test_setup.sh

exec "$1"

