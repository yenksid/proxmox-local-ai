#!/bin/bash
# Adjust the path below if your installation directory differs
/root/llama.cpp/build/bin/llama-server \
    -m /root/models/llama-3.2-3b-q4.gguf \
    --host 0.0.0.0 \
    --port 8080 \
    -c 4096 \
    --temp 0.7 \
    -t 4 \
    --path /root/public
    