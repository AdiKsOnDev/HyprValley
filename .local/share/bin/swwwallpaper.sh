#!/usr/bin/env sh


#// lock instance

lockFile="/tmp/hyde$(id -u)$(basename ${0}).lock"
[ -e "${lockFile}" ] && echo "An instance of the script is already running..." && exit 1
touch "${lockFile}"
trap 'rm -f ${lockFile}' EXIT

hashMech="sha1sum"

set_hash()
{
    local hashImage="${1}"
    "${hashMech}" "${hashImage}" | awk '{print $1}'
}

get_hashmap()
{
    unset wallHash
    unset wallList
    unset skipStrays
    unset verboseMap

    for wallSource in "$@"; do
        [ -z "${wallSource}" ] && continue
        [ "${wallSource}" == "--skipstrays" ] && skipStrays=1 && continue
        [ "${wallSource}" == "--verbose" ] && verboseMap=1 && continue

        hashMap=$(find "${wallSource}" -type f \( -iname "*.gif" -o -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \) -exec "${hashMech}" {} + | sort -k1)
        if [ -z "${hashMap}" ] ; then
            echo "WARNING: No image found in \"${wallSource}\""
            continue
        fi

        while read -r hash image ; do
            wallHash+=("${hash}")
            wallList+=("${image}")
        done <<< "${hashMap}"
    done

    if [ -z "${#wallList[@]}" ] || [[ "${#wallList[@]}" -eq 0 ]] ; then
        if [[ "${skipStrays}" -eq 1 ]] ; then
            return 1
        else
            echo "ERROR: No image found in any source"
            exit 1
        fi
    fi

    if [[ "${verboseMap}" -eq 1 ]] ; then
        echo "// Hash Map //"
        for indx in "${!wallHash[@]}" ; do
            echo ":: \${wallHash[${indx}]}=\"${wallHash[indx]}\" :: \${wallList[${indx}]}=\"${wallList[indx]}\""
        done
    fi
}

#// define functions

Wall_Cache()
{
    ln -fs "${wallList[setIndex]}" "${wallSet}"
    ln -fs "${wallList[setIndex]}" "${wallCur}"
    "${scrDir}/swwwallcache.sh" -w "${wallList[setIndex]}" &> /dev/null
    "${scrDir}/swwwallbash.sh" "${wallList[setIndex]}" &
    ln -fs "${thmbDir}/${wallHash[setIndex]}.sqre" "${wallSqr}"
    ln -fs "${thmbDir}/${wallHash[setIndex]}.thmb" "${wallTmb}"
    ln -fs "${thmbDir}/${wallHash[setIndex]}.blur" "${wallBlr}"
    ln -fs "${thmbDir}/${wallHash[setIndex]}.quad" "${wallQad}"
    ln -fs "${dcolDir}/${wallHash[setIndex]}.dcol" "${wallDcl}"
}

Wall_Change()
{
    curWall="$(set_hash "${wallSet}")"
    for i in "${!wallHash[@]}" ; do
        if [ "${curWall}" == "${wallHash[i]}" ] ; then
            if [ "${1}" == "n" ] ; then
                setIndex=$(( (i + 1) % ${#wallList[@]} ))
            elif [ "${1}" == "p" ] ; then
                setIndex=$(( i - 1 ))
            fi
            break
        fi
    done
    Wall_Cache
}


#// set variables

themeDir="$HOME/.config/hyprValley/theme"
scrDir="$(dirname "$(realpath "$0")")"
wallSet="${themeDir}/wall.set"
cacheDir="$HOME/.cache/hyprValley"
wallCur="${cacheDir}/wall.set"
wallSqr="${cacheDir}/wall.sqre"
wallTmb="${cacheDir}/wall.thmb"
wallBlr="${cacheDir}/wall.blur"
wallQad="${cacheDir}/wall.quad"
wallDcl="${cacheDir}/wall.dcol"


#// check wall

setIndex=0
[ ! -d "${themeDir}" ] && echo "ERROR: \"${themeDir}\" does not exist" && exit 0
wallPathArray=("${themeDir}")
wallPathArray+=("${wallAddCustomPath[@]}")
get_hashmap "${wallPathArray[@]}"
[ ! -e "$(readlink -f "${wallSet}")" ] && echo "fixig link :: ${wallSet}" && ln -fs "${wallList[setIndex]}" "${wallSet}"


#// evaluate options

while getopts "nps:" option ; do
    case $option in
    n ) # set next wallpaper
        xtrans="grow"
        Wall_Change n
        ;;
    p ) # set previous wallpaper
        xtrans="outer"
        Wall_Change p
        ;;
    s ) # set input wallpaper
        if [ ! -z "${OPTARG}" ] && [ -f "${OPTARG}" ] ; then
            get_hashmap "${OPTARG}"
        fi
        Wall_Cache
        ;;
    * ) # invalid option
        echo "... invalid option ..."
        echo "$(basename "${0}") -[option]"
        echo "n : set next wall"
        echo "p : set previous wall"
        echo "s : set input wallpaper"
        exit 1 ;;
    esac
done


#// check swww daemon

swww query &> /dev/null
if [ $? -ne 0 ] ; then
    swww-daemon --format xrgb &
fi


#// set defaults

[ -z "${xtrans}" ] && xtrans="grow"
[ -z "${wallFramerate}" ] && wallFramerate=60
[ -z "${wallTransDuration}" ] && wallTransDuration=0.4


#// apply wallpaper

echo ":: applying wall :: \"$(readlink -f "${wallSet}")\""
swww img "$(readlink "${wallSet}")" --transition-bezier .43,1.19,1,.4 --transition-type "${xtrans}" --transition-duration "${wallTransDuration}" --transition-fps "${wallFramerate}" --invert-y --transition-pos "$(hyprctl cursorpos)" &

