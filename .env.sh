export FZF_DEFAULT_COMMAND="fd --color=never --exclude={anaconda,anaconda3,Library,Qt,.git,.idea,.vscode,.sass-cache,node_modules,build,cmake-build-debug,venv,Dictionaries,Qt5.12.2,repo} "
export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border --prompt '>>>' \
    --bind 'alt-j:preview-down,alt-k:preview-up,alt-v:execute(vi {})+abort,ctrl-y:execute-silent(cat {} | pbcopy)+abort,?:toggle-preview' \
    --header 'A-j/k: preview down/up, A-v: open in vim, C-y: copy, ?: toggle preview' \
    --preview 'highlight -O ansi {} || cat {} 2> /dev/null | head -500'"
export FZF_CTRL_T_OPTS=$FZF_DEFAULT_OPTS
export FZF_CTRL_R_OPTS="--preview 'echo {}' --preview-window hidden:wrap --bind '?:toggle-preview'"
export FZF_ALT_C_OPTS="--height 40% --reverse --border --prompt '>>>' \
    --bind 'alt-j:preview-down,alt-k:preview-up,?:toggle-preview' \
    --header 'A-j/k: preview down/up, A-v: open in vim, C-y: copy, ?: toggle preview' \
    --preview 'exa -T {}'"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND="fd --type d --color=never"
set -U FZF_LEGACY_KEYBINDINGS 0
set -U FZF_COMPLETE 3

