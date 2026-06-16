#!/bin/bash
# Ralph-agy Container Entrypoint
# Container stays alive – use "docker exec" to run ralph manually

echo "================================================"
echo " Ralph + Google Antigravity CLI (agy) Container"
echo "================================================"
echo ""

# Verify agy is available
if command -v agy &>/dev/null; then
    echo "✓ agy CLI found: $(command -v agy)"
else
    echo "✗ WARNING: agy not found in PATH"
    echo "  PATH: $PATH"
fi

# Check for agy auth / config
if [ -f /root/.config/agy/settings.json ]; then
    echo "✓ agy settings found"
else
    echo "⚠ No agy settings.json detected at /root/.config/agy/settings.json"
    echo "  Mount your config: -v \$(pwd)/agy-config:/root/.config/agy"
fi

# Check for workspace/project
if [ -d /workspace/project ]; then
    echo "✓ Project mounted at /workspace/project"
else
    echo "⚠ No project mounted. Mount your repo: -v \$(pwd)/project:/workspace/project"
fi

echo ""
echo "To run Ralph:"
echo "  docker exec -it ralph-agy bash"
echo "  cd /workspace/project"
echo "  ralph.sh --tool agy 10"
echo ""
echo "Container is ready. Keeping alive..."

# Keep container running
exec tail -f /dev/null
