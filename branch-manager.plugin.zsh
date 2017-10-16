# Updates a branch and returns you to your workspace
function update_branch {
  current_branch=$(git symbolic-ref --short HEAD)
  stashed_changes=$(git stash)
  gitdir="$(git rev-parse --git-dir)"
  hook="$gitdir/hooks/post-checkout"

  # Update the current branch if no argument given
  [[ -z "$1" ]] && other_branch=$current_branch || other_branch=$1

  # disable post-checkout hook temporarily
  [ -x $hook ] && chmod -x $hook

  # Update the requested branch
  echo "Updating $other_branch…\n"
  git checkout $other_branch
  git pull

  # If we updated the current branch, then we should run post-checkout hook
  if [[ $other_branch == $current_branch ]]; then
    chmod +x $hook
  fi

  # Return to current branch
  git checkout $current_branch

  # Re-enable hook
  chmod +x $hook

  # Reset working directory
  if [ "$stashed_changes" != "No local changes to save" ]; then
    git stash pop
  else
    echo "No stash to pop"
  fi

  echo "$fg[green]"
  echo "✓ Succesfully updated $other_branch"
  echo "$reset_color"
}


# Merges a branch into your own while preserving your workspace
function merge_branch {
  current_branch=$(git symbolic-ref --short HEAD)
  stashed_changes=$(git stash)
  gitdir="$(git rev-parse --git-dir)"
  hook="$gitdir/hooks/post-checkout"

  # Merge from master if no argument given
  [[ -z "$1" ]] && other_branch="master" || other_branch=$1

  # disable post-checkout hook temporarily
  [ -x $hook ] && chmod -x $hook

  # Update the requested branch
  echo "Updating $other_branch…\n"
  git checkout $other_branch
  git pull

  # Return to current branch
  git checkout $current_branch

  # Re-enable hook
  chmod +x $hook

  # Merge changes
  git merge $other_branch --no-edit

  # Reset working directory
  if [ "$stashed_changes" != "No local changes to save" ]; then
    git stash pop
  else
    echo "No stash to pop"
  fi

  echo "$fg[green]"
  echo "✓ Succesfully merged $other_branch into $current_branch"
  echo "$reset_color"
}

# Rebases a branch into your own while preserving your workspace
function rebase_branch {
  current_branch=$(git symbolic-ref --short HEAD)
  stashed_changes=$(git stash)
  gitdir="$(git rev-parse --git-dir)"
  hook="$gitdir/hooks/post-checkout"

  # Rebase from master if no argument given
  [[ -z "$1" ]] && other_branch="master" || other_branch=$1

  # disable post-checkout hook temporarily
  [ -x $hook ] && chmod -x $hook

  # Update the requested branch
  echo "Updating $other_branch…\n"
  git checkout $other_branch
  git pull

  # Return to current branch
  git checkout $current_branch

  # Re-enable hook
  chmod +x $hook

  # Merge changes
  git rebase $other_branch

  # Reset working directory
  if [ "$stashed_changes" != "No local changes to save" ]; then
    git stash pop
  else
    echo "No stash to pop"
  fi

  echo "$fg[green]"
  echo "✓ Succesfully rebased $current_branch onto $other_branch"
  echo "$reset_color"
}
