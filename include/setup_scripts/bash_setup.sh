#!/usr/bin/env bash

bashrc_setup() {
        if [[ ! -f ~/.bashrc ]]; then
                log_error "No bashrc present on this system"
        fi
        local bashrc="${HOME}/.bashrc"
        local begin="# >>> custom-setup >>>"
        local end="# <<< custom-setup <<<"
        local block
        block="$(cat <<'EOF'
# >>> custom-setup >>>
# Only run the rest for interactive shells. Sourcing tmux/PS1 logic in a
# non-interactive shell (scp, rsync, automation) can hang or break transfers.
case "$-" in
    *i*) ;;     # interactive: continue
    *)   return 0 2>/dev/null || true ;;  # non-interactive: stop here
esac

if command -v tmux >/dev/null 2>&1 && [ -z "${TMUX:-}" ] && [ -t 1 ]; then
    if tmux has-session 2>/dev/null; then
        exec tmux attach-session
    else
        exec tmux new-session
    fi
fi

# Source Rust/cargo environment only if it's actually installed.
if [ -f "$HOME/.cargo/env" ]; then
    . "$HOME/.cargo/env"
fi

# Show the current git branch in the prompt (empty when not in a repo).
git_branch() {
    local branch
    branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
    if [ -n "$branch" ]; then
        printf '(%s)' "$branch"
    fi
}

# Prompt with chroot indicator, colored user@host:cwd, and git branch.
PS1='${debian_chroot:+($debian_chroot)}\[\e]0;\u@\h: \w\007\]\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\[\033[38;5;3m\]$(git_branch)\[\033[00m\]\$ '
# <<< custom-setup <<<
EOF
)"

        # Remove any previous managed block, then append the fresh one.
        # Using a temp file + atomic mv to avoid a half-written ~/.bashrc on failure.
        local tmp
        tmp="$(mktemp "${bashrc}.XXXXXX")" || return 1

        if grep -qF "$begin" "$bashrc"; then
                # Delete the existing block (inclusive of begin/end markers).
                sed "/^${begin}$/,/^${end}$/d" "$bashrc" > "$tmp" || { rm -f "$tmp"; return 1; }
        else
                cp "$bashrc" "$tmp" || { rm -f "$tmp"; return 1; }
        fi

        printf '\n%s\n' "$block" >> "$tmp" || { rm -f "$tmp"; return 1; }
        mv "$tmp" "$bashrc" || { rm -f "$tmp"; return 1; }
        log_success "Bashrc has been configured"
}

nvim_config() {
        # Install latest nvim
        wget https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz
        tar -xvf nvim-linux-x86_64.tar.gz
        sudo cp -r nvim-linux-x86_64/* /usr/
        sudo rm -rf nvim-linux-x86_6*

        cp -r ./include/nvim-config ~/.config/nvim
        cp -r ./include/nvim-local ~/.local/share/nvim

        # This is the font I like to use for nvim
        if [[ -d AnonymousPro ]]; then
                log_warning "Found AnonymousPro dir, it should not exist"
                rm -rf AnonymousPro
        fi
        mkdir AnonymousPro
        (cd AnonymousPro || log_error "Failed to create AnonymousPro dir"
        wget https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/AnonymousPro.zip
        unzip AnonymousPro.zip 
        rm -rf AnonymousPro.zip OFL.txt README.md )

        [ ! -d ~/.fonts/ ] && mkdir ~/.fonts/
        [ -d ~/.fonts/AnonymousPro ] && rm -rf ~/.fonts/AnonymousPro
        mv AnonymousPro/ ~/.fonts/
        
        [[ -d ~/.config/alacritty-old ]] && rm -rf ~/.config/alacritty-old
        [[ -d ~/.config/alacritty ]] && mv ~/.config/alacritty ~/.config/alacritty-old
        cp -r ./include/alacritty/ ~/.config/

        log_info "I always set my terminal to alacrity, but if you like the default or another, select as you please"
        sudo update-alternatives --config x-terminal-emulator
        # If the user does select alacrity I will set the CTRL+ALT+T for them
        if [[ "$(readlink -f /etc/alternatives/x-terminal-emulator)" == "$(command -v alacritty)" ]]; then
                # Disable GNOME's built-in Ctrl+Alt+T so it won't conflict
                gsettings set org.gnome.settings-daemon.plugins.media-keys terminal "[]"

                # Define a custom keybinding in slot custom0
                key="org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"
                # Set the binding
                gsettings set "$key" name 'Alacritty'
                gsettings set "$key" command "$(command -v alacritty)"   # full path is safest
                gsettings set "$key" binding '<Control><Alt>t'

                # Register the slot in the list of custom keybindings
                gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings \
                "['/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/']"
        fi
        log_success "Neovim has been installed correctly"
}

color_setup() {
        # Set the terminal color
        dconf load /org/gnome/ < ./include/gnome-profile.dconf

        # Terminal color preferences
        # This is a subshell, I wont have to cd .. as a result
        ( cd ./include/synth-shell || log_error "Failed to fetch synth shell, please run ./include/scripts/grefresh"
        ./setup.sh )

        # Tmux color scheme
        [[ ! -d ~/.tmux ]] && mkdir -p ~/.tmux
        cp -r ./include/tmux/themes/ ~/.tmux/
        cp ./include/tmux/tmux.conf ~/.tmux.conf

        log_success "New color scheme added"
}

setup_scripts() {
        if [[ -d /opt/scripts ]]; then
                log_warning "/opt/scripts already exists, skipping setup_scripts function"
                return 0
        fi
        sudo mkdir /opt/scripts
        sudo chown -R "$USER":"$USER" /opt/scripts
        sudo cp ./include/scripts/* /opt/scripts

        SOURCE_DIR="/opt/scripts"
        DEST_DIR="/usr/local/bin"

        # Check if dirs
        [[ ! -d "$SOURCE_DIR" ]] && log_error "Source directory $SOURCE_DIR does not exist!"
        # Check if destination directory exists
        [[ ! -d "$DEST_DIR" ]] && log_error "Destination directory $DEST_DIR does not exist!"

        log_info "Creating symbolic links for .sh files from $SOURCE_DIR to $DEST_DIR..."

        # Counter for created links
        created_count=0
        skipped_count=0

        # Find all .sh files in the source directory
        while IFS= read -r -d '' script_file; do
                # Get the basename without the .sh extension
                script_name=$(basename "$script_file" .sh)

                # Define the symbolic link path
                link_path="$DEST_DIR/$script_name"

                # Check if the script is executable
                if [[ ! -x "$script_file" ]]; then
                        log_warning "$script_file is not executable. Making it executable..."
                        chmod +x "$script_file"
                fi

                # Check if symbolic link already exists
                if [[ -L "$link_path" ]]; then
                        # Check if it points to the correct file
                        if [[ "$(readlink "$link_path")" == "$script_file" ]]; then
                                log_info "Symbolic link already exists and is correct: $link_path -> $script_file"
                                skipped_count=$((skipped_count + 1))
                                continue
                        else
                                log_warning "Removing existing symbolic link: $link_path"
                                rm "$link_path"
                        fi
                elif [[ -e "$link_path" ]]; then
                        log_warning "File $link_path already exists and is not a symbolic link. Skipping..."
                        skipped_count=$((skipped_count + 1))
                        continue
                fi

                # Create the symbolic link
                if sudo ln -s "$script_file" "$link_path"; then
                        log_info "Created symbolic link: $link_path -> $script_file"
                        created_count=$((created_count + 1))
                else
                        log_error_no_exit "Failed to create symbolic link: $link_path"
                fi

        done < <(find "$SOURCE_DIR" -maxdepth 1 -name "*.sh" -type f -print0)

        # Print summary
        log_info "Summary:"
        log_info "Created: $created_count symbolic links"
        log_info "Skipped: $skipped_count files"

        log_success "Script completed successfully!"

        if [[ $(uname -a | tr '[:upper:]' '[:lower:]') == *virtual* ]]; then
                sudo ln -s /opt/scripts/mount-vm.sh /usr/bin/mount-vm
        else
                sudo rm /opt/scripts/mount-vm.sh
        fi
        log_success "Scripts have been created"
}
