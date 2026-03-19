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
      cleanup.yaml                       # delete builder user, apt clean, truncate logs
  vms/                                   # VM lifecycle and deployment (existing, refactored)
    create.yaml                          # libvirt domain creation (define, disk, start)
    deploy.yaml                          # post-boot identity provisioning
    tasks/
      containerd-user.yaml               # containerd-rootless-setuptool.sh, per-user
      dotfiles.yaml                      # zsh, tmux, nvim config, cloned into $HOME
      monitoring.yaml                    # node_exporter, fluent-bit, laurel
```

## Implementation Steps

### Phase 1: Dedicated build playbook and image specs

> Note: Previously, we used 10.0.0.7 as our custom image builder VM IP. That IP is now in use by another lab service. 10.0.0.10 is available

Each image spec is a self-contained vars file that pins its own versions and
package lists. Duplication across specs is acceptable -- keeping specs
independent and readable is more valuable than DRY at this stage.

- [x] Create `images/build-playbook.yaml` with cloud-init default user
  - Connects as `ubuntu` (cloud-init default -- simpler than creating a custom builder user)
  - Installs everything system-wide via `become: true`
  - Loads a spec file via `--extra-vars "spec=base"` → `vars_files: [specs/{{ spec }}.yaml]`
  - Deletes `ubuntu` user at the end -- no finalize gymnastics
- [x] Adapt `build-custom-image.py` → `images/build.py`
  - Simplify: no `vm_username` passthrough, cloud-init default user is always `ubuntu`
  - Accept `--spec` flag to select which image profile to build
  - Keep prerequisite checks, VM lifecycle management, arg parsing
  - Validates spec file exists in `check_prerequisites()`
- [x] Create image profile specs under `images/specs/`
  - `base.yaml` -- minimal apt packages (curl, git, jq, make, tmux, etc.)
  - `containerd.yaml` -- base + uidmap (stub, Phase 2 adds system tasks)
  - `nvidia.yaml` -- base + ubuntu-drivers-common (stub, Phase 2 adds driver tasks)
  - `full.yaml` -- containerd + nvidia packages (stub, Phase 2 adds all tasks)
  - Each spec owns its version pins (no shared versions manifest)
- [x] Update inventory: custom-image-builder IP changed from 10.0.0.7 to 10.0.0.10

### Phase 2: Split containerd tasks

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

### Phase 3: Refactor deployment path

- [ ] Create `vms/deploy.yaml` for post-boot identity provisioning
  - Cloud-init handles: user creation, hostname, IP, SSH key import
  - deploy.yaml handles: dotfiles, rootless containerd init, monitoring, wireguard
- [ ] Refactor `vms/tasks/dotfiles.yaml` out of `tasks/common.yaml`
  - Clone .files repo, symlink zsh/tmux/nvim configs
  - This is user-scoped, not image-scoped
- [ ] Retire `custom-base-image.yaml` and its tagged multi-play approach

### Phase 4: Cleanup

- [ ] Remove `bootstrap-deployer.yaml` if deployer user is no longer needed
  (deploy.yaml creates the correct user per-VM via cloud-init)
- [ ] Consolidate inventory `ansible_user` to a single convention
- [ ] Update `requirements.yaml` to declare all used roles (prometheus)
- [ ] Delete dead code and unused templates

## Future Considerations

- **Versions consolidation**: If version sprawl across specs becomes a
  maintenance burden, consolidate pins into a shared `versions.yaml`. Not
  worth the upfront investment right now.
- **Read-only root filesystem**: fstab `ro` + mutable bind mounts for `/home`
  and `/var/lib`. Pairs well with rootless nerdctl (all container state under
  `$HOME`). dm-verity is a further step for tamper-evident roots.
- **install.py refactor**: The current `PROGRAMS` dict in `shell/scripts/install.py`
  works fine for user-level CLI tools. Could be unified with image specs later
  if the overlap justifies it.

## Notes

- The Python orchestrator (`build.py`) is the right approach for managing the
  build VM lifecycle. Packer would replace ~100 lines of this script but adds a
  dependency for minimal gain.
- Container image versions (compose files under `homelab/services/`) are out of
  scope -- those are pinned per-service and don't overlap with system tool
  versions.
- After base images are stable, the next focus is Ansible-driven VM topologies
  for testing multi-tier scenarios (web-db-cache, queue systems, etc.).
