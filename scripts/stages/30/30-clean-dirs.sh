#!/bin/sh

(
  cd "$ROOTFS_PATH" || exit 1
  rm -rf tmp/*
)
