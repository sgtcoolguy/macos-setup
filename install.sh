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
echo "Hello, what is your full name (i.e. John Doe)?"
read fullname
git config --global user.name "$fullname"
echo "What is your verified email address asociated with Github?"
read email
git config --global user.email "$email"
# Set VSCode as git's editor
git config --global core.editor "code --wait"

# TODO: Set up SSH keys!

# Set up gpg for git
# https://gist.github.com/troyfontaine/18c9146295168ee9ca2b30c00bd1b41e
# install gpg/pinentry
if [ ! -f /usr/local/bin/gpg ]; then
    brew install gnupg pinentry-mac
    # Tell git to use gpg to sign
    git config --global gpg.program gpg
fi
# make home dir
if [ ! -f ~/.gnupg ]; then
    mkdir ~/.gnupg
fi
# create agent config
if [ ! -f ~/.gnupg/gpg-agent.conf ]; then
    cat >~/.gnupg/gpg-agent.conf <<EOF
default-cache-ttl 3600

# Connects gpg-agent to the OSX keychain via the brew-installed
# pinentry program from GPGtools. This is the OSX 'magic sauce',
# allowing the gpg key's passphrase to be stored in the login
# keychain, enabling automatic key signing.
pinentry-program /usr/local/bin/pinentry-mac
EOF
fi
# create gpg config
if [ ! -f ~/.gnupg/gpg.conf ]; then
    cat >~/.gnupg/gpg.conf <<EOF
use-agent
keyserver hkp://keys.gnupg.net
EOF
fi
# fix permissions on the folder
chmod 700 ~/.gnupg

# Set up tty for gpg
if [[ ! -v GPG_TTY ]] then
    export GPG_TTY="tty"

    # TODO: Look at SHELL env var to choose?
    if [ -f ~/.zshrc ]; then
        echo '\nexport GPG_TTY="tty"\n' >> ~/.zshrc
    elif [ -f ~/.bashrc ]; then
        echo '\nexport GPG_TTY="tty"\n' >> ~/.bashrc
    fi
fi

# Generate key
if [ ! -f ~/.gnupg/pubring.kbx ]; then
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
fi

# Grab key id
# TODO: Guard by checking if git config value for user.signkey is already set?
key_id=$(gpg -K --keyid-format SHORT | grep 'sec' | cut -d ' ' -f4 | cut -d '/' -f2)
gpg --armor --export $key_id > gpg-key.txt
echo "\e[31m---> Go to \e[4m\e[34mhttps://github.com/settings/keys\e[0m, \e[1mNew GPG Key\e[0m and paste contents of \e[92m$PWD/gpg-key.txt"
# Tell git to sign and what key to use
git config --global commit.gpgsign true
git config --global user.signingkey $key_id
# start gpg-agent
#gpg-agent --daemon # should already be running

# Install node/npm
if ! which node ; then
    brew install node
fi