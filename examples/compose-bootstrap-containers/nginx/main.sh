#!/usr/bin/env bash
# Written in [Amber](https://amber-lang.com/)
# version: 0.4.0-alpha
# date: 2025-09-29 18:27:14
dir_exists__32_v0() {

# bshchk (https://git.blek.codes/blek/bshchk)
deps=('[' '[' 'return' 'return' '[' 'bc' 'sed' 'mkdir' '[' 'bc' 'sed' 'exit' '[' 'bc' 'sed' 'cp' '[' 'exit' 'exit')
non_ok=()

for d in $deps
do
    if ! command -v $d > /dev/null 2>&1; then
        non_ok+=$d
    fi
done

if (( ${#non_ok[@]} != 0 )); then
    >&2 echo "RDC Failed!"
    >&2 echo "  This program requires these commands:"
    >&2 echo "  > $deps"
    >&2 echo "    --- "
    >&2 echo "  From which, these are missing:"
    >&2 echo "  > $non_ok"
    >&2 echo "Make sure that those are installed and are present in \$PATH."
    exit 1
fi

unset non_ok
unset deps
# Dependencies are OK at this point


    local path=$1
    [ -d "${path}" ]
    __AS=$?
    if [ $__AS != 0 ]; then
        __AF_dir_exists32_v0=0
        return 0
    fi
    __AF_dir_exists32_v0=1
    return 0
}
dir_create__38_v0() {
    local path=$1
    dir_exists__32_v0 "${path}"
    __AF_dir_exists32_v0__52_12="$__AF_dir_exists32_v0"
    if [ $(echo '!' "$__AF_dir_exists32_v0__52_12" | bc -l | sed '/\./ s/\.\{0,1\}0\{1,\}$//') != 0 ]; then
        mkdir -p "${path}"
        __AS=$?
    fi
}

compose_directory="/.bottlerocket/rootfs/local/compose-containers"
# ensure that `/local/compose-containers` directory is present,
# otherwise we might be using a non-compose variant of
# bottlerocket.
dir_exists__32_v0 "${compose_directory}"
__AF_dir_exists32_v0__9_12="$__AF_dir_exists32_v0"
if [ $(echo '!' "$__AF_dir_exists32_v0__9_12" | bc -l | sed '/\./ s/\.\{0,1\}0\{1,\}$//') != 0 ]; then
    exit 1
fi
# create the required directory.
dir_exists__32_v0 "${compose_directory}/nginx"
__AF_dir_exists32_v0__14_12="$__AF_dir_exists32_v0"
if [ $(echo '!' "$__AF_dir_exists32_v0__14_12" | bc -l | sed '/\./ s/\.\{0,1\}0\{1,\}$//') != 0 ]; then
    dir_create__38_v0 "${compose_directory}/nginx"
    __AF_dir_create38_v0__15_9="$__AF_dir_create38_v0"
    echo "$__AF_dir_create38_v0__15_9" >/dev/null 2>&1
fi
# copy the required files.
cp nginx/compose.yml ${compose_directory}/nginx
__AS=$?
if [ $__AS != 0 ]; then

    exit $__AS
fi
exit 0
