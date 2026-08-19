# Shared output style for the repo's scripts; sourced, not executed.
# Colours only when stderr is a terminal, to keep escape codes out of the journal.
if [ -t 2 ]; then
  _ui_b=$'\e[1m' _ui_d=$'\e[2m' _ui_c=$'\e[36m'
  _ui_g=$'\e[32m' _ui_y=$'\e[33m' _ui_r=$'\e[31m' _ui_0=$'\e[0m'
else
  _ui_b= _ui_d= _ui_c= _ui_g= _ui_y= _ui_r= _ui_0=
fi

ui_head() { printf '\n%s\n' "${_ui_c}${_ui_b}▌ $*${_ui_0}" >&2; }
ui_info() { printf '    %s\n' "$*" >&2; }
ui_ok()   { printf '    %s\n' "$*" >&2; }
ui_warn() { printf '  %s %s\n' "${_ui_y}!${_ui_0}" "$*" >&2; }
ui_err()  { printf '  %s %s\n' "${_ui_r}✗${_ui_0}" "$*" >&2; }

# Single line that redraws in place; only on a terminal, so the journal keeps
# one line per step instead of a stream of carriage returns.
ui_step() {
  if [ -t 2 ]; then printf '\r\e[2K    %s' "$*" >&2; else printf '    %s\n' "$*" >&2; fi
}
ui_step_end() { [ -t 2 ] && printf '\r\e[2K' >&2 || true; }
