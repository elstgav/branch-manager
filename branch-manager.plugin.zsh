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

  # Merge from master if no argument given
  [[ -z "$1" ]] && other_branch="master" || other_branch=$1

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

  # Rebase from master if no argument given
  [[ -z "$1" ]] && other_branch="master" || other_branch=$1

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
