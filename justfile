registry := "ghcr.io"
username := "brosner"
platform := "linux/arm64"

# Build and push the overlay image
build push="true":
    #!/usr/bin/env bash
    set -euo pipefail
    token=$(echo "https://{{registry}}" | docker-credential-osxkeychain get | python3 -c "import json,sys; print(json.load(sys.stdin)['Secret'])")
    config_dir=$(mktemp -d)
    trap "rm -rf $config_dir" EXIT
    # Write inline credentials without credsStore so BuildKit container can read them.
    # Use docker --config and --builder flags directly (avoids DOCKER_CONFIG env var which
    # breaks plugin and builder state discovery).
    echo "{\"auths\":{\"{{registry}}\":{\"auth\":\"$(echo -n "{{username}}:$token" | base64)\"}}}" > "$config_dir/config.json"
    gmake sbc-raspberrypi PUSH={{push}} PLATFORM={{platform}} \
        BUILD="docker --config $config_dir buildx --builder talos-builder build"
