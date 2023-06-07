#!/bin/zsh

# 1. Homebrew
# List Homebrew formulae
echo "Listing outdated formulae..."
formulae=($(brew outdated  --quiet --formula))

# List Homebrew casks
# Note: It's recommended to set `HOMEBREW_CASK_OPTS=--no-quarantine`, or you will get lots of annoying MacOS prompts
# next time you open a cask after updating (and casks will silently fail to start on login!)
casks_no_upgrade="alfred|docker"  # Can use regex "or" to list multiple, e.g. "alfred|google-cloud-sdk"
echo "Listing outdated casks (except ${casks_no_upgrade})..."
casks=($(brew outdated --quiet --greedy-auto-updates --cask | grep --invert-match -E $casks_no_upgrade))

# Prime the cache (using `brew fetch`) in parallel (using `pueue`)
pueued --daemonize
parallelism=12
pueue group add brew_fetch
pueue parallel $parallelism --group brew_fetch
for formula in ${formulae[@]}; do
    command="brew fetch --formula $formula"
    pueue add --group brew_fetch $command >& /dev/null
done
for cask in ${casks[@]}; do
    command="brew fetch --cask $cask"
    pueue add --group brew_fetch $command >& /dev/null
done

echo "Downloading ${#formulae[@]} formulae and ${#casks[@]} casks with parallelism $parallelism. This may take a while..."
pueue wait --group brew_fetch
pueue log
pueue clean --group brew_fetch
pueue group remove brew_fetch
pueue shutdown

# Upgrade formulae and casks
if [ ${#formulae[@]} -eq 0 ]; then
    echo "No formulae to upgrade."
else
    echo "Upgrading ${#formulae[@]} formulae..."
    brew upgrade --formula --ignore-pinned $formulae
fi
if [ ${#casks[@]} -eq 0 ]; then
    echo "No casks to upgrade."
else
    echo "Upgrading ${#casks[@]} casks..."
    brew upgrade --cask --greedy-auto-updates $casks
fi

# 2. asdf version manager plugins
echo "Updating asdf plugins..."
asdf plugin-update --all

# 3. Mac App Store
mas upgrade