# Determine the default branch name for a given repo
_branch_manager_default_branch_name () {
  local configured_default_branch=$(git config init.defaultBranch)

  if [[ -v configured_default_branch ]]; then
    echo $configured_default_branch
  elif [[ -v BRANCH_MANAGER_DEFAULT_BRANCH ]]; then
    echo $BRANCH_MANAGER_DEFAULT_BRANCH
  else
    echo 'master'
  fi
}


# ==============================================================================
# Update Branch
# ==============================================================================
#
# update_branch [branch_to_update|current_branch]
#
# Pull upstream commits while preserving any unstaged changes.
#
# Pulls upstream changes for the current (or specified) branch and returns you
# to your workspace with any uncommitted changes restored.

function update_branch {
  local current_branch=$(git symbolic-ref --short HEAD)
  local stashed_changes=$(git stash -u)
  local git_dir="$(git rev-parse --git-dir)"
  local hook="$git_dir/hooks/post-checkout"
  local requested_branch="${1:-$current_branch}"

  # Disable post-checkout hook temporarily -------------------------------------
  [ -x $hook ] && mv $hook "$hook-disabled"

  # Update the requested branch ------------------------------------------------
  echo -n "$fg[blue]"
  echo "Updating $requested_branch…"
  echo "$reset_color"

  git checkout $requested_branch
  git pull

  # If we updated the current branch, then we should run post-checkout hook
  if [[ -e "$hook-disabled" && $requested_branch == $current_branch ]]; then
    mv "$hook-disabled" $hook
  fi

  # Return to current branch ---------------------------------------------------
  git checkout $current_branch

  # Re-enable hook -------------------------------------------------------------
  [ -e "$hook-disabled" ] && mv "$hook-disabled" $hook

  # Reset working directory ----------------------------------------------------
  if [ "$stashed_changes" != "No local changes to save" ]; then
    echo "$fg[blue]"
    echo "Restoring stashed changes…"
    echo "$reset_color"
    git stash pop
  fi

  # Show Confirmation ----------------------------------------------------------
  echo "$fg[green]"
  echo "✓ Succesfully updated $requested_branch"
  echo "$reset_color"
}


# ==============================================================================
# Merge Branch
# ==============================================================================
#
# merge_branch [branch_to_merge_in|main_branch]
#
# Merge another branch while preserving any unstaged changes.
#
# Merges the default (or specified) branch into the current branch and returns
# you to your workspace with any uncommitted changes restored.

function merge_branch {
  local current_branch=$(git symbolic-ref --short HEAD)
  local stashed_changes=$(git stash -u)
  local git_dir="$(git rev-parse --git-dir)"
  local hook="$git_dir/hooks/post-checkout"
  local requested_branch="${1:-$(_branch_manager_default_branch_name)}"

  # Disable post-checkout hook temporarily -------------------------------------
  [ -x $hook ] && mv $hook "$hook-disabled"

  # Update the requested branch ------------------------------------------------

  echo -n "$fg[blue]"
  echo "Updating $requested_branch…"
  echo "$reset_color"

  git checkout $requested_branch
  git pull

  # Return to current branch ---------------------------------------------------

  git checkout $current_branch

  # Re-enable hook -------------------------------------------------------------

  [ -e "$hook-disabled" ] && mv "$hook-disabled" $hook

  # Merge changes --------------------------------------------------------------

  echo "$fg[blue]"
  echo "Merging $requested_branch…"
  echo "$reset_color"
  git merge $requested_branch --no-edit

  # Reset working directory ----------------------------------------------------

  if [ "$stashed_changes" != "No local changes to save" ]; then
    echo "$fg[blue]"
    echo "Restoring stashed changes…"
    echo "$reset_color"
    git stash pop
  fi

  # Show Confirmation ----------------------------------------------------------

  echo "$fg[green]"
  echo "✓ Succesfully merged $requested_branch into $current_branch"
  echo "$reset_color"
}


# ==============================================================================
# Rebase Branch
# ==============================================================================
#
# rebase_branch [branch_to_rebase_off|main_branch]
#
# Rebase off another branch while preserving any unstaged changes.
#
# Rebases the current branch off of the default (or specified) branch and
# returns you to your workspace with any uncommitted changes restored.

function rebase_branch {
  local current_branch=$(git symbolic-ref --short HEAD)
  local stashed_changes=$(git stash -u)
  local git_dir="$(git rev-parse --git-dir)"
  local hook="$git_dir/hooks/post-checkout"
  local requested_branch="${1:-$(_branch_manager_default_branch_name)}"

  # Disable post-checkout hook temporarily -------------------------------------

  [ -x $hook ] && mv $hook "$hook-disabled"

  # Update the requested branch ------------------------------------------------

  echo -n "$fg[blue]"
  echo "Updating $requested_branch…"
  echo "$reset_color"

  git checkout $requested_branch
  git pull

  # Return to current branch ---------------------------------------------------

  git checkout $current_branch

  # Re-enable hook -------------------------------------------------------------

  [ -e "$hook-disabled" ] && mv "$hook-disabled" $hook

  # Rebase changes -------------------------------------------------------------

  echo "$fg[blue]"
  echo "Rebasing off $requested_branch…"
  echo "$reset_color"

  git rebase $requested_branch

  # Reset working directory ----------------------------------------------------

  if [ "$stashed_changes" != "No local changes to save" ]; then
    echo "$fg[blue]"
    echo "Restoring stashed changes…"
    echo "$reset_color"
    git stash pop
  fi

  # Show Confirmation ----------------------------------------------------------

  echo "$fg[green]"
  echo "✓ Succesfully rebased $current_branch onto $requested_branch"
  echo "$reset_color"
}


# ==============================================================================
# Squash Branch
# ==============================================================================
#
# squash_branch [base_branch|main_branch]
#   [-m/--message=<msg>|"Squashed $current_branch"]
#   [-b/--branch=<name>|"$current_branch--squashed"]
#   [-f/--force]
#
# Creates a new squashed, single-commit branch with all commits diverged from
# the base branch.
#
# If the --force flag is provided, the current branch will be squashed in place.
#
# Flags:
# -b <name>, --branch=<name>: Set the name of the squashed branch
#   (default: "$current_branch--squashed")
#
# -m <msg>, --message=<msg>: Set the commit message for the squashed commit
#   (default: "Squashed $current_branch")
#
# -f, --force: Squash in place (do not create a new branch)

function squash_branch {
  local current_branch=$(git symbolic-ref --short HEAD)
  local force=false
  local message=""
  local target_branch=""
  local -a positional=()

  # Parse arguments ------------------------------------------------------------
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -f|--force)
        force=true
        target_branch=$current_branch
        shift
        ;;
      -m)
        shift
        message="$1"
        shift
        ;;
      --message=*)
        message="${1#*=}"
        shift
        ;;
      -b)
        shift
        target_branch="$1"
        shift
        ;;
      --branch=*)
        target_branch="${1#*=}"
        shift
        ;;
      --)
        shift
        positional+=("$@")
        break
        ;;
      *)
        positional+=("$1")
        shift
        ;;
    esac
  done

  target_branch="${target_branch:-${current_branch}--squashed}"
  local base_branch="${positional[1]:-$(_branch_manager_default_branch_name)}"
  local default_message="Squashed $current_branch"

  # Show commit messages -------------------------------------------------------

  echo "$fg[blue]"
  echo -n "Commits to be squashed: "
  echo -n "$reset_color$fg_bold[black]"
  echo -n "("
  if [[ $force == true ]]; then
    echo -n "overwriting $reset_color$fg[cyan]target_branch"
  else
    echo -n "into $reset_color$fg[cyan]$target_branch"
  fi
  echo -n "$reset_color$fg_bold[black]"
  echo -n " off of "
  echo -n "$reset_color$fg[cyan]"
  echo -n "$base_branch"
  echo -n "$reset_color$fg_bold[black]"
  echo -n ")"
  echo "$reset_color"
  echo

  git log --reverse --pretty=format:"$fg[yellow]- %s$reset_color $fg_bold[black](%cr)$reset_color" $base_branch..HEAD | cat
  echo

  # Set commit message (if not provided) ---------------------------------------

  if [ -z "$message" ]; then
    echo
    echo -n "Enter commit message: $fg_bold[black](Default: "
    echo -n "$reset_color$fg[cyan]"
    echo -n "\"$default_message\""
    echo -n "$reset_color$fg_bold[black])$reset_color "
    read message

    [[ -z "$message" ]] && message=$default_message
  fi

  # Create new branch if not squashing in place --------------------------------

  if [[ $force == false ]]; then
    echo "$fg[blue]"
    echo "Creating new branch $fg[cyan]$target_branch$fg[blue]…"
    echo "$reset_color"

    git checkout -b "$target_branch"
  fi

  # Stash changes --------------------------------------------------------------

  local stashed_changes=$(git stash -u)

  # Squash commits -------------------------------------------------------------

  echo "$fg[blue]"
  echo "Squashing commits…"
  echo "$reset_color"

  git reset --soft HEAD~$(git rev-list --count HEAD ^$base_branch) && git commit -m "$message"

  # Reset working directory ----------------------------------------------------

  if [ "$stashed_changes" != "No local changes to save" ]; then
    echo "$fg[blue]"
    echo "Restoring stashed changes…"
    echo "$reset_color"
    git stash pop
  fi

  # Show Confirmation ----------------------------------------------------------

  echo "$fg[green]"
  if [[ $force == true ]]; then
    echo "✓ Succesfully squashed $reset_color$fg[cyan]$current_branch"
  else
    echo "✓ Succesfully squashed $reset_color$fg[cyan]$current_branch$reset_color$fg[green] into $reset_color$fg[cyan]$target_branch"
  fi
  echo "$reset_color"
}


# ==============================================================================
# Reset Branch to Origin
# ==============================================================================
#
# Reset the current branch to the origin.
#
# Resets the current branch to the origin and returns you to your workspace with
# any uncommitted changes restored.

function reset_branch_to_origin {
  local current_branch=$(git symbolic-ref --short HEAD)
  local stashed_changes=$(git stash -u)
  local git_dir="$(git rev-parse --git-dir)"
  local hook="$git_dir/hooks/post-checkout"
  local requested_branch="${1:-$current_branch}"

  # Ask for confirmation --------------------------------------------------------

  echo -n "$fg[yellow]"
  echo "Are you sure you want to reset $current_branch to origin/$current_branch?"
  echo "This will discard any changes not on origin/$current_branch."
  echo "$reset_color"
  read -q "REPLY?Continue? (y/n): "
  echo
  echo

  if [[ $REPLY != "y" ]]; then
    echo -n "$fg[yellow]"
    echo "Aborting…"
    echo "$reset_color"
    return
  fi

  # Disable post-checkout hook temporarily -------------------------------------

  [ -x $hook ] && mv $hook "$hook-disabled"

  # Reset the current branch to the origin -------------------------------------

  echo -n "$fg[blue]"
  echo "Resetting $current_branch to origin/$current_branch…"
  echo "$reset_color"

  git checkout $current_branch
  git fetch origin $current_branch
  git reset --hard origin/$current_branch

  # Return to current branch ---------------------------------------------------

  git checkout $current_branch

  # Re-enable hook -------------------------------------------------------------

  [ -e "$hook-disabled" ] && mv "$hook-disabled" $hook

  # Reset working directory ----------------------------------------------------

  if [ "$stashed_changes" != "No local changes to save" ]; then
    echo "$fg[blue]"
    echo "Restoring stashed changes…"
    echo "$reset_color"
    git stash pop
  fi

  # Show Confirmation ----------------------------------------------------------

  echo "$fg[green]"
  echo "✓ Succesfully reset $current_branch to origin/$current_branch"
  echo "$reset_color"
}


# ==============================================================================
# Pull and Prune
# ==============================================================================
#
# Keep your local repository clean and up-to-date by fetching and pruning
# dead/merged branches, while preserving any unstaged changes. Useful for
# staying up-to-date with an active remote, while keeping your local repo tidy.
#
# Pulls upstream changes for the default (or specified) branch, and prunes any
# branches that are dead, merged, or squash-merged to that branch. When
# finished, restores any uncommitted changes and returns you to:
#   - the original branch if it still exists
#   - the default (or specified) branch if the original branch was pruned

function pull_and_prune {
  local original_branch=$(git symbolic-ref --short HEAD)
  local stashed_changes=$(git stash -u)
  local pull_branch="${1:-$(_branch_manager_default_branch_name)}"

  # Update the requested branch ------------------------------------------------

  echo -n "$fg[blue]"
  echo "Updating $pull_branch…"
  echo "$reset_color"

  git checkout $pull_branch
  git pull

  # Prune dead branches --------------------------------------------------------

  echo "$fg[blue]"
  echo "Fetching and pruning branches…"
  echo "$reset_color"

  local prune_output=$(git fetch --prune)

  if [[ $prune_output != "" ]]; then
    echo "$fg[yellow]"
    echo "$prune_output"
    echo "$reset_color"
  else
    echo "✓ Nothing to fetch or prune"
  fi

  # Delete merged branches -----------------------------------------------------

  echo "$fg[blue]"
  echo "Deleting merged branches…"
  echo "$reset_color"

  local deleted_merged_branches=false

  for merged_branch in $(git for-each-ref --format '%(refname:short)' --merged HEAD refs/heads | egrep --invert-match "$pull_branch")
  do
    echo -n "$fg[yellow]"
    echo -n "✗ "
    git branch -d ${merged_branch}
    echo -n "$reset_color"

    deleted_merged_branches=true
  done

  if [ "$deleted_merged_branches" = false ]; then
    echo "✓ Nothing to delete"
  fi

  # Delete squash-merged branches ----------------------------------------------
  #
  # Copied and modified from James Roeder (jmaroeder) under MIT License
  # https://github.com/jmaroeder/plugin-git/blob/216723ef4f9e8dde399661c39c80bdf73f4076c4/functions/gbda.fish

  echo "$fg[blue]"
  echo "Deleting squash-merged branches…"
  echo "$reset_color"

  local deleted_squashed_branches=false

  for squashed_branch in $(git for-each-ref refs/heads/ --format '%(refname:short)' | egrep --invert-match "$pull_branch")
  do
    local merge_base=$(git merge-base $pull_branch $squashed_branch)
    if [[ $(git cherry $pull_branch $(git commit-tree $(git rev-parse $squashed_branch\^{tree}) -p $merge_base -m _)) = -* ]]; then
      echo -n "$fg[yellow]"
      echo -n "✗ "
      git branch -D ${squashed_branch}
      echo -n "$reset_color"

      deleted_squashed_branches=true
    fi
  done

  if [ "$deleted_squashed_branches" = false ]; then
    echo "✓ Nothing to delete"
  fi

  # Reset working directory ----------------------------------------------------

  if [ "$stashed_changes" != "No local changes to save" ]; then
    echo "$fg[blue]"
    echo "Restoring stashed changes…"
    echo "$reset_color"
    git stash pop
  fi

  # Switch back to original branch if still exists -----------------------------

  git rev-parse --verify --quiet $original_branch > /dev/null
  local return_to_original_branch=$?
  if [[ $return_to_original_branch == 0 ]]; then
    echo
    git checkout $original_branch
  fi

  # Show Confirmation ----------------------------------------------------------

  echo "$fg[green]"
  echo "✓ Pulled from $pull_branch and deleted dead/merged branches"
  [[ $return_to_original_branch != 0 ]] && echo "↳ Switched to $pull_branch branch ($original_branch deleted)"
  echo -n "$reset_color"
}


# ==============================================================================
# Auto-Completion
# ==============================================================================

# TODO: Figure out how to properly define these in a _branch-manager #compdef file

# Copied from git-flow plugin
# See https://github.com/ohmyzsh/ohmyzsh/blob/21b385e7bd522983642b52b51db5d4a210a77717/plugins/git-flow/git-flow.plugin.zsh#L351-L359
_branch-manager-git-branch-names () {
  local expl
  declare -a branch_names

  local branch_names=(${${(f)"$(_call_program branchrefs git for-each-ref --format='"%(refname)"' refs/heads 2>/dev/null)"}#refs/heads/})
  __git_command_successful || return

  _wanted branch-names expl branch-name compadd $* - $branch_names
}

_branch-manager () {
  _arguments ':branch:_branch-manager-git-branch-names'
}

compdef _branch-manager update_branch merge_branch rebase_branch pull_and_prune

__git_command_successful () {
  if (( ${#pipestatus:#0} > 0 )); then
    _message 'not a git repository'
    return 1
  fi
  return 0
}
