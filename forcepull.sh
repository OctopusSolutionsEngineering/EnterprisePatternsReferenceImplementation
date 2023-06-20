#!/bin/bash

echo "Perform a hard reset to the upstream main branch"
git fetch --all
git reset --hard origin/main
