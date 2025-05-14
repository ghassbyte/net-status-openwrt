#!/bin/bash
# v1.0 - HTTP-based network check with fallback and retry logic

# Configuration
path=/root/net-status-openwrt
source "$path/config.conf"  # Load TG_CHAT_ID and TG_TOKEN
STAMP_FILE=${path}/stamp

# Primary and fallback URLs
PRIMARY_URL="http://ping.xmbb.net/"
FALLBACK_URL="https://support.zoom.us/"

# Function to reset modem
ngereset() {
  result=ERROR
  until [[ "$result" == *"OK"* ]]; do
    reset=$(echo AT+RESET | atinout - /dev/ttyUSB2 -)
    if grep -q "$reset" <<< "*OK"; then
      result=OK
    elif grep -q "$reset" <<< "*ERROR"; then
      result=ERROR
    fi
  done
}

# Function to send Telegram message
send_telegram_message() {
  curl -s --data "text=$1" \
       --data "parse_mode=markdown" \
       --data "chat_id=$TG_CHAT_ID" \
       "https://api.telegram.org/bot$TG_TOKEN/sendMessage"
}

# Function to test a URL with retry logic
check_url() {
  local URL=$1
  local SUCCESS_COUNT=0
  local ATTEMPTS=3

  for i in $(seq 1 $ATTEMPTS); do
    status_code=$(curl -s -o /dev/null -w "%{http_code}" -L "$URL")
    if [[ "$status_code" == "200" || "$status_code" == "204" ]]; then
      SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
    fi
    sleep 1
  done

  echo $SUCCESS_COUNT
}

# Try primary URL
SUCCESS_COUNT=$(check_url "$PRIMARY_URL")

# If not enough successes, try fallback
if [ "$SUCCESS_COUNT" -lt 2 ]; then
  SUCCESS_COUNT=$(check_url "$FALLBACK_URL")
fi

# Determine connection status
if [ "$SUCCESS_COUNT" -ge 2 ]; then
  status=connected
  if [ -f "$STAMP_FILE" ]; then
    rm -f "$STAMP_FILE"
    # /usr/bin/jam.sh time.bmkg.go.id # enable this if using vmess, for time sync
    sleep 15
    send_telegram_message "✅ Internet connection restored!"
  fi
else
  status=disconnected
  if [ ! -f "$STAMP_FILE" ]; then
    touch ${path}/stamp
    echo $(date +%s) > "$STAMP_FILE"
  fi
fi

# Recovery actions based on disconnect duration
if [ -f "$STAMP_FILE" ]; then
  current_time=$(date +%s)
  stamp_time=$(cat "$STAMP_FILE")
  elapsed_time=$((current_time - stamp_time))

  if [ $elapsed_time -ge 60 ] && [ $elapsed_time -lt 120 ]; then
    ifdown wan1
    ngereset

  elif [ $elapsed_time -ge 300 ] && [ $elapsed_time -lt 360 ]; then
    ifdown wan1
    ngereset

  elif [ $elapsed_time -ge 540 ]; then
    rm -f "$STAMP_FILE"
    reboot
  fi
fi

echo $status
