#!/bin/sh

fetch_version() {
    # Fetch the latest version number from the Factorio API if using "stable" or "experimental"
    if [ "$FACTORIO_VERSION" = "stable" ] || [ "$FACTORIO_VERSION" = "experimental" ]; then
        echo "Fetching the latest '$FACTORIO_VERSION' headless version..."
        resolved_version=$(curl -s https://factorio.com/api/latest-releases | jq -r ".${FACTORIO_VERSION}.headless")
        if [ -n "$resolved_version" ]; then
            echo "Latest '$FACTORIO_VERSION' headless version is $resolved_version."
            FACTORIO_VERSION="$resolved_version" # Update the FACTORIO_VERSION to the resolved version
        else
            echo "Failed to fetch the latest version. Exiting..."
            exit 1
        fi
    fi
}

init_config() {
    jq_cmd='.'

    if [ -n "$RCON_PASS" ]; then
        jq_cmd="${jq_cmd} | .rcon_pass = \"$RCON_PASS\""
        echo "Factorio RCON password is '$RCON_PASS'"
    fi

    jq_cmd="${jq_cmd} | .sq_lite_database_file = \"/opt/fsm-data/sqlite.db\""
    jq_cmd="${jq_cmd} | .log_file = \"/opt/fsm-data/factorio-server-manager.log\""

    jq "${jq_cmd}" /root/fsm/conf.json >/opt/fsm-data/conf.json
}

install_game() {
    echo "Downloading Factorio version ${FACTORIO_VERSION}..."
    curl --max-time 600 --location "https://www.factorio.com/get-download/${FACTORIO_VERSION}/headless/linux64" \
        --output /tmp/factorio_${FACTORIO_VERSION}.tar.xz

    echo "Installing Factorio binaries to /opt/factorio..."
    tar -xf /tmp/factorio_${FACTORIO_VERSION}.tar.xz -C /opt
    rm /tmp/factorio_${FACTORIO_VERSION}.tar.xz
}

check_installed_version() {
    if [ -f /opt/factorio/bin/x64/factorio ]; then
        # Extract only the first line and parse the version number
        installed_version=$(/opt/factorio/bin/x64/factorio --version | head -n 1 | awk '{print $2}')
        echo "Installed Factorio version is $installed_version."

        # Compare the installed version with the required version
        if [ "$installed_version" != "$FACTORIO_VERSION" ]; then
            echo "Installed Factorio version ($installed_version) does not match required version ($FACTORIO_VERSION). Updating binaries..."
            return 1 # Signal that an update is needed
        else
            echo "Correct Factorio version ($installed_version) is already installed."
            return 0 # No update needed
        fi
    else
        echo "Factorio is not installed."
        return 1 # Signal that installation is needed
    fi
}

# Create the required directories
mkdir -p /opt/fsm-data /opt/factorio /opt/factorio/saves /opt/factorio/mods /opt/factorio/config

# Fetch and resolve the required version
fetch_version

# Initialize configuration if missing
if [ ! -f /opt/fsm-data/conf.json ]; then
    init_config
fi

# Check the installed version and update binaries if necessary
if ! check_installed_version; then
    install_game
fi

# Start FSM
cd /root/fsm
./factorio-server-manager --conf /opt/fsm-data/conf.json --dir /opt/factorio --port 80
