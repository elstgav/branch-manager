# Changelog

### `1.13.0` April 17, 2026

- Switch `squashed` suffix to prefix in `squash_branch` command (e.g. `squashed--my-branch` instead of `my-branch--squashed`). Intended to make CLI lookup easier.

### `1.12.0` August 29, 2025

- Fix `pull_and_prune` to restore stash _after_ returning to original branch

### `1.11.0` July 16, 2025

- Improve `squash_branch` output; make it more explicit if new branch is created

### `1.10.0` June 30, 2025

- Add `squash_branch` command

### `1.9.0` June 30, 2025

- Add `reset_branch_to_origin` command

### `1.8.0` May 23, 2025

- Fix missing method for branch auto-completion

### `1.7.0` April 12, 2024

- Update `pull_and_prune` to detect and delete squash-merged branches

### `1.6.0` October 12, 2022

- Fix global namespace pollution by using local variables

### `1.5.0` September 30, 2022

- Auto-detect default branch name (see [Determining Default Branch](#determining-default-branch) above)

### `1.4.0` September 2, 2021

- Add autocompletion of branch names

### `1.3.1` April 17, 2020

- Change `pull_and_prune` branch deletion message color  
  _Changed from red (danger) to yellow (warning), since branch deletion is expected behavior._

### `1.3.0` April 16, 2020

- Add `pull_and_prune` command

### `1.2.1` April 14, 2020

- Colorize status messages
- Print message when restoring stashed changes

### `1.2.0` April 14, 2020

- Include untracked files when auto-stashing changes
- Remove “no stash” feedback to reduce noise

### `1.1.1` October 16, 2017

- Fix warning message if post-checkout hook doesn’t exist ([#2](https://github.com/elstgav/branch-manager/issues/2))

### `1.1.0` October 16, 2017

- Add `rebase_branch` command (Thanks [@blimmer!](https://github.com/blimmer))

### `1.0.0` February 2, 2016
