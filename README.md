# branch-manager [![GitHub tag](https://img.shields.io/github/v/tag/elstgav/branch-manager?label=version&sort=semver)](#changelog)

oh-my-zsh plugin for managing branches

Updating branches can be a pain, especially if you have unsaved changes in your workspace. `branch-manager` makes it easier to perform updates by auto-stashing your changes before doing routine maintenance, and then returning you to your workspace.

## Usage

`branch-manager` adds the following commands to your shell:

- `update_branch [branch=current_branch]`  
  Pull `branch` and return to your workspace  
  _You can also use this to update other branches while staying in your own_

- `merge_branch [branch=default_branch]`  
  Merge `branch` into your own
- `rebase_branch [branch=default_branch]`  
  Rebase `branch` into your own

- `squash_branch [base_branch|main_branch] [-m/--message=<msg>|"Squashed $current_branch"] [-b/--branch=<name>|"$current_branch--squashed"] [-f/--force]`  
  Squash the current branch into a single commit.  
  _You can also use this to squash in place on the current branch by using the `--force` flag_

- `reset_branch_to_origin [branch=current_branch]`  
  Reset `branch` to the origin remote.  
  _Reset a branch to the origin remote, while keeping your uncommitted changes_

- `pull_and_prune [branch=default_branch]`  
  Pull `branch` and delete all dead/merged branches.  
  _Useful for staying up-to-date with an active remote, while keeping your local repo tidy_

## Determining Default Branch

For commands that default to the “default branch” (e.g. `master`/`main`), the default branch is determined by checking the following in order:

1. `git config init.defaultBranch`
2. `BRANCH_MANAGER_DEFAULT_BRANCH` environment variable
3. …otherwise defaults to `master`

If it’s guessing wrong, the easiest way to fix it is to set the default branch per repo:

```sh
git config init.defaultBranch [your_branch_name_here]
```

or globally:

```sh
git config --global init.defaultBranch [your_branch_name_here]
```

## Installation

`branch-manager` is built to work with [oh-my-zsh](https://github.com/robbyrussell/oh-my-zsh/), so you’ll need that installed first.

1. `$ cd ~/.oh-my-zsh/custom/plugins` (you may have to create the folder)
2. `$ git clone git@github.com:elstgav/branch-manager.git`
3. In your .zshrc, add `branch-manager` to your oh-my-zsh plugins:

```bash
plugins(rails git branch-manager)
```

## Changelog

See [CHANGELOG](CHANGELOG.md).
