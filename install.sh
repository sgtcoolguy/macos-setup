#!/bin/sh

# Show hidden files
defaults write com.apple.finder AppleShowAllFiles YES

# Install Homebrew
/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

# Install wget
brew install wget

# Install VSCode
brew cask install visual-studio-code

# Install git?
# gpg?
