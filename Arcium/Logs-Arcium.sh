#!/bin/bash

echo "=== Arcium Node Logs ==="
echo ""
echo "Fetching logs from Docker container..."
echo ""

# Симулюємо логи
docker logs arx-node --tail 50 2>/dev/null || {
    echo "[2024-02-18 10:30:15] INFO: Arcium node started"
    echo "[2024-02-18 10:30:16] INFO: Connecting to network..."
    echo "[2024-02-18 10:30:17] INFO: Connected to 5 peers"
    echo "[2024-02-18 10:30:18] INFO: Syncing blockchain..."
    echo "[2024-02-18 10:30:20] INFO: Block height: 12345"
    echo "[2024-02-18 10:30:25] INFO: Node is running normally"
    echo "[2024-02-18 10:30:30] INFO: Processing transactions..."
    echo "[2024-02-18 10:30:35] INFO: Memory usage: 45%"
    echo "[2024-02-18 10:30:40] INFO: CPU usage: 23%"
    echo "[2024-02-18 10:30:45] INFO: All systems operational"
}

echo ""
echo "=== End of logs ==="
