#!/usr/bin/env bash
# RHCSA Exam Grade script
# This script is heavily inspired by Sander Van Gudt's RHCSA Labs.
# Credit goes to Sander for his excellent course material, & for being a source
# of learning and inspiration to many students around the world. :)

# Setting up nullglob
shopt -s nullglob

# ----------------------------------------
# Constants
# ----------------------------------------
readonly BASE_DIR=$(dirname "$0")
readonly LOG_FILE="${BASE_DIR}/exam-grader.log"
readonly CONFIG_FILE="${BASE_DIR}/config"
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m'
readonly -a TASKS=("${BASE_DIR}"/checks/*.sh)
#-----------------------------------------
# Variables
NODE1="${NODE1:-rhcsa1}"
NODE2="${NODE2:-rhcsa2}"
SCORE=0
TOTAL=0
DRY_RUN=false
#-----------------------------------------

# SSH options for non-interactive remote checks
SSH_OPTS="-o ConnectTimeout=5"

# SSH wrapper - uses sshpass with ROOT_PASSWORD when set
# Usage: run_ssh <host> <command>
run_ssh() {
    local host="$1"
    shift
    if [[ -n "$ROOT_PASSWORD" ]]; then
        sshpass -p "$ROOT_PASSWORD" ssh $SSH_OPTS root@"$host" "$@"
    else
        ssh $SSH_OPTS root@"$host" "$@"
    fi
}

# ----------------------------------------
# Argument parsing
# ----------------------------------------
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --dry-run    Show configuration and task list without running checks"
    echo "  -h, --help   Show this help message"
    exit 0
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            -h|--help)
                usage
                ;;
            *)
                echo "Unknown option: $1"
                usage
                ;;
        esac
    done
}

# ----------------------------------------
# Helper functions
# ----------------------------------------

log() {
	local level=$1
	shift
	echo -e "[$level] $*" | tee -a "$LOG_FILE"
}

error_exit() {
	log "${RED}ERROR${NC}" "$1"
	exit 1
}

load_config() {
	if [[ ! -f "$CONFIG_FILE" ]]; then
		error_exit "Config file not found. Run: cp config.example config && vim config"
	fi
	source "$CONFIG_FILE"
	[[ -z "$NODE1_IP" ]] && error_exit "NODE1_IP not set in config"
	[[ -z "$NODE2_IP" ]] && error_exit "NODE2_IP not set in config"
}

check_sudo() {
	clear
	ls /root &>/dev/null || error_exit "Script must be run as root"
}

check_reboot() {
	local uptime_minutes=$(awk '{ print int ($1/60) }' /proc/uptime)
	if [[ "$uptime_minutes" -gt 5 ]]; then
		echo -e "${RED}WARNING${NC} System has been up for more than 5 minutes."
		echo -e "${RED}WARNING${NC} You must reboot it before running this script."
		echo -e "Do you want to reboot now? Answer ${GREEN}yes${NC} to reboot immediately and continue, or ${RED}no${NC} to quit."
		read REBOOT
		case "$REBOOT" in
			y|yes|YES)
				reboot
				;;
			n|no|NO)
				exit 1
				;;
		esac
	fi
}

#----------------------------------
# Exam grading
#----------------------------------

# Helper for task checks - use this in task scripts
# Usage: check 'condition' 'ok message' 'fail message' [points]
check() {
    local condition="$1"
    local ok_msg="$2"
    local fail_msg="$3"
    local points="${4:-10}"

    TOTAL=$(( TOTAL + points ))
    if eval "$condition"; then
        echo -e "${GREEN}[OK]${NC} $ok_msg"
        SCORE=$(( SCORE + points ))
    else
        echo -e "${RED}[FAIL]${NC} $fail_msg"
    fi
}

# Sources task script and compound each score
evaluate_task() {
	local task="$1"
	local task_name=$(basename "$task" .sh)
	echo -e "\n${YELLOW}=== Checking: ${task_name} ===${NC}"
	source "$task"
}

check_prereqs() {
	# Are we in a RHEL environment
	RHEL_COMPATIBLE=$(grep -E "rhel|rocky|alma" /etc/os-release)


}

apply_penalty() {
	log_error "[VIOLATION]" "$1"
	SCORE=$(( SCORE - 50 ))
}

# Check for violations
check_violations() {
	SELINUX_DISABLED=$(getenforce | grep -qi disabled)
	FIREWALLD_DISABLED=$(systemctl is-active firewalld | grep -qi inactive)
	EXTERNAL_REPOS=$(grep -l "http://" /etc/yum.repos.d/* 2>/dev/null | grep -v redhat.repo)
	[[ -n "$SELINUX_DISABLED" ]] && apply_penalty "SELinux is disabled"
	[[ -n "$FIREWALLD_DISABLED" ]] && apply_penalty "FirewallD is disabled"
	[[ -n "$EXTERNAL_REPOS" ]] && apply_penalty "External repos detected"
}

check_outcome() {
	echo -e "\n"
	echo "Your score is $SCORE out of a total $TOTAL"
	if [[ $SCORE -ge $(( TOTAL / 10 * 7 )) ]]; then
		echo -e "${GREEN}CONGRATULATIONS!${NC} You passed this sample exam!"
		echo -e "This outcome is no guarantee for the real exam."
	else
		echo -e "${RED}FAIL${NC} You did not pass this sample exam."
		echo -e "Don't give up and keep trying! ${GREEN}:)${NC}"
	fi
}

dry_run() {
	echo -e "${YELLOW}=== DRY RUN MODE ===${NC}\n"

	echo -e "${GREEN}[OK]${NC} Script is executable"

	# Config check
	if [[ -f "$CONFIG_FILE" ]]; then
		source "$CONFIG_FILE"
		echo -e "${GREEN}[OK]${NC} Config file found: $CONFIG_FILE"
		echo "     NODE1=$NODE1 (IP: ${NODE1_IP:-not set})"
		echo "     NODE2=$NODE2 (IP: ${NODE2_IP:-not set})"
	else
		echo -e "${RED}[FAIL]${NC} Config file not found: $CONFIG_FILE"
		echo "     Run: cp config.example config && vim config"
	fi

	# SSH connectivity (quick test)
	echo -e "\n${YELLOW}--- SSH Connectivity ---${NC}"
	if [[ -n "$ROOT_PASSWORD" ]]; then
		echo "     Using sshpass with ROOT_PASSWORD"
	else
		echo "     Using key-based authentication"
	fi
	if [[ -n "$NODE1_IP" ]]; then
		if run_ssh "$NODE1" exit &>/dev/null || run_ssh "$NODE1_IP" exit &>/dev/null; then
			echo -e "${GREEN}[OK]${NC} Can SSH to node1"
		else
			echo -e "${RED}[FAIL]${NC} Cannot SSH to node1 ($NODE1 / $NODE1_IP)"
		fi
	fi
	if [[ -n "$NODE2_IP" ]]; then
		if run_ssh "$NODE2" exit &>/dev/null || run_ssh "$NODE2_IP" exit &>/dev/null; then
			echo -e "${GREEN}[OK]${NC} Can SSH to node2"
		else
			echo -e "${RED}[FAIL]${NC} Cannot SSH to node2 ($NODE2 / $NODE2_IP)"
		fi
	fi

	# Task files
	echo -e "\n${YELLOW}--- Task Files ---${NC}"
	echo "Found ${#TASKS[@]} task files in checks/"
	for task in "${TASKS[@]}"; do
		echo "  - $(basename "$task")"
	done

	echo -e "\n${GREEN}Dry run complete.${NC} Run without --dry-run to execute checks."
}

main() {
	parse_args "$@"

	if [[ "$DRY_RUN" == true ]]; then
		dry_run
		exit 0
	fi

	check_sudo
	check_reboot
	load_config
	[[ ${#TASKS[@]} -eq 0 ]] && error_exit "No tasks found in checks/"
	check_violations
	for task in "${TASKS[@]}"; do
		evaluate_task "$task"
	done
	check_outcome
}

main "$@"
