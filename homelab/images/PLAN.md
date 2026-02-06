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
homelab/
  images/                              # image building (this directory)
    PLAN.md                            # this file
    build.py                           # orchestrator (libvirt lifecycle + ansible invocation)
    build-playbook.yaml                # single-purpose build playbook
    versions.yaml                      # single source of truth for all version pins + checksums
    specs/                             # declarative image profiles (vars files)
      base.yaml                        # common packages, tools
      containerd.yaml                  # rootless container system prerequisites
      nvidia.yaml                      # GPU drivers + toolkit
      full.yaml                        # everything
    tasks/
      packages.yaml                    # system-level apt installs
      tools.yaml                       # go, rust, neovim, fzf (installed to /usr/local)
      containerd-system.yaml           # uidmap, sysctl, apparmor profiles (no per-user setup)
      nvidia.yaml                      # drivers, container toolkit, gpu exporter
      harden.yaml                      # read-only root, fstab, delete builder user, cleanup
  vms/                                 # VM lifecycle and deployment (existing, refactored)
    create.yaml                        # libvirt domain creation (define, disk, start)
    deploy.yaml                        # post-boot identity provisioning
    tasks/
      containerd-user.yaml             # containerd-rootless-setuptool.sh, per-user
      dotfiles.yaml                    # zsh, tmux, nvim config, cloned into $HOME
      monitoring.yaml                  # node_exporter, fluent-bit, laurel
```

## Implementation Steps

### Phase 1: Centralize versions

- [ ] Create `images/versions.yaml` with all version pins and SHA256 checksums
- [ ] Add checksums to existing download tasks (`get_url` checksum param)
- [ ] Reference `versions.yaml` as `vars_files` from existing playbooks

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

## Notes

- The Python orchestrator (`build.py`) is the right approach for managing the
  build VM lifecycle. Packer would replace ~100 lines of this script but adds a
  dependency for minimal gain.
- `versions.yaml` enables automated version bump scripts (check GitHub releases,
  update pins + checksums, open PR).
- The read-only root pairs naturally with rootless nerdctl: all container state
  lives under `$HOME` on a mutable filesystem, while the OS root is immutable.
- dm-verity is a future option for tamper-evident roots but significantly more
  complex. Start with fstab `ro` + mutable bind mounts.
