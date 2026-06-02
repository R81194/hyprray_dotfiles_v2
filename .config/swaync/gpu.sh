#!/bin/bash
# Cycles supergfxctl modes (Integrated <-> Hybrid)

CURRENT=$(supergfxctl -g)

if [ "$CURRENT" == "Integrated" ]; then
    supergfxctl -m Hybrid
    notify-send -t 3000 "GPU Mode" "Switched to Hybrid (NVIDIA ON)"
else
    supergfxctl -m Integrated
    notify-send -t 3000 "GPU Mode" "Switched to Integrated (NVIDIA OFF)"
fi