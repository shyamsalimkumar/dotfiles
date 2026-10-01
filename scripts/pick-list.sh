# shellcheck shell=bash
# Lists "$@" as a numbered menu and sets PICKED to the 0-based indexes the
# user chose ("a" picks everything, Enter picks nothing).
pick_from_list() {
  local items=("$@") i pick picks
  PICKED=()
  for i in "${!items[@]}"; do
    printf "  %2d) %s\n" $((i + 1)) "${items[$i]}"
  done
  read -rp "  Numbers to update, separated by spaces (a for all, Enter for none): " -a picks
  if [[ "${picks[0]:-}" == "a" ]]; then
    PICKED=("${!items[@]}")
    return
  fi
  for pick in ${picks[@]+"${picks[@]}"}; do
    if [[ "$pick" =~ ^[0-9]+$ && "$pick" -ge 1 && "$pick" -le ${#items[@]} ]]; then
      PICKED+=($((pick - 1)))
    else
      echo "  Skipping '$pick' - not a number from the list"
    fi
  done
}
