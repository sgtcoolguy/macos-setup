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
    # Have it use the osxkeychain for credentials
    git config --global credential.helper osxkeychain
    # Automatically rebase on pull instead of generating a merge commit
    git config --global pull.rebase true
    # Automatically stash/unstash working changes on rebase
    git config --global rebase.autoStash true
fi

# Install VSCode
if ! which code ; then
    brew cask install visual-studio-code
fi

# Grab user's full name for git/gpg
fullname=$(id -F)

# Set up git
git_user_name=$(git config --global --get user.name)
RESULT=$?
if [ $RESULT -ne 0 ]; then
  git_user_name=$fullname
  git config --global user.name "$fullname"
fi

git_email=$(git config --global --get user.email)
RESULT=$?
if [ $RESULT -ne 0 ]; then
  echo "What is your verified email address asociated with Github?"
  read git_email
  git config --global user.email "$git_email"
fi

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
if [ ! -d $HOME/.gnupg ]; then
    mkdir $HOME/.gnupg
fi
# create agent config
if [ ! -f $HOME/.gnupg/gpg-agent.conf ]; then
    cat >$HOME/.gnupg/gpg-agent.conf <<EOF
default-cache-ttl 3600

# Connects gpg-agent to the OSX keychain via the brew-installed
# pinentry program from GPGtools. This is the OSX 'magic sauce',
# allowing the gpg key's passphrase to be stored in the login
# keychain, enabling automatic key signing.
pinentry-program /usr/local/bin/pinentry-mac
EOF
fi
# create gpg config
if [ ! -f $HOME/.gnupg/gpg.conf ]; then
    cat >$HOME/.gnupg/gpg.conf <<EOF
use-agent
keyserver hkp://keys.gnupg.net
EOF
fi
# fix permissions on the folder
chmod 700 $HOME/.gnupg

# Set up tty for gpg
if [ -z "$GPG_TTY" ]; then
    export GPG_TTY="tty"

    # TODO: Look at SHELL env var to choose?
    if [ -f $HOME/.zshrc ]; then
        echo '\nexport GPG_TTY="tty"\n' >> $HOME/.zshrc
    elif [ -f $HOME/.bashrc ]; then
        echo '\nexport GPG_TTY="tty"\n' >> $HOME/.bashrc
    else
        echo 'Unknown shell. Please add GPG_TTY="tty" to your shell startup script'
    fi
fi

# Generate key
if [ ! -f $HOME/.gnupg/pubring.kbx ]; then
    cat >gen-key-script <<EOF
Key-Type: 1
Key-Length: 4096
Subkey-Type: 1
Subkey-Length: 4096
Name-Real: $fullname
Name-Email: $git_email
Expire-Date: 0
EOF
    gpg --batch --gen-key gen-key-script
    rm gen-key-script
fi

# Grab key id (use existing one in git config if set)
key_id=$(git config --global --get user.signingkey)
RESULT=$?
if [ $RESULT -ne 0 ]; then
  key_id=$(gpg -K --keyid-format SHORT | grep 'sec' | cut -d ' ' -f4 | cut -d '/' -f2)
  git config --global user.signingkey $key_id
fi

gpg --armor --export $key_id > gpg-key.txt
echo "\x1B[31m---> Go to \x1B[4m\x1B[34mhttps://github.com/settings/keys\x1B[0m, \x1B[1mNew GPG Key\x1B[0m and paste contents of \x1B[92m$PWD/gpg-key.txt\x1B[0m"
# Tell git to sign and what key to use
git config --global commit.gpgsign true

# start gpg-agent
#gpg-agent --daemon # should already be running

# Install node/npm
if ! which node ; then
    brew install nvm
    nvm install 10
fi

# Install 'hub' cli
if ! which hub ; then
    brew install hub
fi

# Install Android SDK
if [ ! -d /usr/local/share/android-sdk ]; then
    brew cask install android-sdk

    export ANDROID_SDK_ROOT="/usr/local/share/android-sdk"
    export ANDROID_SDK="/usr/local/share/android-sdk"
    export ANDROID_HOME="/usr/local/share/android-sdk"

    # TODO: Look at SHELL env var to choose?
    if [ -f $HOME/.zshrc ]; then
        echo '\nexport ANDROID_SDK_ROOT="/usr/local/share/android-sdk"\nANDROID_SDK=\$ANDROID_SDK_ROOT\nANDROID_HOME=\$ANDROID_SDK_ROOT\n' >> $HOME/.zshrc
    elif [ -f $HOME/.bashrc ]; then
        echo '\nexport ANDROID_SDK_ROOT="/usr/local/share/android-sdk"\nANDROID_SDK=\$ANDROID_SDK_ROOT\nANDROID_HOME=\$ANDROID_SDK_ROOT\n' >> $HOME/.bashrc
    else
        echo 'Unknown shell. Please add ANDROID_SDK_ROOT="/usr/local/share/android-sdk\nANDROID_NDK=\$ANDROID_NDK_HOME\nANDROID_HOME=\$ANDROID_SDK_ROOT\n" to your shell startup script'
    fi

    # Install some components!
    yes | /usr/local/bin/sdkmanager "build-tools;28.0.2" "platform-tools" "emulator" "platforms;android-28" "system-images;android-28;google_apis;x86"
    # Set up an emulator
    echo | /usr/local/bin/avdmanager create avd -n "android-28-x86" -k "system-images;android-28;google_apis;x86" -c "512M"
fi

# Install Android NDK
if [ ! -d /usr/local/share/android-ndk ]; then
    brew cask install android-ndk
    export ANDROID_NDK_HOME="/usr/local/share/android-ndk"
    export ANDROID_NDK="/usr/local/share/android-ndk"

    # TODO: Look at SHELL env var to choose?
    if [ -f $HOME/.zshrc ]; then
        echo '\nexport ANDROID_NDK_HOME="/usr/local/share/android-ndk"\nANDROID_NDK=\$ANDROID_NDK_HOME\n' >> $HOME/.zshrc
    elif [ -f $HOME/.bashrc ]; then
        echo '\nexport ANDROID_NDK_HOME="/usr/local/share/android-ndk"\nANDROID_NDK=\$ANDROID_NDK_HOME\n' >> $HOME/.bashrc
    else
        echo 'Unknown shell. Please add ANDROID_NDK_HOME="/usr/local/share/android-ndk\nANDROID_NDK=\$ANDROID_NDK_HOME" to your shell startup script'
    fi
fi