#!bin/sh -e

export HOME="${HOME:-/tmp}"
export TMPDIR="${TMPDIR:-/tmp}"

export DISPLAY=
unset DISPLAY

export SAL_NO_X11=1
export SAL_USE_VCLPLUGIN=svp
export LIBGL_ALWAYS_SOFTWARE=1

export OOO_DISABLE_RECOVERY=1
export OOO_EXIT_POST_STARTUP=1

export SAL_NO_NWF=1

exec /usr/lib/libreoffice/program/soffice.bin \
  --headless \
  --invisible \
  --nocrashreport \
  --nodefault \
  --nofirststartwizard \
  --nologo \
  --norestore \
  --nolockcheck \
  "@"
