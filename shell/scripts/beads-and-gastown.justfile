# Build beads and gastown from source
# Usage: just all

set positional-arguments

oss_dir  := justfile_directory()
beads_repo := "https://github.com/steveyegge/beads.git"
gastown_repo := "https://github.com/steveyegge/gastown.git"

# Install system dependencies, pull latest, and rebuild everything
all: deps update build

# Install system build dependencies
deps:
    sudo apt-get install -y libicu-dev build-essential

# Clone repos if missing, pull latest on main
update: (_update "beads" beads_repo) (_update "gastown" gastown_repo)

_update name repo:
    #!/usr/bin/env bash
    set -euo pipefail
    dir="{{ oss_dir }}/{{ name }}"
    if [ ! -d "$dir/.git" ]; then
        echo "Cloning {{ name }}..."
        git clone "{{ repo }}" "$dir"
    else
        echo "Updating {{ name }}..."
        cd "$dir"
        git fetch origin
        git checkout main
        git pull --ff-only origin main
    fi

# Build and install both binaries
build: build-beads build-gastown

# Build and install beads (bd)
build-beads:
    cd {{ oss_dir }}/beads && make install

# Build and install gastown (gt)
build-gastown:
    cd {{ oss_dir }}/gastown && SKIP_UPDATE_CHECK=1 make install
