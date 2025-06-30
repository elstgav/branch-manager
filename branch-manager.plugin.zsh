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
