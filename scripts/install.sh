#!/bin/bash

# ==============================================================================
# AUTOMATED INSTALLER: Local AI Server on Proxmox LXC
# Installs llama.cpp engine + Llama 3.2 3B Model + Custom UI + Systemd Service
# Version: 1.2.1 (Custom UI + Safety Checks + IP Fix)
# ==============================================================================

# Exit on any error
set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${BLUE}>>> Starting Installation of Local AI Server...${NC}"

# 1. Check Root
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}Please run as root (or use sudo).${NC}"
  exit 1
fi

# 1.1 Safety Check: Warn if running on Proxmox Host
if [ -f "/etc/pve/storage.cfg" ] || [ -f "/etc/pve/local/pve-ssl.key" ]; then
    echo -e "${RED}==============================================================${NC}"
    echo -e "${RED}⚠️  WARNING: PROXMOX HOST DETECTED ⚠️${NC}"
    echo -e "${RED}==============================================================${NC}"
    echo -e "${YELLOW}It looks like you are running this script directly on your Proxmox Node.${NC}"
    echo -e "${YELLOW}This is NOT recommended. You should run this inside an LXC Container${NC}"
    echo -e "${YELLOW}to keep your hypervisor clean and secure.${NC}"
    echo -e ""
    echo -e "If you really want to install it on the host, press ENTER."
    echo -e "Otherwise, press Ctrl+C to abort and create an LXC."
    read -p ""
fi

# 1.2 Personalization
echo -e "${CYAN}--------------------------------------------------------------${NC}"
echo -e "${CYAN} PERSONALIZATION ${NC}"
echo -e "${CYAN}--------------------------------------------------------------${NC}"
read -p "How should the AI address you? (Default: Architect): " USER_TITLE
USER_TITLE=${USER_TITLE:-Architect} # Default to Architect if empty
echo -e "${GREEN}>>> Understood. The system will address you as '${USER_TITLE}'.${NC}"

# 2. System Update & Dependencies
echo -e "${GREEN}>>> Updating system and installing dependencies...${NC}"
apt-get update -qq
apt-get install -y -qq git build-essential cmake curl wget libssl-dev pkg-config

# 3. Clone & Build Engine (llama.cpp)
INSTALL_DIR="/root/llama.cpp"
if [ -d "$INSTALL_DIR" ]; then
    echo -e "${BLUE}>>> llama.cpp directory exists. Pulling latest changes...${NC}"
    cd "$INSTALL_DIR"
    git pull
else
    echo -e "${GREEN}>>> Cloning llama.cpp repository...${NC}"
    git clone https://github.com/ggerganov/llama.cpp "$INSTALL_DIR"
    cd "$INSTALL_DIR"
fi

echo -e "${GREEN}>>> Compiling llama-server (This may take a few minutes)...${NC}"
rm -rf build
cmake -B build
CORES=$(nproc)
cmake --build build --config Release -j"$CORES" --target llama-server

# 4. Download Model (Llama 3.2 3B Q4)
MODEL_DIR="/root/models"
MODEL_URL="https://huggingface.co/bartowski/Llama-3.2-3B-Instruct-GGUF/resolve/main/Llama-3.2-3B-Instruct-Q4_K_M.gguf"
MODEL_PATH="$MODEL_DIR/llama-3.2-3b-q4.gguf"

mkdir -p "$MODEL_DIR"

if [ -f "$MODEL_PATH" ]; then
    echo -e "${BLUE}>>> Model already exists. Skipping download.${NC}"
else
    echo -e "${GREEN}>>> Downloading Llama 3.2 3B model...${NC}"
    wget "$MODEL_URL" -O "$MODEL_PATH"
fi

# 5. Generate UI (Injecting User Title)
PUBLIC_DIR="/root/public"
mkdir -p "$PUBLIC_DIR"
echo -e "${GREEN}>>> Generating Custom UI...${NC}"

cat <<EOF > "$PUBLIC_DIR/index.html"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Resilient AI Node</title>
    <script src="https://cdn.jsdelivr.net/npm/marked/marked.min.js"></script>
    <style>
        :root { --bg-color: #0d1117; --chat-bg: #161b22; --user-msg: #238636; --ai-msg: #1f6feb; --text-color: #c9d1d9; --font-mono: 'Courier New', Courier, monospace; }
        body { background-color: var(--bg-color); color: var(--text-color); font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Helvetica, Arial, sans-serif; margin: 0; display: flex; flex-direction: column; height: 100vh; }
        header { background-color: var(--chat-bg); padding: 1rem; border-bottom: 1px solid #30363d; text-align: center; font-family: var(--font-mono); font-weight: bold; color: #58a6ff; }
        #chat-container { flex: 1; overflow-y: auto; padding: 20px; display: flex; flex-direction: column; gap: 15px; }
        .message { max-width: 80%; padding: 10px 15px; border-radius: 8px; line-height: 1.5; word-wrap: break-word; }
        .user { align-self: flex-end; background-color: var(--user-msg); color: white; }
        .ai { align-self: flex-start; background-color: var(--chat-bg); border: 1px solid #30363d; }
        .json-badge { font-size: 0.7em; background: #d29922; color: black; padding: 2px 6px; border-radius: 4px; font-weight: bold; display: inline-block; margin-bottom: 5px; }
        #input-area { background-color: var(--chat-bg); padding: 20px; border-top: 1px solid #30363d; display: flex; gap: 10px; }
        input[type="text"] { flex: 1; background-color: #0d1117; border: 1px solid #30363d; color: white; padding: 12px; border-radius: 6px; font-family: var(--font-mono); }
        button { background-color: #238636; color: white; border: none; padding: 0 20px; border-radius: 6px; cursor: pointer; font-weight: bold; }
        button:hover { background-color: #2ea043; }
        button:disabled { background-color: #30363d; cursor: wait; }
        pre { background: #000; padding: 10px; border-radius: 5px; overflow-x: auto; }
        code { font-family: var(--font-mono); }
    </style>
</head>
<body>
<header>⚡ RESILIENT NODE | Llama 3.2 3B</header>
<div id="chat-container">
    <div class="message ai">System ready. Running in LXC. 4GB RAM Optimization active.<br>How can I assist you, ${USER_TITLE}?</div>
</div>
<div id="input-area">
    <input type="text" id="user-input" placeholder="Type a command or query..." autocomplete="off">
    <button id="send-btn">SEND</button>
</div>
<script>
    const chatContainer = document.getElementById('chat-container');
    const inputField = document.getElementById('user-input');
    const sendBtn = document.getElementById('send-btn');

    function parseAIResponse(text) {
        text = text.trim();
        if (text.startsWith('{') && text.endsWith('}')) {
            try {
                const data = JSON.parse(text);
                if (data.parameters) {
                    let cleanContent = data.parameters.content || JSON.stringify(data.parameters, null, 2);
                    return \`<span class="json-badge">TOOL OUTPUT</span><br>\` + marked.parse(cleanContent);
                }
                return \`<span class="json-badge">JSON DATA</span><pre>\${JSON.stringify(data, null, 2)}</pre>\`;
            } catch (e) { return marked.parse(text); }
        }
        return marked.parse(text);
    }

    async function sendMessage() {
        const text = inputField.value.trim();
        if (!text) return;
        addMessage(text, 'user');
        inputField.value = ''; inputField.disabled = true; sendBtn.disabled = true;
        const loadingId = addMessage("Thinking...", 'ai', true);
        try {
            const response = await fetch('/completion', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    prompt: \`<|begin_of_text|><|start_header_id|>system<|end_header_id|>\n\nYou are a helpful AI assistant running on a local Proxmox server. Address the user as '${USER_TITLE}'. Keep answers concise.<|eot_id|><|start_header_id|>user<|end_header_id|>\n\n\${text}<|eot_id|><|start_header_id|>assistant<|end_header_id|>\n\n\`,
                    n_predict: 512, temperature: 0.7, stop: ["<|eot_id|>"]
                })
            });
            const data = await response.json();
            document.getElementById(loadingId).remove();
            const aiText = parseAIResponse(data.content);
            addMessage(aiText, 'ai', false, true);
        } catch (error) {
            document.getElementById(loadingId).remove();
            addMessage("Error connecting to Local AI: " + error.message, 'ai');
        }
        inputField.disabled = false; sendBtn.disabled = false; inputField.focus();
    }
    function addMessage(text, sender, isTemp = false, isHTML = false) {
        const div = document.createElement('div'); div.className = \`message \${sender}\`;
        if (isTemp) div.id = 'msg-' + Date.now();
        if (isHTML) div.innerHTML = text; else div.textContent = text;
        chatContainer.appendChild(div); chatContainer.scrollTop = chatContainer.scrollHeight;
        return div.id;
    }
    sendBtn.addEventListener('click', sendMessage);
    inputField.addEventListener('keypress', (e) => { if (e.key === 'Enter') sendMessage(); });
</script>
</body>
</html>
EOF

# 6. Create Startup Script
SCRIPT_PATH="/root/start_ai.sh"
echo -e "${GREEN}>>> Creating startup script at $SCRIPT_PATH...${NC}"

cat <<EOF > "$SCRIPT_PATH"
#!/bin/bash
# Auto-generated by install.sh
$INSTALL_DIR/build/bin/llama-server \\
    -m $MODEL_PATH \\
    --host 0.0.0.0 \\
    --port 8080 \\
    -c 4096 \\
    --temp 0.7 \\
    -t 4 \\
    --path $PUBLIC_DIR
EOF

chmod +x "$SCRIPT_PATH"

# 7. Create Systemd Service
SERVICE_PATH="/etc/systemd/system/local-ai.service"
echo -e "${GREEN}>>> Creating systemd service at $SERVICE_PATH...${NC}"

cat <<EOF > "$SERVICE_PATH"
[Unit]
Description=Local AI Server (Llama 3.2)
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/root
ExecStart=$SCRIPT_PATH
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

# 8. Enable & Start Service
echo -e "${GREEN}>>> Enabling and starting service...${NC}"
systemctl daemon-reload
systemctl enable local-ai.service
systemctl restart local-ai.service

# 9. Final Info
IP_ADDR=$(ip route get 1.1.1.1 2>/dev/null | grep -oP 'src \K\S+') || IP_ADDR=$(hostname -I | awk '{print $1}')

echo -e "${GREEN}======================================================${NC}"
echo -e "${GREEN} INSTALLATION COMPLETE! ${NC}"
echo -e "${GREEN}======================================================${NC}"
echo -e "Your AI Server is running at: ${BLUE}http://$IP_ADDR:8080${NC}"
echo -e "API Endpoint: ${BLUE}http://$IP_ADDR:8080/v1${NC}"
echo -e "System will address you as: ${CYAN}$USER_TITLE${NC}"