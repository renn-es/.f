# ========================= #
#  Variables and functions  #
# ========================= #

# Set some variables just in case
export XDG_DATA_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}"
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-${HOME}/.config}"
export XDG_CACHE_HOME="$HOME/.cache"

__pathadd() {
    export PATH="$1:$PATH"
}

__pathadd $HOME/.local/bin
__pathadd $HOME/.cargo/bin

# Switch to emacs mode instead of vi mode
bindkey -e

# ==================== #
#    Plugin manager    #
# ==================== #

# Zinit
ZINIT_HOME="${XDG_DATA_HOME}/zinit/zinit"

[ ! -d $ZINIT_HOME ] && mkdir -p "$(dirname $ZINIT_HOME)"
[ ! -d $ZINIT_HOME/.git ] && echo "Installing zinit..." && git clone https://github.com/zdharma-continuum/zinit.git --depth=1 "$ZINIT_HOME" > /dev/null 2>&1

source "${ZINIT_HOME}/zinit.zsh"

# ==================== #
#       Plugins        #
# ==================== #

# Syntax highlighting
zinit light zdharma-continuum/fast-syntax-highlighting

# Fish-like history search pt. 1: pressing ↑ will search through history
zinit light zsh-users/zsh-history-substring-search
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down
HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_FOUND=''
HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_NOT_FOUND=''
HISTORY_SUBSTRING_SEARCH_FUZZY='true'

# Fish-like history search pt. 2: the grayed out part
zinit light zsh-users/zsh-autosuggestions
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=8'

# Additions to the default completion system
zinit light zsh-users/zsh-completions

# ==================== #
#     Miscellaneous    #
# ==================== #

# Allow using pgup and pgdown for argument completion
bindkey '^[[5~' insert-last-word # page up
bindkey '^[[6~' backward-kill-word # page down

## History options
HISTSIZE=1000000
SAVEHIST=1000000
HISTFILE=${XDG_DATA_HOME}/zsh_history
setopt HIST_IGNORE_ALL_DUPS
# write to history file after each command
setopt INC_APPEND_HISTORY

## Gray completion based on history
autoload -U compinit
zstyle ":completion:*" menu select
zmodload zsh/complist
compinit
_comp_options+=(globdots) # Include hidden files


# Prevent keeping a block cursor after exiting from nvim.
__reset-cursor() {printf '\033[5 q'}
add-zsh-hook precmd "__reset-cursor"

# Refresh the tmux bar after each command.
__reload-tmux-bar() {tmux refresh-client -S > /dev/null 2>&1}
add-zsh-hook precmd "__reload-tmux-bar"


# =================== #
#       Aliases       #
# =================== #

alias vim="nvim"
alias v="nvim"
alias fm="ranger"

# Add confirmations to potentially harmful commands
alias cp="cp -i"
alias mv="mv -i"
alias rm="rm -i"

alias ls="exa --icons --group-directories-first"
alias ll="ls -l" # Refers to previous alias
alias tree="ls --tree" # Same
alias la="ls -a"
alias lla="ll -a"

alias t="trash"
alias b="bat"

alias grep="grep --color=auto"

alias g="git"
alias ga="git add"
alias gap="git add -p"
alias gc="git commit"
alias gcm="git commit -m"
alias gca="git commit -a"
alias gcam="git commit -am"
alias gp="git push"
alias gs="git status"
alias gl="git log --decorate --oneline --graph"
alias gd="git diff"
alias gb="git branch"
alias gco="git checkout"
alias gr="git restore"
alias grs="git restore --staged"

alias d="docker"
alias dp="docker ps"
alias dc="docker compose"
alias dcu"dc up -d"
alias dcd="dc down"

# Let me use the keys on my keyboard.
bindkey  "^[[H"   beginning-of-line
bindkey  "^[[F"   end-of-line
bindkey  "^[[3~"  delete-char

# =================== #
#       Prompt        #
# =================== #

# Autoload zsh add-zsh-hook and vcs_info functions (-U autoload w/o substition, -z use zsh style)
autoload -Uz add-zsh-hook vcs_info
# Enable substitution in the prompt.
setopt prompt_subst

function _git_symbols() {
	# Symbols
	local ahead='↑'
	local behind='↓'
	local diverged='↕'
	local up_to_date='|'
	local no_remote=''
	local staged='+'
	local untracked='?'
	local modified='!'
	local moved='>'
	local deleted='x'
	local stashed='$'

	local output_symbols=''

	local git_status_v
	git_status_v="$(git status --porcelain=v2 --branch --show-stash 2>/dev/null)"

	# Parse branch information
	local ahead_count behind_count

	# AHEAD, BEHIND, DIVERGED
	if echo $git_status_v | grep -q "^# branch.ab " ; then
		# One line of the git status output looks like this:
		# # branch.ab +1 -2
		# In the line below:
		# - we grep for the line starting with # branch.ab
		# - we grep for the numbers and output them on separate lines
		# - we remove the + and - signs
		# - we put the two numbers into variables, while telling read to use a newline as the delimiter for reading
		read -d "\n" -r ahead_count behind_count <<< $(echo "$git_status_v" | grep "^# branch.ab" | grep -o -E '[+-][0-9]+' | sed 's/[-+]//')
		# Show the ahead and behind symbols when relevant
		[[ $ahead_count != 0 ]] && output_symbols+="$ahead"
		[[ $behind_count != 0 ]] && output_symbols+="$behind"
		# Replace the ahead symbol with the diverged symbol when both ahead and behind
		output_symbols="${output_symbols//$ahead$behind/$diverged}"

		# If the branch is up to date, show the up to date symbol
		[[ $ahead_count == 0 && $behind_count == 0 ]] && output_symbols+="$up_to_date"
	fi


	# STASHED
	echo $git_status_v | grep -q "^# stash " && output_symbols+="$stashed"

	# STAGED
	[[ $(git diff --name-only --cached) ]] && output_symbols+="$staged"

	# For the rest of the symbols, we use the v1 format of git status because it's easier to parse.
	local git_status

	symbols="$(git status --porcelain=v1 | cut -c1-2 | sort | uniq | sed 's/ //g')"

	while IFS= read -r symbol; do
		case $symbol in
			??) output_symbols+="$untracked";;
			M) output_symbols+="$modified";;
			R) output_symbols+="$moved";;
			D) output_symbols+="$deleted";;
		esac
	done <<< "$symbols"

	[[ -n $output_symbols ]] && echo -n " $output_symbols"
}


# Function to display Git status with symbols
function _git_info() {
	local git_info=''
	local git_branch_name=''

	if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
		# Get the Git branch name
		git_branch_name="$(git symbolic-ref --short HEAD 2>/dev/null)"
		if [[ -n "$git_branch_name" ]]; then
			git_info+="ש $git_branch_name"
		fi
		# Get the Git status
		git_info+="$(_git_symbols)"
		echo " [$git_info]"
	fi
}


PROMPT=''
PROMPT+='%F{yellow}%n@%m ' # Display the username followed by @ and hostname in yellow
PROMPT+='%F{blue}%~' # Display the current working directory in blue
PROMPT+='%F{red}$(_git_info)%f ' # Display the vcs info in red
PROMPT+='%(?.%F{green}λ .%F{red}λ )' # Display a green prompt if the last command succeeded, or red if it failed
PROMPT+='%f' # Reset the text color



# =================== #
#      Tmux keys      #
# =================== #

# Without this, tmux will not work well with the HOME and END keys.
# See https://stackoverflow.com/questions/161676/home-end-keys-in-zsh-dont-work-with-putty

if [[ "$TERM" != emacs ]]; then
	[[ -z "$terminfo[kdch1]" ]] || bindkey -M emacs "$terminfo[kdch1]" delete-char
	[[ -z "$terminfo[khome]" ]] || bindkey -M emacs "$terminfo[khome]" beginning-of-line
	[[ -z "$terminfo[kend]" ]]  || bindkey -M emacs "$terminfo[kend]" end-of-line
	[[ -z "$terminfo[kich1]" ]] || bindkey -M emacs "$terminfo[kich1]" overwrite-mode
	[[ -z "$terminfo[kdch1]" ]] || bindkey -M vicmd "$terminfo[kdch1]" vi-delete-char
	[[ -z "$terminfo[khome]" ]] || bindkey -M vicmd "$terminfo[khome]" vi-beginning-of-line
	[[ -z "$terminfo[kend]" ]]  || bindkey -M vicmd "$terminfo[kend]" vi-end-of-line
	[[ -z "$terminfo[kich1]" ]] || bindkey -M vicmd "$terminfo[kich1]" overwrite-mode

	[[ -z "$terminfo[cuu1]" ]]  || bindkey -M viins "$terminfo[cuu1]" vi-up-line-or-history
	[[ -z "$terminfo[cuf1]" ]]  || bindkey -M viins "$terminfo[cuf1]" vi-forward-char
	[[ -z "$terminfo[kcuu1]" ]] || bindkey -M viins "$terminfo[kcuu1]" vi-up-line-or-history
	[[ -z "$terminfo[kcud1]" ]] || bindkey -M viins "$terminfo[kcud1]" vi-down-line-or-history
	[[ -z "$terminfo[kcuf1]" ]] || bindkey -M viins "$terminfo[kcuf1]" vi-forward-char
	[[ -z "$terminfo[kcub1]" ]] || bindkey -M viins "$terminfo[kcub1]" vi-backward-char

	# ncurses fogyatekos
	[[ "$terminfo[kcuu1]" == "^[O"* ]] && bindkey -M viins "${terminfo[kcuu1]/O/[}" vi-up-line-or-history
	[[ "$terminfo[kcud1]" == "^[O"* ]] && bindkey -M viins "${terminfo[kcud1]/O/[}" vi-down-line-or-history
	[[ "$terminfo[kcuf1]" == "^[O"* ]] && bindkey -M viins "${terminfo[kcuf1]/O/[}" vi-forward-char
	[[ "$terminfo[kcub1]" == "^[O"* ]] && bindkey -M viins "${terminfo[kcub1]/O/[}" vi-backward-char
	[[ "$terminfo[khome]" == "^[O"* ]] && bindkey -M viins "${terminfo[khome]/O/[}" beginning-of-line
	[[ "$terminfo[kend]" == "^[O"* ]] && bindkey -M viins "${terminfo[kend]/O/[}" end-of-line
	[[ "$terminfo[khome]" == "^[O"* ]] && bindkey -M emacs "${terminfo[khome]/O/[}" beginning-of-line
	[[ "$terminfo[kend]" == "^[O"* ]] && bindkey -M emacs "${terminfo[kend]/O/[}" end-of-line
fi
