#!/bin/sh

# Show hidden files
defaults write com.apple.finder AppleShowAllFiles YES

# Install Homebrew
/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

# Install wget
brew install wget

# Install VSCode
brew cask install visual-studio-code

# Set up git
echo Hello, what git username should we use?
read user
git config --global user.name "$user"
echo What git email address should we use?
read email
git config --global user.email "$email"
# Set VSCode as git's editor
git config --global core.editor "code --wait"

# Set up gpgp for git?