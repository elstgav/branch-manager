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

# Pull a branch, and safely delete any dead/merged branches
function pull_and_prune {
  stashed_changes=$(git stash -u)

  # Pull from master if no argument given
  [[ -z "$1" ]] && master_branch="master" || master_branch=$1

  # Update the requested branch
  echo -n "$fg[blue]"
  echo "Updating $master_branch…"
  echo "$reset_color"

  git checkout $master_branch
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

  for mergedBranch in $(git for-each-ref --format '%(refname:short)' --merged HEAD refs/heads | egrep --invert-match 'master|$master_branch')
  do
    echo -n "$fg[red]"
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

  echo "$fg[green]"
  echo "✓ Pulled from $master_branch and deleted merged branches"
  echo -n "$reset_color"
}
