#!/bin/zsh

sudo -v  # ask for password once up front (or cache it)


# 1. Formulae
echo "Upgrading formulae..."
brew upgrade --formula --ignore-pinned

# 2. Casks
# Note: It's recommended to set `HOMEBREW_CASK_OPTS=--no-quarantine`, or you will get lots of annoying MacOS prompts
# next time you open a cask after updating (and casks will silently fail to start on login!)
sudo -v  # cache sudo
casks_no_upgrade="alfred"  # Can use regex "or" to list multiple, e.g. "alfred|google-cloud-sdk"
echo "Upgrading casks (except ${casks_no_upgrade})..."

list=$(brew outdated --greedy-auto-updates --cask --quiet | grep --invert-match -E $casks_no_upgrade)

if [ -n "${list}" ]
then
	brew upgrade $list --greedy-auto-updates --cask --quiet
else
	echo "No casks to upgrade"
fi

# 3. Poetry
poetry self update

# 4. asdf version manager plugins
echo "Updating asdf plugins..."
asdf plugin-update --all