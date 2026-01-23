# 🚀 BitNet AI Server on Proxmox (LXC)

![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Platform](https://img.shields.io/badge/platform-Proxmox%20LXC-orange)
![Model](https://img.shields.io/badge/model-Llama%203.2%20%2F%20BitNet%201.58--bit-green)

A complete guide and configuration set to run efficient, local AI models (like BitNet 1.58-bit or Llama 3.2 3B) on standard hardware using Proxmox LXC containers.

## 📋 Prerequisites

- **Proxmox VE** (7.x or 8.x)
- **CPU:** x86_64 with AVX2 support (Recommended)
- **RAM:** Minimum 4GB allocated to the container
- **Disk:** ~20GB storage

## 🛠️ Installation

### 1. Create the Container
Create an LXC container in Proxmox with the following specs:
- **Template:** Ubuntu 24.04 or Debian 12
- **Cores:** 4+
- **Memory:** 4096 MB
- **Swap:** 1024 MB

## ⚡ Quick Install (One-Liner)

If you have a fresh LXC container (Ubuntu/Debian), you can install everything with a single command:

```bash
curl -sL https://raw.githubusercontent.com/yenksid/proxmox-local-ai/main/scripts/install.sh | bash
```

### 2. 🛠️ Manual Installation
If you prefer to do it step-by-step run the following commands inside your LXC console:

```bash
# Update system
apt update && apt upgrade -y
apt install -y git build-essential cmake curl wget

# Clone & Build llama.cpp (Official Engine)
cd ~
git clone https://github.com/ggerganov/llama.cpp
cd llama.cpp
cmake -B build
cmake --build build --config Release -j4 --target llama-server
```

### 3. Download Model
We recommend the quantized Llama 3.2 3B for best performance/quality ratio on low resources.

```bash
mkdir -p /root/models
wget https://huggingface.co/bartowski/Llama-3.2-3B-Instruct-GGUF/resolve/main/Llama-3.2-3B-Instruct-Q4_K_M.gguf -O /root/models/llama-3.2-3b-q4.gguf
```

### 4. Configuration
Copy the provided scripts from this repository to your server:

1. Copy `scripts/start_ai.sh` to `/root/start_ai.sh` and `chmod +x` it.
2. Copy `config/bitnet.service` to `/etc/systemd/system/bitnet.service`.

### 5. Enable Service
```bash
systemctl daemon-reload
systemctl enable bitnet.service
systemctl start bitnet.service
```

## 🔌 API Usage
The server exposes an OpenAI-compatible API at `http://<YOUR_IP>:8080/v1`.

Example Request (curl):

```bash
curl http://<YOUR_IP>:8080/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "llama-3.2-3b-q4.gguf",
    "messages": [
      { "role": "system", "content": "You are a helpful assistant." },
      { "role": "user", "content": "Hello!" }
    ]
  }'
```

## 🤝 Contributing
Feel free to submit issues or pull requests to improve the setup scripts.

## 📄 License
MIT License
