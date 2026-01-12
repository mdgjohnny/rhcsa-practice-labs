#!/usr/bin/env bash
# Task: Create a Containerfile in /root/myimage/ that builds from ubi8, installs httpd, exposes port 80, and sets CMD to run httpd in foreground. Build the image as "myhttpd:v1".
# Title: Build Container from Containerfile
# Category: containers
# Target: node1

check '[[ -f /root/myimage/Containerfile ]] || [[ -f /root/myimage/Dockerfile ]]' \
    "Containerfile exists in /root/myimage/" \
    "No Containerfile or Dockerfile in /root/myimage/"

check 'grep -qi "FROM.*ubi8" /root/myimage/Containerfile 2>/dev/null || grep -qi "FROM.*ubi8" /root/myimage/Dockerfile 2>/dev/null' \
    "Containerfile uses ubi8 base image" \
    "Containerfile doesn't use ubi8"

check 'grep -qiE "RUN.*(dnf|yum).*install.*httpd" /root/myimage/Containerfile 2>/dev/null || grep -qiE "RUN.*(dnf|yum).*install.*httpd" /root/myimage/Dockerfile 2>/dev/null' \
    "Containerfile installs httpd" \
    "Containerfile doesn't install httpd"

check 'grep -qi "EXPOSE.*80" /root/myimage/Containerfile 2>/dev/null || grep -qi "EXPOSE.*80" /root/myimage/Dockerfile 2>/dev/null' \
    "Containerfile exposes port 80" \
    "Port 80 not exposed in Containerfile"

check 'podman image exists localhost/myhttpd:v1 2>/dev/null || podman images | grep -q "myhttpd.*v1"' \
    "Image myhttpd:v1 has been built" \
    "Image myhttpd:v1 not found"
