#!/usr/bin/env bash
#
# Cross-compile Go binaries for various architectures or local (by default).
# Takes up to four arguments:
#   `-a [Arch]`: The (Go) name of the system Architecture to compile to
#   `-d [dest]`: The path to the destination directory with source code to build
#   `-o [OS]`: The (Go) name of the Operating System to compile to
#   `-s [src]`: The path to the directory with source code to build
#   `-h`: Print help message and exit (regardless of other arguments)
#

# NOTE: We don't sepcify the PATH variable here; all executables, including
#       `go`, need to be known from the caller's environment.`
declare args="a:d:ho:s:"
declare goarch=""
declare dest="${PWD}"
declare goos=""
declare src="${PWD}/../"
declare -i archset=0
declare -i destset=0
declare -i osset=0
declare -i srcset=0
declare -a oslist=(
    darwin
    mac
    linux
    lnx
    win
    windows
)
declare -a archlist=(
    386
    amd64
    arm
    arm64
)

## Print a usage statement. Note that the caller must handle any exit or error
#  status, as appropriate.
#
function usage {
    local -i idx=0

    printf "usage: ./xbuild.sh <src> <OS> <Arch>\n"
    printf "where: <src> is the the directory of source code to build\n"
    printf "       and <OS> <Arch> are one (each) of:\n"

    for (( idx = 0 ; idx < ${#oslist} ; idx++ )); do
        printf "%23s %s\n" "${oslist[$i]}" "${archlist[$i]}"
    done

    printf "For a list of all OS/Arch combinations, run `go tool dist list`\n"
}

## Print an error message (with usage) and exit with error status.
#
function error {
    local msg="${*}"

    usage
    printf "ERROR: %s\n" "${msg}"

    exit 1
}

## Run the Go cross-compiler on the source directory (`sd`), sending the
#  resultant binary to the final directory (`fd`) comprised of the binary
#  directory path (`bd`)/GOOS/GOARCH/.
#
function gox {
    local sd="${1:-$PWD/..}"
    local bd="${2:-$PWD}"
    local fd="${bd}/${goos}/${goarch}"

    if [[ ! ${oslist[@]} =~ ${goos} ]]; then
        error "unknown Operating System ${goos}"
    elif [[ -z ${goarch} ]] || [[ ! ${archlist[@]} =~ ${goarch} ]]; then
        error "unknown Architecture ${goarch}"
    else
        mkdir -p "${fd}"
    fi

    (cd "${bd}" \
         && env GOOS=${goos} GOARCH=${goarch} go build -o ${fd} -v \
                || error "unable to change to ${bd} directory")
}

## Process command line arguments and start script.
#
while getopts "${optstring}" opt; do
    case ${opt} in
        a) goarch="${OPTARG}"
           (( archset = 1 ))
           ;;
        d) dest="${OPTARG}"
           (( destset = 1 ))
           ;;
        h) usage
           exit 0
           ;;
        o) goos="${OPTARG}"
           (( osset = 1 ))
           ;;
        s) src="${OPTARG}"
           (( srcset = 1 ))
           ;;
        :) error "${OPTARG} requires an argument"
           ;;
        *) usage
           exit 1
           ;;
    esac
done

## Post-process variables and any command-line options for sanity.

# Set GOOS & GOARCH to the local environment if not already set.
[[ -n ${goos} ]]   || goos=$(go env GOOS)
[[ -n ${goarch} ]] || goos=$(go env GOARCH)

# Make sure we have appropriate directory permissions.
[[ -d ${src} ]]  || error "Unable to read source directory ${src}"
[[ -w ${dest} ]] || error "Unable to write to destination directory ${dest}"

# Interpolate shorthand for GOOS but otherwise pass arguments on to Go and let
# it handle any errant entries.
case ${goos} in
    lnx) goos="linux" ;;
    mac) goos="darwin" ;;
    win) goos="windows" ;;
esac

# Ensure that user has specified both GOOS and GOARCH or neither.
(( archset == osset )) || error "Must specify both OS and  Architecture"
