# branch-manager
oh-my-zsh plugin for managing branches

Adds the `update_branch` and `merge_branch` commands to your shell. Both of these will let you update or merge changes while preserving your current workspace.


## Installation

`branch-manager` is built to work with [oh-my-zsh](https://github.com/robbyrussell/oh-my-zsh/), so you’ll need that installed first.

1. `$ cd ~/.oh-my-zsh/custom/plugins` (you may have to create the folder)
2. `$ git clone git@github.com:elstgav/branch-manager.git`
3. In your .zshrc, add `branch-manager` to your oh-my-zsh plugins:
   
  ```bash 
  plugins(rails git branch-manager)
  ```
