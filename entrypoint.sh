#!/bin/sh

mkdir -p /opt/fsm-data /opt/factorio /opt/factorio/saves /opt/factorio/mods /opt/factorio/config

init_config() {
    jq_cmd='.'

    if [ -n "$RCON_PASS" ]; then
        jq_cmd="${jq_cmd} | .rcon_pass = \"$RCON_PASS\""
        echo "Factorio rcon password is '$RCON_PASS'"
    fi

    jq_cmd="${jq_cmd} | .sq_lite_database_file = \"/opt/fsm-data/sqlite.db\""
    jq_cmd="${jq_cmd} | .log_file = \"/opt/fsm-data/factorio-server-manager.log\""

    jq "${jq_cmd}" /root/fsm/conf.json >/opt/fsm-data/conf.json
}

random_pass() {
    LC_ALL=C tr -dc 'a-zA-Z0-9' </dev/urandom | fold -w 24 | head -n 1
}

install_game() {
    echo "Downloading Factorio version ${FACTORIO_VERSION}..."
    curl --max-time 600 --location "https://www.factorio.com/get-download/${FACTORIO_VERSION}/headless/linux64" \
        --output /tmp/factorio_${FACTORIO_VERSION}.tar.xz

    echo "Installing Factorio to /opt/factorio..."
    tar -xf /tmp/factorio_${FACTORIO_VERSION}.tar.xz -C /opt
    rm /tmp/factorio_${FACTORIO_VERSION}.tar.xz
}

is_correct_version_installed() {
    # Check if Factorio is installed and verify the version
    if [ -f /opt/factorio/bin/x64/factorio ]; then
        # Extract the version from the installed Factorio binary
        installed_version=$(/opt/factorio/bin/x64/factorio --version | grep -oP '^Version:\s+\K.*')

        if [ "$installed_version" = "$FACTORIO_VERSION" ]; then
            echo "Correct Factorio version ($installed_version) is already installed."
            return 0
        else
            echo "Installed Factorio version ($installed_version) does not match required version ($FACTORIO_VERSION)."
            return 1
        fi
    else
        echo "Factorio is not installed."
        return 1
    fi
}

if [ ! -f /opt/fsm-data/conf.json ]; then
    init_config
fi

# Install Factorio if the correct version is not installed
if ! is_correct_version_installed; then
    install_game
fi

cd /root/fsm && ./factorio-server-manager --conf /opt/fsm-data/conf.json --dir /opt/factorio --port 80
