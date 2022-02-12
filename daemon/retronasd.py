#!/usr/bin/env python3
#
# The RetroNAS daemon
# Hi, I am responsible for managing software for retronas
#
# drop files go into DIR_SPOOL and are generated by the UI
# cache files go into DIR_CACHE
# logging to DIR_LOG
#

import os, sys
import argparse
import yaml

#
# These should be read in from some central config
#
DIR_SPOOL="/var/spool/retronas"
DIR_CACHE="/var/cache/retronas"
DIR_LOG="/var/log/retronas"
RN_GROUP="retronas"

# Internal
me = "retronasd"
modes = ["start", "stop", "restart", "status", "install", "uninstall"]

#
# LOGGING
#
def _log(s):
    print(s)

#
# USAGE
#
def _usage():
  print("Usage $0\n-h this help\n")
  sys.exit(0)

#
# SETUP
#
def setup():
    # run setup playbook
    pass

#
# WATCHDOG
# Monitor path for changes
#
# possible reference: https://www.geeksforgeeks.org/create-a-watchdog-in-python-to-look-for-filesystem-changes/
#
def watchdog(directory, frequenct="1s"):
    print("Watching %s" % directory)

#
# PROCESS cache
#
def process_cache():
    _log("updating cache")

#
# READ drop file
#
def read_drop_file():
    _log("reading drop file")

#
# INSTALL software
#
def install_software():
    _log("installing software")

    install_software()
    write_cache()
    delete_drop_file()

#
# UNINSTALL software
#
def uninstall_software():
    _log("uninstalling software")
    uninstall_software()
    write_cache()

#
# DELETE drop file
#
def delete_drop_file():
    _log("removing drop file")

def warning():
    _log("I am a mere theoretical being, my ability to cope with my task is minimal!!")
    sys.exit(0)

#
# START
#
def start():
    _log("Starting %s" % me)
    setup()

#
# STOP
#
def stop():
    _log("Stopping %s" % me)

#
# RESTART
#
def restart():
    start()
    stop()

#
# STATUS report
#
def status():
    _log("Querying %s" % me)
    
#
# MODEs
#
def call_mode(modes, mode):

    if mode in modes:
        if mode == modes[0]:
            start()
        elif mode == modes[1]:
            stop()
        elif mode == modes[2]:
            restart()
        elif mode == modes[3]:            
            status()
        elif mode == modes[4]:
            install_software()
        elif mode == modes[5]:
            uninstall_software()
        else:
            _log("Invalid mode, can not operate in this mode")
            exit()

def main(args):
    if args.bow_before_retronas is False:
        warning()
    call_mode(modes, args.mode)

if __name__ == "__main__":

    parser = argparse.ArgumentParser(description='"Heavily work in progress" - RetroNAS the great ruler of planet RetroLosis')
    parser.add_argument('--mode', required=False, default="status", type=str, help="op mode (%s)" % "|".join(modes))
    parser.add_argument('--bow-before-retronas', required=False, const=True, default=False, type=bool, nargs="?")
    #parser.add_argument('--flush-cache', const=True, default=False, type=bool, nargs="?")
 
    args = parser.parse_args()

    main(args)