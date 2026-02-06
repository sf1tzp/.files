# Custom VM Image Build Pipeline -- Redesign Plan

## Problem

The current `homelab/vms/` playbooks conflate image building and VM deployment
through shared playbooks, tagged plays, and inconsistent user management. The
build flow creates users that shouldn't exist in the final image, then tries to
clean them up in a finalize step. This has led to lingering users with sudo
access being baked into base images.

## Design Principle

**Images are user-agnostic.** The build creates a system-level artifact. Users,
SSH keys, hostnames, and IPs are deployment concerns applied after boot.

## Target Directory Structure

```
versions.yaml                            # single source of truth for ALL version pins + checksums
                                         # consumed by both install.py and Ansible playbooks
homelab/
  images/                                # image building (this directory)
    PLAN.md                              # this file
    build.py                             # orchestrator (libvirt lifecycle + ansible invocation)
    build-playbook.yaml                  # single-purpose build playbook
    specs/                               # declarative image profiles (vars files)
      base.yaml                          # common packages, tools
      containerd.yaml                    # rootless container system prerequisites
      nvidia.yaml                        # GPU drivers + toolkit
      full.yaml                          # everything
    tasks/
      packages.yaml                      # system-level apt installs
      tools.yaml                         # go, rust, neovim, fzf (installed to /usr/local)
      containerd-system.yaml             # uidmap, sysctl, apparmor profiles (no per-user setup)
      nvidia.yaml                        # drivers, container toolkit, gpu exporter
      harden.yaml                        # read-only root, fstab, delete builder user, cleanup
  vms/                                   # VM lifecycle and deployment (existing, refactored)
    create.yaml                          # libvirt domain creation (define, disk, start)
    deploy.yaml                          # post-boot identity provisioning
    tasks/
      containerd-user.yaml               # containerd-rootless-setuptool.sh, per-user
      dotfiles.yaml                      # zsh, tmux, nvim config, cloned into $HOME
      monitoring.yaml                    # node_exporter, fluent-bit, laurel
shell/
  scripts/
    install.py                           # reads versions.yaml, installs user-level CLI tools
```

## Implementation Steps

### Phase 1: Versions manifest and install.py redesign

Create a single `versions.yaml` at the repo root. Both `install.py` and Ansible
playbooks read from it. No tool has its version defined in more than one place.

#### versions.yaml format

```yaml
# Entries used by install.py for user-level CLI tools
bat:
  version: "0.25.0"
  sha256: "..."
  repo: sharkdp/bat                              # shorthand for GitHub releases URL
  artifact: "bat-v{version}-{arch}-unknown-linux-musl.tar.gz"
  binary: "bat-v{version}-{arch}-unknown-linux-musl/bat"
  arch: x86_64

jq:
  version: "1.7.1"
  sha256: "..."
  repo: jqlang/jq
  artifact: "jq-linux-{arch}"                    # not a tarball, just a raw binary
  binary: "jq-linux-{arch}"
  arch: amd64

nerdctl:
  version: "2.1.3"
  sha256: "..."
  repo: containerd/nerdctl
  artifact: "nerdctl-full-{version}-linux-{arch}.tar.gz"
  extract_to: "~/.local"                         # whole tree, not a single binary
  arch: amd64

# Entries used only by Ansible (system-level installs)
go:
  version: "1.24.2"
  sha256: "..."
  url: "https://golang.org/dl/go{version}.linux-amd64.tar.gz"
  system: true                                   # installed to /usr/local by Ansible

neovim:
  version: "0.11.3"
  sha256: "..."
  repo: neovim/neovim
  artifact: "nvim-linux-x86_64.tar.gz"
  system: true

nvidia_gpu_exporter:
  version: "1.3.2"
  sha256: "..."
  repo: utkuozdemir/nvidia_gpu_exporter
  artifact: "nvidia_gpu_exporter_{version}_linux_x86_64.tar.gz"
  system: true
```

Most tools follow one of three installation patterns:

1. **Binary in a subdirectory** -- `binary` field points to path inside archive
   (bat, dust, fd, rg, uv, step, etc.)
2. **Binary at archive root** -- `binary` matches the filename
   (eza, just, starship, zoxide, duf, etc.)
3. **Whole tree extraction** -- `extract_to` instead of `binary`
   (nerdctl only)

Raw binaries (not tarballs) like jq are detected by artifact extension.

#### install.py redesign

The `PROGRAMS` dict and all embedded `setup_script` bash strings are replaced by
reading `versions.yaml`. The installer becomes ~50 lines of logic:

```python
def install(name, spec):
    url = build_url(spec)                        # from repo + artifact, or explicit url
    with tempfile.TemporaryDirectory() as tmp:
        path = download(url, tmp)
        verify_checksum(path, spec["sha256"])
        if is_archive(path):
            extract(path, tmp)
        if "extract_to" in spec:
            dest = os.path.expanduser(spec["extract_to"])
            extract(path, dest)                  # nerdctl-style: whole tree
        else:
            binary = spec["binary"].format(version=spec["version"], arch=arch)
            shutil.move(os.path.join(tmp, binary), os.path.join(INSTALL_DIR, name))
            os.chmod(os.path.join(INSTALL_DIR, name), 0o755)
```

install.py filters for entries where `system` is not true (or absent). Ansible
loads the full file and references `{{ versions.go.version }}`.

#### Migration steps

- [ ] Create `versions.yaml` at repo root with all current version pins + SHA256
      checksums, consolidated from:
  - `shell/scripts/install.py` (20 tools)
  - `homelab/vms/custom-base-image.yaml` (nerdctl, go, neovim, nvidia_gpu_exporter)
  - `homelab/vms/tasks/common.yaml` (go, neovim -- duplicates)
  - `homelab/vms/tasks/nvidia.yaml` (nvidia_gpu_exporter -- duplicate)
  - `homelab/vms/set-up.yaml` (nerdctl, nvidia_gpu_exporter -- duplicates)
  - `shell/bash/installs` (migrate any still-needed tools, then retire the file)
- [ ] Rewrite `install.py` to read `versions.yaml`, drop embedded PROGRAMS dict
  - Three install patterns, no per-tool bash scripts
  - Verify SHA256 after download
  - Keep `AUTOMATIC` mode and `is_installed()` skip logic
- [ ] Update Ansible playbooks to use `vars_files: [../../versions.yaml]`
  - Replace inline `nerdctl_version`, `go_version`, `nvim_version`, etc.
  - Add `checksum: "sha256:{{ versions.<tool>.sha256 }}"` to `get_url` tasks
- [ ] Retire `shell/bash/installs` (migrate tmux, shellcheck, vivid if still used)
- [ ] (Optional) Write a version bump script that checks GitHub releases API,
      updates version + checksum in `versions.yaml`, and opens a PR

### Phase 2: Dedicated build playbook

- [ ] Create `images/build-playbook.yaml` with a single throwaway `builder` user
  - Connects as `builder` (created by cloud-init for the build VM)
  - Installs everything system-wide (no user home dependencies)
  - Deletes `builder` user at the end -- no finalize gymnastics
- [ ] Adapt `build-custom-image.py` → `images/build.py`
  - Simplify: no `vm_username` passthrough, builder user is always `builder`
  - Keep prerequisite checks, VM lifecycle management, arg parsing
- [ ] Create image profile specs under `images/specs/`
  - Each profile is a vars file that the build playbook loads
  - Profiles compose (e.g., `full.yaml` includes containerd + nvidia + monitoring)

### Phase 3: Split containerd tasks

- [ ] Extract system-level container prerequisites into `images/tasks/containerd-system.yaml`
  - uidmap package, `/etc/subuid` + `/etc/subgid` templates (parameterized by user)
  - AppArmor profile for rootlesskit (parameterized path)
  - sysctl settings (ping_group_range, unprivileged_port_start)
- [ ] Extract per-user container setup into `vms/tasks/containerd-user.yaml`
  - nerdctl extraction to `~/.local`
  - `containerd-rootless-setuptool.sh install`
  - `install-bypass4netnsd`
  - `loginctl enable-linger`
- [ ] System-level tasks run at image build time, user-level tasks run at deploy time

### Phase 4: Read-only root filesystem

- [ ] Create `images/tasks/harden.yaml` (runs last in build playbook)
  - Configure tmpfs mounts in fstab for `/tmp`, `/var/tmp`, `/run`
  - Mark root filesystem read-only in fstab (`defaults,ro`)
  - Ensure `/var/lib` and `/home` are on separate mutable mounts
  - Set up `tmpfiles.d` entries for volatile paths that services expect
- [ ] Test with a deployed VM to verify:
  - System boots cleanly with ro root
  - Container volumes under `$HOME` are writable
  - Logs, package state, and other mutable paths work correctly
  - `apt` operations are blocked (or require remount -- this is intentional)

### Phase 5: Refactor deployment path

- [ ] Create `vms/deploy.yaml` for post-boot identity provisioning
  - Cloud-init handles: user creation, hostname, IP, SSH key import
  - deploy.yaml handles: dotfiles, rootless containerd init, monitoring, wireguard
- [ ] Refactor `vms/tasks/dotfiles.yaml` out of `tasks/common.yaml`
  - Clone .files repo, symlink zsh/tmux/nvim configs
  - This is user-scoped, not image-scoped
- [ ] Retire `custom-base-image.yaml` and its tagged multi-play approach

### Phase 6: Cleanup

- [ ] Remove `bootstrap-deployer.yaml` if deployer user is no longer needed
  (deploy.yaml creates the correct user per-VM via cloud-init)
- [ ] Consolidate inventory `ansible_user` to a single convention
- [ ] Update `requirements.yaml` to declare all used roles (prometheus)
- [ ] Delete dead code and unused templates

## Current Version Sprawl (for reference)

Tools with versions defined in multiple places (at time of writing):

| Tool                 | install.py | custom-base-image.yaml | common.yaml | set-up.yaml | tasks/nvidia.yaml | bash/installs |
|----------------------|-----------|------------------------|-------------|-------------|-------------------|---------------|
| nerdctl              | 2.0.3     | 2.1.3                  | --          | 2.1.3       | --                | --            |
| go                   | --        | 1.24.2                 | 1.24.2      | --          | --                | 1.19.4        |
| neovim               | --        | 0.11.3                 | 0.11.3      | --          | --                | 0.10.4        |
| nvidia_gpu_exporter  | --        | 1.3.2                  | --          | 1.3.2       | 1.3.2             | --            |

`shell/bash/installs` also has stale pins for clusterctl, glow, helm, k9s, kind,
kubectx, node.js, python, shellcheck, tmux, vivid -- most from a previous k8s era.

## Notes

- The Python orchestrator (`build.py`) is the right approach for managing the
  build VM lifecycle. Packer would replace ~100 lines of this script but adds a
  dependency for minimal gain.
- `versions.yaml` at the repo root is the single source of truth for all binary
  versions. install.py consumes it for user-level CLI tools, Ansible consumes it
  for system-level installs. No version is defined in more than one place.
- The read-only root pairs naturally with rootless nerdctl: all container state
  lives under `$HOME` on a mutable filesystem, while the OS root is immutable.
- dm-verity is a future option for tamper-evident roots but significantly more
  complex. Start with fstab `ro` + mutable bind mounts.
- Container image versions (compose files under `homelab/services/`) are out of
  scope for `versions.yaml` -- those are pinned per-service and don't overlap
  with the CLI/system tool versions.
