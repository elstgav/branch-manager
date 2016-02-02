# Updates a branch and returns you to your workspace
function update_branch {
  [[ -z "$1" ]] && other_branch=$(git rev-parse --abbrev-ref HEAD) || other_branch=$1
  current_branch=$(git rev-parse --abbrev-ref HEAD)
  stashed_changes=$(git stash)
  git checkout $other_branch
  git pull
  git checkout $current_branch

  # Reset working directory
  if [ "$stashed_changes" != "No local changes to save" ]; then
    git stash pop
  else
    echo "No stash to pop"
  fi
}


# Merges a branch into your own while preserving your workspace
function merge_branch {
  [[ -z "$1" ]] && other_branch="master" || other_branch=$1
  branch=$(git rev-parse --abbrev-ref HEAD)
  stashy=$(git stash)
  git checkout $other_branch
  git pull
  git checkout $branch
  git merge $other_branch --no-edit
  if [ "$stashy" != "No local changes to save" ]; then
    git stash pop
  else
    echo "No stash to pop"
  fi
}
