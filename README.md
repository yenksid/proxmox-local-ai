# 🚀 BitNet AI Server on Proxmox (LXC)

![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Platform](https://img.shields.io/badge/platform-Proxmox%20LXC-orange)
![Model](https://img.shields.io/badge/model-Llama%203.2%20%2F%20BitNet%201.58--bit-green)

A complete guide and configuration set to run efficient, local AI models (like **BitNet 1.58-bit** or **Llama 3.2 3B**) on standard hardware using Proxmox LXC containers.

---

## ✨ Features
- ⚡ **High Performance**: Optimized for CPU-only inference using `llama.cpp`.
- 🌐 **Web UI Included**: Built-in minimalist chat interface.
- � **OpenAI Compatible**: Fully compatible with OpenAI API clients.
- 📦 **LXC Optimized**: Designed specifically for Proxmox containers.
- 🔋 **Systemd Integration**: Automatic startup and crash recovery.

---

## �📖 Table of Contents
- [📋 Prerequisites](#-prerequisites)
- [🛠️ Installation](#-installation)
  - [⚡ Quick Install (One-Liner)](#-quick-install-one-liner)
  - [🛠️ Manual Installation](#️-manual-installation)
- [📥 Download Model](#-download-model)
- [⚙️ Configuration](#️-configuration)
- [🔋 Enable Service](#-enable-service)
- [🔌 API Usage](#-api-usage)
- [🤝 Contributing](#-contributing)
- [📄 License](#-license)

---

## 📋 Prerequisites

> [!IMPORTANT]
> Ensure your Proxmox node supports **AVX2** for optimal performance.

| Resource | Minimum Requirement | Recommended |
| :--- | :--- | :--- |
| **CPU** | 2-4 Cores (x86_64) | 4+ Cores (AVX2 support) |
| **RAM** | 4 GB | 8 GB+ |
| **Disk** | 20 GB | 40 GB (NVMe preferred) |
| **OS** | Ubuntu 24.04 / Debian 12 | Ubuntu 24.04 |

---

## 🛠️ Installation

### 1. Create the Container
Create an LXC container in Proxmox with these specifications:
- **Template:** Ubuntu 24.04 or Debian 12
- **Cores:** 4+
- **Memory:** 4096 MB
- **Swap:** 1024 MB
- **Unprivileged:** Yes

### ⚡ Quick Install (One-Liner)

> [!TIP]
> This is the recommended way for a fresh installation.

```bash
curl -sL https://raw.githubusercontent.com/yenksid/proxmox-local-ai/main/scripts/install.sh | bash
```

### 2. 🛠️ Manual Installation
If you prefer manual control, run these commands inside your LXC console:

```bash
# Update system & dependencies
apt update && apt upgrade -y
apt install -y git build-essential cmake curl wget

# Clone & Build llama.cpp (Official Engine)
cd ~
git clone https://github.com/ggerganov/llama.cpp
cd llama.cpp
cmake -B build
cmake --build build --config Release -j$(nproc) --target llama-server

# Setup Web UI
mkdir -p /root/public
wget https://raw.githubusercontent.com/yenksid/proxmox-local-ai/main/public/index.html -O /root/public/index.html
```

---

## 📥 Download Model
We recommend the quantized **Llama 3.2 3B** for the best performance/quality ratio on low resources.

```bash
mkdir -p /root/models
wget https://huggingface.co/bartowski/Llama-3.2-3B-Instruct-GGUF/resolve/main/Llama-3.2-3B-Instruct-Q4_K_M.gguf -O /root/models/llama-3.2-3b-q4.gguf
```

---

## ⚙️ Configuration
Copy the provided scripts from this repository to your server:

1.  **Startup Script**: Copy `scripts/start_ai.sh` to `/root/start_ai.sh` and make it executable (`chmod +x`).
2.  **Systemd Service**: Copy `config/bitnet.service` to `/etc/systemd/system/bitnet.service`.

---

## 🔋 Enable Service
Run the following commands to enable and start the AI server:

```bash
systemctl daemon-reload
systemctl enable bitnet.service
systemctl start bitnet.service
```

---

## 🌐 Web UI & API Usage

### 🎨 Web Interface
Once the service is running, you can access the built-in chat interface at:
`http://<YOUR_IP>:8080`

### 🔌 API Endpoint
The server also exposes an OpenAI-compatible API at:
`http://<YOUR_IP>:8080/v1`

#### Example Request (curl):

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

---

## 🤝 Contributing
Contributions are welcome! Feel free to submit issues or pull requests to improve the setup scripts or UI.

---

## 📄 License
This project is licensed under the **MIT License** - see the [LICENSE](LICENSE) file for details.

---
Built with ❤️ for the Proxmox Community.
