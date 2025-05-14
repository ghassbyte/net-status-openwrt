# OpenWRT Internet Connection Watchdog for HG680-P + LT4220 Modem

This project provides a Bash script to automatically **monitor internet connectivity** and **recover from network failures** on an OpenWRT system, specifically designed for:

- **Device**: HG680P
- **Modem**: LT4220 (USB modem, AT command capable)
- **Firmware**: [OpenWrt 21.02.1 SR-14 HG680P Kernel 6.1.15-reyre](https://www.youtube.com/watch?v=MaYQSRVp87A&ab_channel=REYRE-WRT)


## 🔧 How It Works

- Periodically (via cron every minute), the script pings a reliable web endpoint using `curl`.
- If the connection **fails multiple times in a row**, it:
  - Triggers a **modem reset** using AT commands (`AT+RESET`)
  - If connection restored, sends an alert via **Telegram**
  - If connection is not recovered in time, it will **reboot the device**

The script uses a **fallback URL** (`support.zoom.us`) if the primary one (`ping.xmbb.net`) fails.

---

## 📂 File Structure
```
net-status-openwrt/
├── net-detect.sh       # Main watchdog script
├── config.example.conf # Example Telegram config (no secrets)
└── stamp               # Auto-generated timestamp file (used internally)
```

---

## 📦 Installation & Setup

1. Upload the files to your router, preferably under:
```
/root/net-status-openwrt/
```

2. Set executable permissions:
```bash
chmod 0755 /root/net-status-openwrt/net-detect.sh
```

3. Copy and edit the config file:
```bash
cd /root/net-status-openwrt
mv config.example.conf config.conf
nano config.conf # Add your actual Telegram CHAT ID and TOKEN.
```

4. Edit your crontab to run the script every minute:
```bash
crontab -e

# Add the line:
* * * * * /root/net-status-openwrt/net-detect.sh
```

---

## 🛜 Requirements
Your OpenWRT build should include:
- bash
- curl
- atinout (to send AT commands to the modem)

To install:
```bash
opkg update
opkg install bash curl atinout
```

---

## 🔐 Security
Do not commit config.conf to GitHub. It contains sensitive tokens.  
The .gitignore file should contain:
```
config.conf
stamp
```

---

## 🧪 Test It
To manually run and test the script:
```bash
bash /root/net-status-openwrt/net-detect.sh
```
Watch the Telegram message or the modem reset to verify behavior.

---

## 📬 Telegram Bot Setup
- Create a new bot via BotFather
- Get your TG_TOKEN
- Find your Telegram user or group TG_CHAT_ID using tools like IDBot

---

## 👨‍🔧 Customization
You can adjust retry logic and URLs inside the script.  
The modem reset logic can be adapted if your modem responds to different AT commands.

---

## 🛠️ Troubleshooting
If modem doesn’t reset, try verifying AT command support:
```bash
echo "AT+RESET" | atinout - /dev/ttyUSB2 -
```

If Telegram messages don’t send, test your token manually:
```bash
curl -s -X POST https://api.telegram.org/bot<your_token>/sendMessage \
     -d chat_id=<your_chat_id> \
     -d text="Hello from OpenWRT"
```

---

## 🧾 License
MIT License — Free to use and modify.

---

## 💬 Credits
Maintained by ghassbyte  
Inspired by real-world OpenWRT needs for remote connectivity management on LTE routers.