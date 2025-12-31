#!/usr/bin/env bash
# RHCSA Exam Grade script
# This script is heavily inspired by Sander Van Gudt's RHCSA Labs.
# Credit goes to Sander for his excellent course material, & for being a source
# of learning and inspiration to many students around the world. :)


# ----------------------------------------
# Variables
# ----------------------------------------
readonly BASE_DIR=$(dirname "$0")
readonly LOG_FILE="${BASE_DIR}/exam-grader.log"
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m'

# ----------------------------------------
# Helper functions
# ----------------------------------------

log() {
	local level=$1
	shift
	echo "$(date '+%Y-%m-%d %H:%M:%S') [$level] $*" | tee -a "$LOG_FILE"
}

error_exit() {
	log "ERROR" "$1"
	exit 1
}

check_sudo() {
	clear
	ls /root &>/dev/null || (log "FAIL" "Script must be run as root" && exit 2)
}

check_reboot() {
	local uptime_minutes=$(awk '{ print int ($1/60) }' /proc/uptime)
	if [[ "$uptime_minutes" -gt 5 ]]; then
		echo -e "${RED}WARNING${NC} System has been up for more than 5 minutes."
		echo -e "${RED}WARNING${NC} You must reboot it before running this script."
		echo -e "Do you want to reboot now? Answer ${GREEN}yes${NC} to reboot immediately and continue"
		read REBOOT
		[[ $REBOOT = yes ]] && reboot
	fi
}

check_tasks() {
	readonly -a TASKS=("${BASE_DIR}"/checks/*.sh) || (echo "No tasks found in the checks directory" & exit 1)
}

check_for_user() {
	# handle user student - yet to see
}


# Sources task script and compound each score
evaluate_task() {
	local task="$1"		
	source $task
	echo "The score is $SCORE"
	TOTALSCORE=$SCORE
	TOTAL=$TOTAL
}


check_outcome() {
	echo -e "\n"
	echo "Your score is $SCORE out of a total $TOTAL"
	if [[ $SCORE -ge $(( TOTAL / 10 * 7 )) ]]; then
		echo -e "${GREEN}CONGRATULATIONS!${NC} You passed this sample exam!"
		echo -e "This outcome is no guarantee for the real exam."
	else
		echo -e "${RED}FAIL${NC} You did not pass this sample exam."
		echo -e "Don't give up and keep trying! ${GREEN}:)"
	fi
}

main() {
	check_sudo
	check_reboot
	check_tasks
	for task in "${TASKS_DIR[@]}"; do
		evalue_task "$task"
	done
	check_outcome
}
