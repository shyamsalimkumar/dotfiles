# shellcheck shell=bash
# Shows "$@" as a checklist and sets PICKED to the 0-based indexes the user
# ticked. Plain bash (3.2-safe) since setup-brew.sh runs before Nix exists.
pick_from_list() {
  local items=("$@") chosen=() cursor=0 i key rest pointer box all
  # Long lines would wrap and throw off the redraw, so cut them to fit.
  local cols
  cols="$(stty size 2>/dev/null | cut -d' ' -f2 || true)"
  local width=$((${cols:-80} - 9))
  for i in "${!items[@]}"; do chosen[i]=false; done
  PICKED=()

  echo "  ↑/↓ to move, space to tick, a to tick all, enter to confirm"
  printf '\033[?25l'
  trap 'printf "\033[?25h"; exit 130' INT
  while true; do
    for i in "${!items[@]}"; do
      pointer=" "
      box="[ ]"
      if [[ $i -eq $cursor ]]; then pointer=">"; fi
      if [[ ${chosen[i]} == true ]]; then box="[x]"; fi
      printf '\033[2K  %s %s %.*s\n' "$pointer" "$box" "$width" "${items[$i]}"
    done

    IFS= read -rsn1 key || break
    case "$key" in
      $'\033')
        IFS= read -rsn2 rest || true
        case "$rest" in
          "[A") if [[ $cursor -gt 0 ]]; then cursor=$((cursor - 1)); fi ;;
          "[B") if [[ $cursor -lt $((${#items[@]} - 1)) ]]; then cursor=$((cursor + 1)); fi ;;
        esac
        ;;
      k) if [[ $cursor -gt 0 ]]; then cursor=$((cursor - 1)); fi ;;
      j) if [[ $cursor -lt $((${#items[@]} - 1)) ]]; then cursor=$((cursor + 1)); fi ;;
      " ") if [[ ${chosen[cursor]} == true ]]; then chosen[cursor]=false; else chosen[cursor]=true; fi ;;
      a)
        all=true
        for i in "${!items[@]}"; do [[ ${chosen[i]} == true ]] || all=false; done
        for i in "${!items[@]}"; do if [[ $all == true ]]; then chosen[i]=false; else chosen[i]=true; fi; done
        ;;
      "") break ;;
    esac
    printf '\033[%dA' "${#items[@]}"
  done
  printf '\033[?25h'
  trap - INT

  for i in "${!items[@]}"; do
    if [[ ${chosen[i]} == true ]]; then PICKED+=("$i"); fi
  done
}
