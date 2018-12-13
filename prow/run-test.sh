#!/bin/bash

# Exit immediately for non zero status
set -e
# Print commands
set -x

source ./prow/test_setup.sh

exec "$1"

