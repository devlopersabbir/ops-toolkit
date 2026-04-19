#!/usr/bin/env bash

# ==============================================================================
# Simple HTTP Server using netcat
# Author: Sabbir
# ==============================================================================

PORT=8080

# Detect OS (DevOps best practice)
if [[ "$OSTYPE" == "darwin"* ]]; then
  NC_CMD="nc -l $PORT"
else
  NC_CMD="nc -l -p $PORT -q 1"
fi

echo "🚀 Bash HTTP Server running on $PORT"

while true; do
  {
    read request_line
    echo "📥 $request_line"

    while read header && [ "$header" != $'\r' ]; do
      :
    done

    echo -e "HTTP/1.1 200 OK\r"
    echo -e "Content-Type: text/plain\r"
    echo -e "\r"
    echo "Hello from portable Bash server 🚀"
  } | eval $NC_CMD
done
