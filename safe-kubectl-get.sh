#!/bin/bash

# Wrapper for kubectl get commands
# Routes to safe-kubectl.sh with proper arguments

# Pass all arguments to safe-kubectl.sh
./safe-kubectl.sh get "$@"
