if [[ -n ${ZSH_VERSION-} ]]; then
  autoload -U +X bashcompinit && bashcompinit
fi

_mortar () {
  local cur prev ret
  COMPREPLY=()
  cur="${COMP_WORDS[COMP_CWORD]}"
  prev="${COMP_WORDS[COMP_CWORD-1]}"

  if [ "$COMP_CWORD" = "1" ]; then
    if [[ ${cur} == -* ]] ; then
      COMPREPLY=( $(compgen -W "--help --version" -- ${cur}) )
      return
    fi

    COMPREPLY=( $(compgen -W "fire yank" -- ${cur}) )
    return
  else
    case "${COMP_WORDS[1]}" in
      fire)
        if [[ ${cur} == -* ]] ; then
          COMPREPLY=( $(compgen -W "--var --output --prune --overlay --force --debug --help" -- ${cur}) )
        elif [ "$prev" = "--overlay" ]; then
          if command -v compopt &> /dev/null; then
            COMPREPLY=( $(compgen -d -S "/" -- "${COMP_WORDS[COMP_CWORD]}") )
            compopt -o nospace
          fi
        fi
        ;;
      yank)
        if [[ ${cur} == -* ]] ; then
          COMPREPLY=( $(compgen -W "--force --debug --help" -- ${cur}) )
        fi
        ;;
    esac
  fi
}

complete -o default -F _mortar mortar

