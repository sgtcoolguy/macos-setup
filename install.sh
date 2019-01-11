#!/bin/sh

# Show hidden files
defaults write com.apple.finder AppleShowAllFiles YES

# Install Homebrew
if [ ! -f /usr/local/bin/brew ]; then
   /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
fi

# Install wget
if [ ! -f /usr/local/bin/wget ]; then
    brew install wget
fi

# Install git
if [ ! -f /usr/local/bin/git ]; then
    brew install git
fi

# Install VSCode
if ! which code ; then
    brew cask install visual-studio-code
fi

# Set up git
echo Hello, what is your full name (i.e. John Doe)?
read fullname
git config --global user.name "$fullname"
echo What is your verified email address asociated with Github?
read email
git config --global user.email "$email"
# Set VSCode as git's editor
git config --global core.editor "code --wait"

# Set up gpgp for git?
# https://gist.github.com/troyfontaine/18c9146295168ee9ca2b30c00bd1b41e
brew install gnupg pinentry-mac
mkdir ~/.gnupg
cat >~/.gnupg/gpg-agent.conf <<EOF
# Enables GPG to find gpg-agent
use-standard-socket

default-cache-ttl 3600

# Connects gpg-agent to the OSX keychain via the brew-installed
# pinentry program from GPGtools. This is the OSX 'magic sauce',
# allowing the gpg key's passphrase to be stored in the login
# keychain, enabling automatic key signing.
pinentry-program /usr/local/bin/pinentry-mac
EOF
cat >~/.gnupg/gpg.conf <<EOF
use-agent
keyserver hkp://keys.gnupg.net
EOF
# Set up tty for gpg
export GPG_TTY="tty"
if [ -f ~/.zshrc ]; then
    echo '\nexport GPG_TTY="tty"\n' >> ~/.zshrc
elif [ -f ~/.bashrc ]; then
    echo '\nexport GPG_TTY="tty"\n' >> ~/.bashrc
fi

# Generate key
cat >gen-key-script <<EOF
Key-Type: 1
Key-Length: 4096
Subkey-Type: 1
Subkey-Length: 4096
Name-Real: $fullname
Name-Email: $email
Expire-Date: 0
EOF
gpg --batch --gen-key gen-key-script
# fix permissions on the folder
chmod 700 ~/.gnupg

key_id=$(gpg -K --keyid-format SHORT | grep 'sec' | cut -d ' ' -f4 | cut -d '/' -f2)
gpg --armor --export $key_id > gpg-key.txt
echo Go to https://github.com/settings/keys to upload contents of $pwd/gpg-key.txt
# Tell git to sign and how
git config --global gpg.program gpg
git config --global commit.gpgsign true
git config --global user.signingkey $key_id
# start gpg-agent
gpg-agent --daemon