#!/bin/bash

echo "=== Arcium Node Status ==="
echo ""
echo "Checking node status..."
echo ""

# Перевіряємо чи запущений Docker контейнер
if docker ps | grep -q arx-node; then
    echo "✓ Node Status: RUNNING"
    echo ""
    echo "Container Info:"
    docker ps --filter "name=arx-node" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    echo ""
    echo "Resource Usage:"
    docker stats arx-node --no-stream --format "  CPU: {{.CPUPerc}}\n  Memory: {{.MemUsage}}\n  Network: {{.NetIO}}"
else
    echo "✗ Node Status: NOT RUNNING"
    echo ""
    echo "The Arcium node container is not running."
    echo "Use 'install' command to set up the node."
fi

echo ""
echo "=== End of status check ==="
