# Determine the default branch name for a given
_branch_manager_default_branch_name () {
  configured_default_branch=$(git config init.defaultBranch)
  if [[ -v configured_default_branch ]]; then
    echo $configured_default_branch
  elif [[ -v BRANCH_MANAGER_DEFAULT_BRANCH ]]; then
    echo $BRANCH_MANAGER_DEFAULT_BRANCH
  else
    echo 'master'
  fi
}

# Updates a branch and returns you to your workspace
function update_branch {
  current_branch=$(git symbolic-ref --short HEAD)
  stashed_changes=$(git stash -u)
  gitdir="$(git rev-parse --git-dir)"
  hook="$gitdir/hooks/post-checkout"

  # Update the current branch if no argument given
  [[ -z "$1" ]] && other_branch=$current_branch || other_branch=$1

  # disable post-checkout hook temporarily
  [ -x $hook ] && mv $hook "$hook-disabled"

  # Update the requested branch
  echo -n "$fg[blue]"
  echo "Updating $other_branch…"
  echo "$reset_color"

  git checkout $other_branch
  git pull

  # If we updated the current branch, then we should run post-checkout hook
  if [[ -e "$hook-disabled" && $other_branch == $current_branch ]]; then
    mv "$hook-disabled" $hook
  fi

  # Return to current branch
  git checkout $current_branch

  # Re-enable hook
  [ -e "$hook-disabled" ] && mv "$hook-disabled" $hook

  # Reset working directory
  if [ "$stashed_changes" != "No local changes to save" ]; then
    echo "$fg[blue]"
    echo "Restoring stashed changes…"
    echo "$reset_color"
    git stash pop
  fi

  echo "$fg[green]"
  echo "✓ Succesfully updated $other_branch"
  echo "$reset_color"
}


# Merges a branch into your own while preserving your workspace
function merge_branch {
  current_branch=$(git symbolic-ref --short HEAD)
  stashed_changes=$(git stash -u)
  gitdir="$(git rev-parse --git-dir)"
  hook="$gitdir/hooks/post-checkout"

  # Merge from default branch (e.g. "master") if no argument given
  [[ -z "$1" ]] && other_branch=$(_branch_manager_default_branch_name) || other_branch=$1

  # disable post-checkout hook temporarily
  [ -x $hook ] && mv $hook "$hook-disabled"

  # Update the requested branch
  echo -n "$fg[blue]"
  echo "Updating $other_branch…"
  echo "$reset_color"

  git checkout $other_branch
  git pull

  # Return to current branch
  git checkout $current_branch

  # Re-enable hook
  [ -e "$hook-disabled" ] && mv "$hook-disabled" $hook

  # Merge changes
  echo "$fg[blue]"
  echo "Merging $other_branch…"
  echo "$reset_color"
  git merge $other_branch --no-edit

  # Reset working directory
  if [ "$stashed_changes" != "No local changes to save" ]; then
    echo "$fg[blue]"
    echo "Restoring stashed changes…"
    echo "$reset_color"
    git stash pop
  fi

  echo "$fg[green]"
  echo "✓ Succesfully merged $other_branch into $current_branch"
  echo "$reset_color"
}


# Rebases a branch into your own while preserving your workspace
function rebase_branch {
  current_branch=$(git symbolic-ref --short HEAD)
  stashed_changes=$(git stash -u)
  gitdir="$(git rev-parse --git-dir)"
  hook="$gitdir/hooks/post-checkout"

  # Rebase from default branch (e.g. "master") if no argument given
  [[ -z "$1" ]] && other_branch=$(_branch_manager_default_branch_name) || other_branch=$1

  # disable post-checkout hook temporarily
  [ -x $hook ] && mv $hook "$hook-disabled"

  # Update the requested branch
  echo -n "$fg[blue]"
  echo "Updating $other_branch…"
  echo "$reset_color"

  git checkout $other_branch
  git pull

  # Return to current branch
  git checkout $current_branch

  # Re-enable hook
  [ -e "$hook-disabled" ] && mv "$hook-disabled" $hook

  # Rebase changes
  echo "$fg[blue]"
  echo "Rebasing off $other_branch…"
  echo "$reset_color"

  git rebase $other_branch

  # Reset working directory
  if [ "$stashed_changes" != "No local changes to save" ]; then
    echo "$fg[blue]"
    echo "Restoring stashed changes…"
    echo "$reset_color"
    git stash pop
  fi

  echo "$fg[green]"
  echo "✓ Succesfully rebased $current_branch onto $other_branch"
  echo "$reset_color"
}


# Pull a branch, and safely delete any dead/merged branches
function pull_and_prune {
  original_branch=$(git symbolic-ref --short HEAD)
  stashed_changes=$(git stash -u)

  # Pull from default branch (e.g. "master") if no argument given
  [[ -z "$1" ]] && pull_branch=$(_branch_manager_default_branch_name) || pull_branch=$1

  # Update the requested branch
  echo -n "$fg[blue]"
  echo "Updating $pull_branch…"
  echo "$reset_color"

  git checkout $pull_branch
  git pull

  # Prune dead branches
  echo "$fg[blue]"
  echo "Pruning branches…"
  echo "$reset_color"

  git fetch --prune

  # Delete merged branches
  echo "$fg[blue]"
  echo "Deleting merged branches…"
  echo "$reset_color"

  for mergedBranch in $(git for-each-ref --format '%(refname:short)' --merged HEAD refs/heads | egrep --invert-match "$pull_branch")
  do
    echo -n "$fg[yellow]"
    echo -n "✗ "
    git branch -d ${mergedBranch}
    echo -n "$reset_color"
  done

  # Reset working directory
  if [ "$stashed_changes" != "No local changes to save" ]; then
    echo "$fg[blue]"
    echo "Restoring stashed changes…"
    echo "$reset_color"
    git stash pop
  fi

  # Switch back to original branch if still exists
  git rev-parse --verify --quiet $original_branch > /dev/null
  return_to_original_branch=$?
  [[ $return_to_original_branch == 0 ]] && git checkout $original_branch

  echo "$fg[green]"
  echo "✓ Pulled from $pull_branch and deleted merged branches"
  [[ $return_to_original_branch != 0 ]] && echo "↳ Switched to $pull_branch branch ($original_branch deleted)"
  echo -n "$reset_color"
}


# ------------------------------------------------------------------------------
# Auto-Completion
# ------------------------------------------------------------------------------
# TODO: Figure out how to properly define these in a _branch-manager #compdef file

# Copied from git-flow plugin
# See https://github.com/ohmyzsh/ohmyzsh/blob/21b385e7bd522983642b52b51db5d4a210a77717/plugins/git-flow/git-flow.plugin.zsh#L351-L359
_branch-manager-git-branch-names () {
  local expl
  declare -a branch_names

  branch_names=(${${(f)"$(_call_program branchrefs git for-each-ref --format='"%(refname)"' refs/heads 2>/dev/null)"}#refs/heads/})
  __git_command_successful || return

  _wanted branch-names expl branch-name compadd $* - $branch_names
}

_branch-manager () {
  _arguments ':branch:_branch-manager-git-branch-names'
}

compdef _branch-manager update_branch merge_branch rebase_branch pull_and_prune
