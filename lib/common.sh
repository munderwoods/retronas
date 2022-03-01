#!/bin/bash

set -u

_CONFIG=/opt/retronas/config/retronas.cfg
source $_CONFIG

export SC="systemctl --no-pager --full"

## If this is run as root, switch to our RetroNAS user
## Manifests and cookies stored in ~/.gogrepo
DROP_ROOT() {
    if [ "${USER}" == "root" ]
    then
        export SUCOMMAND="sudo -u ${OLDRNUSER}"
    else
        export SUCOMMAND=""
    fi
}

### Check if we have the correct privs for op
CHECK_ROOT() {
    [ $UID -ne 0 ] && echo "You must run this as root" && exit 1
}

### Get LANG file
GET_LANG() {
    [ ! -z "${LANG}" ] && RNLANG=$(echo $LANG | awk -F'_' '{print $1}')
    [ -z ${RNLANG} ] && RNLANG="en"
    
    if [ -f ${LANGDIR}/${RNLANG} ]
    then
        source ${LANGDIR}/${RNLANG}
    else
        echo "Failed to load language file, check config is complete"
        exit 1
    fi

}

READ_MENU_JSON() {
    local MENU_TITLE="${1:-main}"

    #local IFS=";"
    declare -a MENU_ARRAY_TMP
    export MENU_DATA=$(<${RNJSON} jq -r ".dialog.${MENU_TITLE}.items[] | \"\(.index)|\(.title)|\(.description);\"")    

}

READ_MENU_COMMAND() {
    local MENU_NAME=$1
    local MENU_CHOICE=$2

    MENU_SELECT=$(<${RNJSON} jq -r ".dialog.${MENU_NAME}.items[] | select(.index == \"${MENU_CHOICE}\") | \"\(.command)\"")
    if [ ! -z "${MENU_SELECT}" ] && [ $MENU_SELECT != "null" ]
    then 
        RN_INSTALL_EXECUTE $MENU_SELECT
    else
        echo "Failed to select item for $MENU_CHOICE"
        PAUSE
    fi
    unset MENU_SELECT
}

### Run a script
EXEC_SCRIPT() {
    local SCRIPT="${1}"
    shift
    bash "${SCRIPT}" $*
    unset SCRIPT
}

### Clear function, standardised
CLEAR() {
    clear
}

### Wait for user input
PAUSE() {
    echo "${PAUSEMSG}"
    read -s
}

#
# Install Ansible Dependencies, runs with every installer
#
# !!! this function will be deprecated
#
RN_INSTALL_DEPS() {
    source $_CONFIG
    cd ${ANDIR}
    ansible-playbook -vv retronas_dependencies.yml
}

#
# Run the playbook
#
RN_INSTALL_EXECUTE() {
    source $_CONFIG
    local PLAYBOOK=$1

    CLEAR
    /opt/retronas/lib/ansible_runner.sh "${PLAYBOOK}"
    PAUSE

    #cd ${ANDIR}
    #ansible-playbook -vv "${PLAYBOOK}"
    unset PLAYBOOK
}

#
# GENERIC function to call a command format output
#
RN_SERVICE_STATUS() {
  source $_CONFIG
  local CMD="$1"

  CLEAR
  echo "${CMD}"
  echo ; $CMD ; echo
  PAUSE
}

#
# SYSTEMD status checks
#
RN_SYSTEMD_STATUS() {
  RN_SYSTEMD $1 "status"
}

#
# SYSTEMD start/enable
#
RN_SYSTEMD_START() {
  RN_SYSTEMD $1 "enable"
  RN_SYSTEMD $1 "restart"
}

#
# SYSTEMD stop/disable
#
RN_SYSTEMD_STOP() {
  RN_SYSTEMD $1 "disable"
  RN_SYSTEMD $1 "stop"
}

#
# SYSTEMD
#
RN_SYSTEMD() {
  source $_CONFIG
  local SERVICE="$1"
  local COMMAND="${2:-status}"

  RN_SERVICE_STATUS "${SC} ${COMMAND} ${SERVICE}"

}

#
# DIRECTLY call a status command, and pass args
#
RN_DIRECT_STATUS() {
  source $_CONFIG
  local SERVICE="$1"
  local ARGS="$2"

  if [ -x "$(which $SERVICE)" ]
  then
    RN_SERVICE_STATUS "${SERVICE} ${ARGS}"
  fi

}

# Dialog builder functions
# based on: https://stackoverflow.com/questions/4889187/dynamic-dialog-menu-box-in-bash
#

#
# MENU
#
DLG_MENUJ() {

    local IFS=$'\n'
    local TITLE="$1"
    local MENU_H=$2
    local MENU_BLURB=$3


    local MENU_DESC="My IP addresses: ${MY_IPS}\n${MENU_BLURB}"

    DIALOG=(dialog \
            --backtitle "RetroNAS" \
            --title "RetroNAS ${TITLE}" \
            --clear \
            --menu "$MENU_DESC" ${MW} ${MH} ${MENU_H})

    declare -a MENU_ARRAY
    while IFS=";" read -r ITEM
    do

        INDEX=$(echo $ITEM    | cut -d"|" -f1 | tr -d "\n" | sed 's/\s$//') 
        TITLE=$(echo $ITEM    | cut -d"|" -f2 | tr -d "\n" | sed 's/\s$//') 
        DESC=$(echo $ITEM     | cut -d"|" -f3 | tr -d "\n" | sed 's/\s$//') 
        #COMMAND=$(echo $ITEM | cut -d"|" -f4 | tr -d "\n" | sed 's/\s$//')

        MENU_ARRAY+=(${INDEX} "${TITLE} - ${DESC}")


    done < <(echo "${MENU_DATA[@]}")

    export CHOICE=$("${DIALOG[@]}" "${MENU_ARRAY[@]}" 2>&1 >/dev/tty)
    unset MENU_ARRAY

}


#
# MENU
#
DLG_MENU() {

    local IFS=$'\n'
    local TITLE="$1"
    local -n MENU_ARRAY=$2
    local MENU_H=$3
    local MENU_BLURB=$4


    local MENU_DESC="My IP addresses: ${MY_IPS}\n${MENU_BLURB}"

    DIALOG=(dialog \
            --backtitle "RetroNAS" \
            --title "RetroNAS ${TITLE}" \
            --clear \
            --menu "$MENU_DESC" ${MW} ${MH} ${MENU_H})

    export CHOICE=$("${DIALOG[@]}" "${MENU_ARRAY[@]}" 2>&1 >/dev/tty)

}

#
# YES/NO
#
DLG_YN() {
    local IFS=$'\n'
    local TITLE="$1"
    local MENU_BLURB=$2

    local MENU_DESC="My IP addresses: ${MY_IPS}\n${MENU_BLURB}"

    DIALOG=(dialog \
    --backtitle "RetroNAS" \
    --title "RetroNAS ${TITLE}" \
    --clear \
    --defaultno \
    --yesno "${MENU_DESC}" ${MW} ${MH})

    "${DIALOG[@]}" 2>&1 >/dev/tty
    export CHOICE=$?

}

#
# DIRECTORY SELECTOR
#
DLG_DSELECT() {
    local IFS=$'\n'
    local TITLE="$1"
    local MENU_BLURB=$2

    local MENU_DESC="My IP addresses: ${MY_IPS}\n${MENU_BLURB}"

    DIALOG=(dialog \
    --backtitle "RetroNAS" \
    --title "RetroNAS ${TITLE}" \
    --clear \
    --dselect "${MENU_BLURB}" ${MW} ${MH})

    export CHOICE=$("${DIALOG[@]}" 2>&1 >/dev/tty)

}

#
# DIRECTORY SELECTOR
#
DLG_INPUTBOX() {
    local IFS=$'\n'
    local TITLE="$1"
    local MENU_BLURB=$2
    local MENU_INIT=$3

    local MENU_DESC="My IP addresses: ${MY_IPS}\n${MENU_BLURB}"

    DIALOG=(dialog \
    --backtitle "RetroNAS" \
    --title "RetroNAS ${TITLE}" \
    --clear \
    --inputbox "${MENU_BLURB}" ${MW} ${MH} $MENU_INIT)

    export CHOICE=$("${DIALOG[@]}" 2>&1 >/dev/tty)

}