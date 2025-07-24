#!/usr/bin/env python3

# install.py - Download, Extract, and move files to ~/.local/bin

# Files are downloaded to a temp dir and extracted.
# setup_script is copied to the temp dir and executed.

# Set INSTALL_DIR to override default location
# Set ARCH to override system aritechture

# Config Format:
# "name": str (name of the command to look for)
#         "version": str (release version, used in urls and file)
#         "url_template": str (can referece name, version, arch variables)
#         "is_amd64": str (some projects use "amd64" instead of "x86_64")
#         "setup_script": str (script to run after download & extract)
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

AUTOMATIC = os.getenv("AUTOMATIC")


PROGRAMS = {
    "bat": {
        "version": "0.25.0",
        "url_template": "https://github.com/sharkdp/bat/releases/download/v{version}/bat-v{version}-{arch}-unknown-linux-musl.tar.gz",
        "setup_script": """#!/usr/bin/env bash
            mv bat-v{version}-{arch}-unknown-linux-musl/bat {install_dir}
            """,
    },
    "duf": {
        "version": "0.8.1",
        "url_template": "https://github.com/muesli/duf/releases/download/v{version}/duf_{version}_linux_{arch}.tar.gz",
        "setup_script": """#!/usr/bin/env bash
            chmod +x duf
            mv duf {install_dir}
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
    "fastfetch": {
        "version": "2.40.3",
        "url_template": "https://github.com/fastfetch-cli/fastfetch/releases/download/{version}/fastfetch-linux-{arch}.tar.gz",
        "is_amd64": True,
        "setup_script": """#!/usr/bin/env bash
            chmod +x fastfetch-linux-{arch}/usr/bin/fastfetch
            mv fastfetch-linux-{arch}/usr/bin/fastfetch {install_dir}
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
    "fnm": {
        "version": "1.38.1",
        "url_template": "https://github.com/Schniz/fnm/releases/download/v{version}/fnm-linux.zip",
        "setup_script": """#!/usr/bin/env bash
            unzip fnm-linux.zip
            chmod +x fnm
            mv fnm {install_dir}
            """,
    },
    "jq": {
        "version": "1.7.1",
        "url_template": "https://github.com/jqlang/jq/releases/download/jq-{version}/jq-linux-{arch}",
        "is_amd64": True,
        "setup_script": """#!/usr/bin/env bash
            chmod +x jq-linux-{arch}
            mv jq-linux-{arch} {install_dir}
            """,
    },
    "just": {
        "version": "1.40.0",
        "url_template": "https://github.com/casey/just/releases/download/{version}/just-{version}-{arch}-unknown-linux-musl.tar.gz",
        "setup_script": """#!/usr/bin/env bash
            mv just {install_dir}
            """,
    },
    "k6": {
        "version": "1.1.0",
        "url_template": "https://github.com/grafana/k6/releases/download/v{version}/k6-v{version}-linux-amd64.tar.gz",
        "setup_script": """#!/usr/bin/env bash
            tar xzvf k6-v{version}-linux-amd64.tar.gz
            mv k6-v{version}-linux-amd64 {install_dir}
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
    "ollama": {
        "version": "0.6.4",
        "url_template": "https://github.com/ollama/ollama/releases/download/v{version}/ollama-linux-{arch}.tgz",
        "is_amd64": True,
        "setup_script": """#!/usr/bin/env bash
            mv bin/ollama {install_dir}
            """,
    },
    "pipes-rs": {
        "version": "1.6.3",
        "url_template": "https://github.com/lhvy/pipes-rs/releases/download/v{version}/pipes-rs-linux-{arch}.tar.gz",
        "setup_script": """#!/usr/bin/env bash
            mv target/{arch}-unknown-linux-gnu/release/pipes-rs {install_dir}
            """,
    },
    "rg": {
        "version": "14.1.1",
        "url_template": "https://github.com/BurntSushi/ripgrep/releases/download/{version}/ripgrep-{version}-{arch}-unknown-linux-musl.tar.gz",
        "setup_script": """#!/usr/bin/env bash
            mv ripgrep-{version}-{arch}-unknown-linux-musl/rg {install_dir}
            """,
    },
    "starship": {
        "version": "1.22.1",
        "url_template": "https://github.com/starship/starship/releases/download/v{version}/starship-{arch}-unknown-linux-musl.tar.gz",
        "setup_script": """#!/usr/bin/env bash
            mv starship {install_dir}
            """,
    },
    "step": {
        "version": "0.28.6",
        "url_template": "https://dl.smallstep.com/gh-release/cli/gh-release-header/v{version}/step_linux_{version}_{arch}.tar.gz",
        "is_amd64": True,
        "setup_script": """#!/usr/bin/env bash
            mv step_{version}/bin/step {install_dir}
            """,
    },
    "step-ca": {
        "version": "0.28.3",
        "url_template": "https://dl.smallstep.com/gh-release/certificates/gh-release-header/v{version}/step-ca_linux_{version}_amd64.tar.gz",
        "is_amd64": True,
        "setup_script": """#!/usr/bin/env bash
            mv step-ca {install_dir}
            """,
    },
    "uv": {
        "version": "0.6.12",
        "url_template": "https://github.com/astral-sh/uv/releases/download/{version}/uv-{arch}-unknown-linux-musl.tar.gz",
        "setup_script": """#!/usr/bin/env bash
            mv uv-{arch}-unknown-linux-musl/uv  {install_dir}
            mv uv-{arch}-unknown-linux-musl/uvx  {install_dir}
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
    "zoxide": {
        "version": "0.9.7",
        "url_template": "https://github.com/ajeetdsouza/zoxide/releases/download/v{version}/zoxide-{version}-{arch}-unknown-linux-musl.tar.gz",
        "setup_script": """#!/usr/bin/env bash
            mv zoxide {install_dir}
            """,
    },
}


def main():
    # filter out things that are already installed
    programs = {
        program: config
        for (program, config) in PROGRAMS.items()
        if not is_installed(program)
    }

    to_install = [
        format_package_string(name, config) for name, config in programs.items()
    ]

    if len(to_install) == 0:
        return

    print(
        f"The following programs will be installed to {INSTALL_DIR}: {' '.join(to_install)}"
    )

    if not AUTOMATIC:
        confirm = (
            input("Do you want to proceed with the installation? (y/n): ")
            .strip()
            .lower()
        )
        if confirm != "y":
            print("Installation aborted.")
            return

    print(f"Installing: {' '.join(to_install)}")
    os.makedirs(INSTALL_DIR, exist_ok=True)
    install_from_releases(programs)


def is_installed(program):
    return shutil.which(program) is not None


# build a "package@version" string, using the config["package_name"] override if present
def format_package_string(name, config):
    package_name = config.get("package_name", name)
    return f"{package_name}@{config['version']}"


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


def download_and_extract(url, temp_dir):
    filename = os.path.basename(urlparse(url).path)
    is_tarball = filename.lower().endswith(".tar.gz") or filename.lower().endswith(
        ".tgz"
    )
    download_path = f"{temp_dir}/{filename}"
    subprocess.run(["curl", "-L", "-o", download_path, url], check=True)
    if is_tarball:
        subprocess.run(["tar", "xzvf", download_path, "-C", temp_dir], check=True)


if __name__ == "__main__":
    main()
