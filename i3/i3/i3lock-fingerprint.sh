# this requires a little more preparation since sudo fprintd-verify command requires password we 
# have to give it permission to run without password and for that we have to edit suoders file
# run sudo visudo command and at the end of the file add
# username ALL=(ALL) NOPASSWD: /usr/bin/fprintd-verify
# username ALL=(ALL) NOPASSWD: /usr/bin/systemctl restart fprintd
# from the above command replace username with your current username and also check if the location of fprintd-verify fprint service file is correct
# this script below requires fprintd to work but if your fingerprint authenticator allows similar implementation to verify fingerprint then replace fprintd-verify and service name command
# also change the log_file to a different path but if you want to do the same as me create a folder i3lock-fingerprint and give the folder root permission

#!/bin/bash

log_file="/tmp/fingerprint_login.log"

# Function to log messages to the specified log file
log() {
    echo "$(date "+%Y-%m-%d %H:%M:%S") - $1" #>> "$log_file"
}

# Function to clean up and exit
cleanup_and_exit() {
    log "Script finished."
    exit
}

# Function to handle sleep event
handle_sleep() {
    log "Entering sleep mode."
}

# Function to handle resume event
handle_resume() {
    log "Resuming from sleep."
    run_main_loop
}

# Function for the checking fingerprint
run_main_loop() {
    log "Starting main loop."
    cat ~/.config/i3/lostspaceStretched.png | i3lock --image /dev/stdin --raw 2560x1600:rgb  &
    i3lock_pid=$!

    while ps -p "$i3lock_pid" > /dev/null; do
        fingerprint_output=$(fprintd-verify 2>&1)
        #restart_fprintd=$(sudo systemctl restart fprintd 2>&1)
        log "Starting Fingerprint login."
        log "Fingerprint Output: $fingerprint_output"

        if echo "$fingerprint_output" | grep -q "Device was already claimed"; then
            log "Fprintd service restarted."
            #$restart_fprintd
            sudo systemctl restart fprintd 2>&1
        elif echo "$fingerprint_output" | grep -q "verify-match"; then
            log "Fingerprint matched!"
            pkill -f "i3lock.*"
            break
        else
            log "Fingerprint not matched."
        fi
    done
}

trap handle_sleep INT
trap handle_resume CONT

#exec >> "$log_file" 2>&1

log "Script started."

run_main_loop
