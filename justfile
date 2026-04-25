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
    # Write inline credentials (no credsStore) so the BuildKit container can read them.
    # Symlink cli-plugins/buildx/contexts so the temp config dir has full docker state.
    # Pass DOCKER_CONFIG + explicit --builder to avoid falling back to the default docker driver.
    mkdir -p "$config_dir/cli-plugins"
    ln -sf ~/.docker/cli-plugins/docker-buildx "$config_dir/cli-plugins/docker-buildx"
    ln -sf ~/.docker/buildx "$config_dir/buildx"
    ln -sf ~/.docker/contexts "$config_dir/contexts"
    echo "{\"auths\":{\"{{registry}}\":{\"auth\":\"$(echo -n "{{username}}:$token" | base64)\"}}}" > "$config_dir/config.json"
    DOCKER_CONFIG="$config_dir" gmake sbc-raspberrypi PUSH={{push}} PLATFORM={{platform}} \
        BUILD="docker buildx build --builder talos-builder"
