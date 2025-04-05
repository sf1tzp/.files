#!/usr/bin/env python3

# install.py - a 'simple' script to install shell utilities
# This script will attempt to install utilities using brew, cargo, or by downloading a release artifact.
# If brew or cargo is unavilable, this script will download release artifacts and move binaries to $INSTALL_DIR (~/.local/bin)
# Since most programs are packaged differently, "setup_script" scripts can be provided to finish up the installation
# eg moving `install/some/downloaded/file` to a common place on the $PATH
# setup_script is written to, and executed from, a temp_dir containing the downloaded files

# Config Format:
# "name": str (name of the command to look for)
#         "version": str (release version, used in urls and file)
#         "url_template": str (can referece name, version, arch variables)
#         "is_amd64": str (some projects choose "amd64" while others choose "x86_64")
#         "package_name": str (some projects' package names don't match the primary command, eg "ripgrep":"rg")
#         "setup_script": str (contents written to, and executed from, install_dir)
# }

import os
import subprocess
import shutil
import platform
import tempfile
from textwrap import dedent
from urllib.parse import urlparse

INSTALL_DIR = os.getenv("INSTALL_DIR", os.path.expanduser("~/.local/bin"))
ARCH = platform.machine() if platform.machine() in {"x86_64", "arm64"} else None

AUTOMATIC_INSTALL = os.getenv("AUTOMATIC")


# Programs listed here are crates and can be installed via brew, cargo, or download from github releases if necessary
# TODO: Add setup_script for these for when cargo is not available
CRATES = {
    "bat": {
        "version": "0.25.0",
        "url_template": "https://github.com/sharkdp/bat/releases/download/v{version}/bat-v{version}-{arch}-unknown-linux-musl.tar.gz",
        "setup_script": """#!/usr/bin/env bash
            mv bat-v{version}-{arch}-unknown-linux-musl/bat {install_dir}
            """,
    },
    "dust": {
        "version": "1.1.2",
        "url_template": "https://github.com/bootandy/dust/releases/download/v{version}/dust-v{version}-{arch}-unknown-linux-musl.tar.gz",
        "package_name": "du-dust",
        "setup_script": """#!/usr/bin/env bash
            mv dust-v{version}-{arch}-unknown-linux-musl/dust {install_dir}
            """,
    },
    "eza": {
        "version": "0.21.0",
        "url_template": "https://github.com/eza-community/eza/releases/download/v{version}/eza_{arch}-unknown-linux-musl.tar.gz",
        "setup_script": """#!/usr/bin/env bash
            mv eza {install_dir}
            """,
    },
    "fd": {
        "version": "10.2.0",
        "url_template": "https://github.com/sharkdp/fd/releases/download/v{version}/fd-v{version}-{arch}-unknown-linux-musl.tar.gz",
        "package_name": "fd-find",
        "setup_script": """#!/usr/bin/env bash
            mv fd-v10.2.0-{arch}-unknown-linux-musl/fd {install_dir}
            """,
    },
    "pipes-rs": {
        "version": "1.6.3",
        "url_template": "https://github.com/lhvy/pipes-rs/releases/download/v{version}/pipes-rs-linux-{arch}.tar.gz",
        "package_name": "--git https://github.com/lhvy/pipes-rs",
        "setup_script": """#!/usr/bin/env bash
            mv target/{arch}-unknown-linux-gnu/release/pipes-rs {install_dir}
            """,
    },
    "rg": {
        "version": "14.1.1",
        "url_template": "https://github.com/BurntSushi/ripgrep/releases/download/{version}/ripgrep-{version}-{arch}-unknown-linux-musl.tar.gz",
        "package_name": "ripgrep",
        "setup_script": """#!/usr/bin/env bash
            mv ripgrep-14.1.1-{arch}-unknown-linux-musl/rg {install_dir}
            """,
    },
    "starship": {
        "version": "1.22.1",
        "url_template": "https://github.com/starship/starship/releases/download/v{version}/starship-{arch}-unknown-linux-musl.tar.gz",
        "setup_script": """#!/usr/bin/env bash
            mv starship {install_dir}
            """,
    },
    "uv": {
        "version": "0.6.12",
        "url_template": "https://github.com/astral-sh/uv/releases/download/{version}/uv-{arch}-unknown-linux-musl.tar.gz",
        "package_name": "--git https://github.com/astral-sh/uv",
        "setup_script": """#!/usr/bin/env bash
            mv uv-{arch}-unknown-linux-musl/uv  {install_dir}
            mv uv-{arch}-unknown-linux-musl/uvx  {install_dir}
            """,
    },
    "zoxide": {
        "version": "0.9.7",
        "url_template": "https://github.com/ajeetdsouza/zoxide/releases/download/v{version}/zoxide-{version}-{arch}-unknown-linux-musl.tar.gz",
        "setup_script": """#!/usr/bin/env bash
            mv zoxide {install_dir}
            """,
    },
}

# Programs listed here are either on brew or need to be downloaded
PROGRAMS = {
    "duf": {
        "version": "0.8.1",
        "url_template": "https://github.com/muesli/duf/releases/download/v{version}/duf_{version}_linux_{arch}.tar.gz",
        "setup_script": """#!/usr/bin/env bash
            chmod +x duf
            mv duf {install_dir}
        """,
    },
    "fastfetch": {
        "version": "2.40.3",
        "url_template": "https://github.com/fastfetch-cli/fastfetch/releases/download/{version}/fastfetch-linux-{arch}.tar.gz",
        "is_amd64": True,
        "setup_script": """#!/usr/bin/env bash
            chmod +x fastfetch-linux-{arch}/usr/bin/fastfetch
            mv fastfetch-linux-{arch}/usr/bin/fastfetch fastfetch
            mv fastfetch {install_dir}
            """,
    },
    "jq": {
        "version": "1.7.1",
        "url_template": "https://github.com/jqlang/jq/releases/download/jq-{version}/jq-linux-{arch}",
        "is_amd64": True,
        "setup_script": """#!/usr/bin/env bash
            chmod +x jq-linux-{arch}
            mv jq-linux-{arch} jq
            mv jq {install_dir}
            """,
    },
    "nerdctl": {
        "version": "2.0.3",
        "url_template": "https://github.com/containerd/nerdctl/releases/download/v{version}/nerdctl-full-{version}-linux-{arch}.tar.gz",
        "is_amd64": True,
        "setup_script": """#!/usr/bin/env bash
            tar -xzvf nerdctl-full-{version}-linux-{arch}.tar.gz -C ~/.local
            """,
    },
    "yq": {
        "version": "4.45.1",
        "url_template": "https://github.com/mikefarah/yq/releases/download/v{version}/yq_linux_{arch}.tar.gz",
        "is_amd64": True,
        "setup_script": """#!/usr/bin/env bash
            chmod +x yq_linux_{arch}
            mv yq_linux_{arch} yq
            mv yq {install_dir}
            """,
    },
}


def main():
    # filter installed utilities out of 'crates' and 'programs'
    crates = {
        crate: config for (crate, config) in CRATES.items() if not is_installed(crate)
    }
    programs = {
        program: config
        for (program, config) in PROGRAMS.items()
        if not is_installed(program)
    }

    to_install = [
        format_package_string(name, config)
        for name, config in (crates | programs).items()
    ]

    if len(to_install) == 0:
        return

    print(
        f"The following programs will be installed to {INSTALL_DIR}: {' '.join(to_install)}"
    )

    if AUTOMATIC_INSTALL:
        binaries_only = True
    else:
        confirm = (
            input("Do you want to proceed with the installation? (y/n): ")
            .strip()
            .lower()
        )
        if confirm != "y":
            print("Installation aborted.")
            return

        binaries_only = input("Binaries only? (y/n)").strip().lower()
        binaries_only = True if binaries_only == "y" else False

    print(f"Installing: {' '.join(to_install)}")
    os.makedirs(INSTALL_DIR, exist_ok=True)

    if binaries_only:
        install_from_releases(programs | crates)

    else:
        if is_installed("brew"):
            install_with_brew(programs | crates)
            return

        if is_installed("cargo"):
            install_with_cargo(crates)
            install_from_releases(programs)
            return

        else:
            print("no brew or cargo?")


def is_installed(program):
    return shutil.which(program) is not None


# build a "package@version" string, using the config["package_name"] override if present
def format_package_string(name, config):
    package_name = config.get("package_name", name)
    return f"{package_name}@{config['version']}"


def install_with_brew(program_list):
    if program_list:
        strings = [
            format_package_string(name, config) for name, config in program_list.items()
        ]
        subprocess.run(["brew", "install", *strings], check=True)


def install_with_cargo(program_list):
    if program_list:
        strings = [
            format_package_string(name, config) for name, config in program_list.items()
        ]
        subprocess.run(["cargo", "install", *strings], check=True)


def install_from_releases(program_list):
    for program, config in program_list.items():
        version = config["version"]
        url_template = config["url_template"]
        arch = "amd64" if config.get("is_amd64") else ARCH
        url = url_template.format(version=version, arch=arch)

        with tempfile.TemporaryDirectory(delete=False) as temp_dir:
            download_and_extract(url, temp_dir)

            if "setup_script" in config:
                setup_script_script = config["setup_script"]
                setup_script_script = setup_script_script.format(
                    program=program, version=version, arch=arch, install_dir=INSTALL_DIR
                )
                script_path = f"{temp_dir}/{program}_setup_script.sh"
                with open(script_path, "w") as script_file:
                    script_file.write(dedent(setup_script_script))

                subprocess.run(["chmod", "+x", script_path], check=True)
                subprocess.run([script_path], cwd=temp_dir, check=True)
            else:
                print(f"Warning: No setup found for {program}")


def download_and_extract(url, install_dir):
    filename = os.path.basename(urlparse(url).path)
    is_tarball = filename.lower().endswith(".tar.gz")
    download_path = f"{install_dir}/{filename}"
    subprocess.run(["curl", "-L", "-o", download_path, url], check=True)
    if is_tarball:
        subprocess.run(["tar", "-xzf", download_path, "-C", install_dir], check=True)


if __name__ == "__main__":
    main()

# TODO: These require different installation methods, eg

# distro package managers, cloning git repo, running installation scripts
# - "fzf": "0.60.3" git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
# - "tmux": "3.5a",
# - "tpm": "v3.1.0", git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
# - "zsh": "5.9",
# - "zplug": "2.4.2" git clone https://github.com/zplug/zplug $ZPLUG_HOME

# Cargo w/ git url
# -"uv" (python venv / package manager) cargo install --git https://github.com/astral-sh/uv uv
# - pipes-rs cargo install --git https://github.com/lhvy/pipes-rs

# Linux only
# - keyd (git clone & make) https://github.com/rvaiya/keyd
