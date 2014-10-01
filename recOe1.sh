#!/bin/bash
URL=http://mp3stream3.apasf.apa.at:8000

# CONFIGURATION: 
TARGET_DIR=${HOME}/oe1
WWW_DIR="/var/www/oe1" # must be owned by executing user
WWW_BASE_URL=
# e.g  WWW_BASE_URL="http://myserver.at/oe1"

PROGNAME=$(basename $0)
die () {
   echo "${PROGNAME}: ${1:-"Unknown Error, Abort."}" 1>&2
   exit 1
}

set -o errexit
set -o nounset

USAGE="Usage: $0 <length in seconds> <name-string (e.g Pasticcio)>"

if [ "$#" -lt 2 ]; then echo $USAGE; exit 1; fi

mkdir -p "${TARGET_DIR}"
dat=$(date  +%Y-%m-%d)
datRec=$(date +%Y_%m_%d)
showTitle="${2}"
NAME="${2}-${dat}"
LEN="${1}"
re='^[0-9]+$'
[[ $LEN =~ $re ]] || die "error: '$LEN' is not an integer"

echo "recording  ${NAME}.mp3 in ${TARGET_DIR}"
echo ""
if [[ -s "${TARGET_DIR}/${NAME}.mp3" ]]; then
  die "$LINENO: ${TARGET_DIR}/${NAME}.mp3 exists already. "
fi

streamripper "${URL}" --quiet -l $LEN -m 20 -d "${TARGET_DIR}" \
  -a "${NAME}.mp3" -A -s -u "winamp" || die "$LINENO: streamripper error"
  
id3tool --set-artist="Oe1" --set-title="${NAME}" --set-year=`date +%Y` \
  --set-album="Radio"  "${TARGET_DIR}/${NAME}.mp3" || echo \
  "id3 tool failed (nevermind)"
  
chmod -w "${TARGET_DIR}/${NAME}.mp3" || echo "chmod failed (nevermind)"

# grep abstract from oe1 page
status=0
wget --quiet "http://oe1.orf.at/programm" --convert-links \
  -O $TARGET_DIR/programm  || status=$?
if [[ $status -ne 0 ]]; then
  echo "${PROGNAME} $LINENO: failed to retrieve today's program (oe1.orf.at/programm)"
else
  show_URI=$(grep -i -E ".*${showTitle}.*" "$TARGET_DIR/programm" \
    | grep -m1 "<h3>" | grep -o 'http:[A-Za-z0-9/\.]*') || echo \
    "${PROGNAME}: $LINENO: No show URL has been found on today's program with name '${showTitle}'. No abstract can be retrieved. Be sure to use a name which allows matching with the titles on 'oe1.orf.at/programm'"
  if ! [ -z "$show_URI" ]; then
    echo "Show URL: ${show_URI}"
    echo ""
    # post output in email
    links -dump $show_URI | sed -e \
      '/^\s*\(Montag\|Dienstag\|Mittwoch\|Donnerstag\|Freitag\|Samstag\|Sonntag\)/,/^\s*back/!d'\
      | tee "${TARGET_DIR}/${NAME}.txt"
    [[ ${PIPESTATUS[0]} -eq 0 ]] || echo "${PROGNAME}: $LINENO: problem generating text output"
  fi
fi

# move to www folder, post link in email (only if the two variables are set)
if ! [ -z "$WWW_DIR" -o -z "$WWW_BASE_URL" ]; then
  cd "${WWW_DIR}"
  ln -f -s "${TARGET_DIR}/${NAME}.mp3" "${NAME}.mp3" || status=$?
  if [[ $status -ne 0 ]]; then
    echo  "failed to link file in ${WWW_DIR}/${NAME}.mp3"
  else
    echo ''
    echo "Download/Listen at ${WWW_BASE_URL}/${NAME}.mp3"
    echo ''
  fi
fi
