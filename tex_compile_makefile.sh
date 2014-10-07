#!/bin/bash
set -o errexit
set -o nounset
#set -o xtrace
PROGNAME=$(basename $0)
die () {
  echo "${PROGNAME}: ${1:-"Unknown Error, Abort."}" 1>&2
  exit 1
}
# dir of script folder
DIR=$( cd "$( dirname "$0" )" && pwd )
USAGE="Usage: $0 <path-to-main.tex> <other make options -j2 -B>"
if [ "$#" -lt 1 ]; then echo $USAGE; exit 1; fi
PDFCMD="pdflatex -shell-escape -interaction=nonstopmode -file-line-error-style"
pdfl () {
  # TODO do I want to pass control to vim suite?
  ${PDFCMD} "${1}" || die "$LINENO: error pdflatex"
}
hasMakeAndFigFile () {
  test -s "${1}.makefile" || die "$LINENO: Something is wrong, ${1}.tex has mode=list and make, but there is no ${1}.makefile"
  sortUniqMakefile "${1}.makefile" || die "$LINENO: error reducing makefile"
  test -s "${1}.figlist" || die "$LINENO: Something is wrong, ${1}.tex has mode=list and make, but there is no ${1}.figlist"
}
sortUniqFiglist () {
  echo 0
}
sortUniqMakefile () {
  # TODO remove duplicate entries in makefile (happens if using 
  # \tikzsetnextfilename
  # prevents warning in makefile
  gawk -i inplace '!_[$0]++' "${1}" || die "$LINENO: error reducing makefile. Do you have gawk 4.1.0 or higher?"
}
firstCompile () {
  pdfl "${1}"
}
texMain="$(basename ${1})"
dir="${1%$texMain}"
shift
if [ -z "${dir}" ]; then dir="."; fi
test -d "${dir}" || die "$LINENO: not a directory (${dir})"
test -s "${dir}/${texMain}" \
  || die "$LINENO: Provide valid .tex file (${texMain})"
# check if 'mode=list and make' is present
if [[ $(grep -m1 -P '^[^%]*mode=list and make' "${dir}/${texMain}") ]]; then
  echo candidate
  main=${texMain%.tex}
  test -s "${dir}/${main}.makefile" || firstCompile "${dir}/${texMain}" \
    || die "$LINENO: first compile failed"
  hasMakeAndFigFile "${dir}/${main}" || die "$LINENO: some files were not found"
# http://tex.stackexchange.com/questions/145501/integrating-latexmk-and-tikz-external-mode-list-and-make
  make -n -C "${dir}" "$@" -f "${main}.makefile" > /dev/null\
    | grep ${PDFCMD} > /dev/null || (echo ok > /dev/null)
  if [[ ${PIPESTATUS[0]} -eq 0 ]] ; then
    make -j -C "${dir}" "$@" -f "${main}.makefile"  \
      || die "$LINENO: make error in ${dir} for makefile ${main}.makefile"
    echo "=================================================================="
  fi
fi
# final compile
cd "${dir}"
pdfl "${texMain}" || die "$LINENO: pdfl failed"
