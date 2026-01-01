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
SKIP_REBOOT=false
JSON_OUTPUT=false
LIST_TASKS=false
SELECTED_TASKS=""

# For JSON output - stores results
declare -a RESULTS_JSON=()
CURRENT_TASK=""
CURRENT_CATEGORY=""
#-----------------------------------------

# SSH options for non-interactive remote checks
SSH_OPTS="-o ConnectTimeout=5"

# SSH wrapper - uses sshpass with ROOT_PASSWORD when set
# Usage: run_ssh <host> <command>
# Note: Prefer hostnames over IPs as some systems block IP-based SSH
run_ssh() {
    local host="$1"
    shift
    if [[ -n "$ROOT_PASSWORD" ]]; then
        sshpass -p "$ROOT_PASSWORD" ssh $SSH_OPTS root@"$host" "$@"
    else
        ssh $SSH_OPTS root@"$host" "$@"
    fi
}

# SSH to node2 - tries hostname first, falls back to IP
ssh_node2() {
    run_ssh "$NODE2" "$@" 2>/dev/null || run_ssh "$NODE2_IP" "$@"
}

# ----------------------------------------
# Argument parsing
# ----------------------------------------
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --dry-run         Show configuration and task list without running checks"
    echo "  --check-ssh       Check SSH connectivity between nodes"
    echo "  --skip-reboot     Skip the reboot check (for API/automation use)"
    echo "  --json            Output results as JSON (for API integration)"
    echo "  --tasks=LIST      Run only specific tasks (comma-separated, e.g., --tasks=01,05,27)"
    echo "  --list-tasks      List all available tasks with categories"
    echo "  -h, --help        Show this help message"
    exit 0
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --check-ssh)
                CHECK_SSH=true
                shift
                ;;
            --skip-reboot)
                SKIP_REBOOT=true
                shift
                ;;
            --json)
                JSON_OUTPUT=true
                shift
                ;;
            --tasks=*)
                SELECTED_TASKS="${1#*=}"
                shift
                ;;
            --list-tasks)
                LIST_TASKS=true
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
	[[ "$JSON_OUTPUT" == false ]] && clear
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
    local passed=false

    TOTAL=$(( TOTAL + points ))
    if eval "$condition"; then
        passed=true
        SCORE=$(( SCORE + points ))
        if [[ "$JSON_OUTPUT" == false ]]; then
            echo -e "${GREEN}[OK]${NC} $ok_msg"
        fi
    else
        if [[ "$JSON_OUTPUT" == false ]]; then
            echo -e "${RED}[FAIL]${NC} $fail_msg"
        fi
    fi

    # Store result for JSON output
    if [[ "$JSON_OUTPUT" == true ]]; then
        local json_entry=$(cat <<EOF
{"task":"$CURRENT_TASK","category":"$CURRENT_CATEGORY","check":"$ok_msg","passed":$passed,"points":$points}
EOF
)
        RESULTS_JSON+=("$json_entry")
    fi
}

# Sources task script and compound each score
evaluate_task() {
	local task="$1"
	CURRENT_TASK=$(basename "$task" .sh)
	# Extract category from task file
	CURRENT_CATEGORY=$(grep "^# Category:" "$task" | sed 's/# Category: //' || echo "unknown")

	if [[ "$JSON_OUTPUT" == false ]]; then
		echo -e "\n${YELLOW}=== Checking: ${CURRENT_TASK} ===${NC}"
	fi
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
	local passed=false
	[[ $SCORE -ge $(( TOTAL / 10 * 7 )) ]] && passed=true

	if [[ "$JSON_OUTPUT" == true ]]; then
		output_json "$passed"
	else
		echo -e "\n"
		echo "Your score is $SCORE out of a total $TOTAL"
		if [[ "$passed" == true ]]; then
			echo -e "${GREEN}CONGRATULATIONS!${NC} You passed this sample exam!"
			echo -e "This outcome is no guarantee for the real exam."
		else
			echo -e "${RED}FAIL${NC} You did not pass this sample exam."
			echo -e "Don't give up and keep trying! ${GREEN}:)${NC}"
		fi
	fi
}

output_json() {
	local passed="$1"
	local timestamp=$(date -Iseconds)

	# Build results array
	local results_arr=""
	for i in "${!RESULTS_JSON[@]}"; do
		[[ $i -gt 0 ]] && results_arr+=","
		results_arr+="${RESULTS_JSON[$i]}"
	done

	# Calculate category stats
	local categories=$(printf '%s\n' "${RESULTS_JSON[@]}" | grep -oP '"category":"\K[^"]+' | sort -u)
	local cat_stats=""
	local first=true
	for cat in $categories; do
		local cat_total=$(printf '%s\n' "${RESULTS_JSON[@]}" | grep "\"category\":\"$cat\"" | grep -oP '"points":\K[0-9]+' | paste -sd+ | bc)
		local cat_passed=$(printf '%s\n' "${RESULTS_JSON[@]}" | grep "\"category\":\"$cat\"" | grep '"passed":true' | grep -oP '"points":\K[0-9]+' | paste -sd+ | bc)
		[[ -z "$cat_passed" ]] && cat_passed=0
		[[ "$first" == false ]] && cat_stats+=","
		cat_stats+="\"$cat\":{\"earned\":$cat_passed,\"possible\":$cat_total}"
		first=false
	done

	cat <<EOF
{
  "timestamp": "$timestamp",
  "score": $SCORE,
  "total": $TOTAL,
  "passed": $passed,
  "passing_threshold": 70,
  "categories": {$cat_stats},
  "checks": [$results_arr]
}
EOF
}

list_tasks() {
	local json_mode="$1"
	if [[ "$json_mode" == true ]]; then
		echo "["
		local first=true
		for task in "${TASKS[@]}"; do
			local name=$(basename "$task" .sh)
			local category=$(grep "^# Category:" "$task" | sed 's/# Category: //')
			local desc=$(grep "^# Task:" "$task" | sed 's/# Task: //')
			[[ "$first" == false ]] && echo ","
			echo "{\"id\":\"$name\",\"category\":\"$category\",\"description\":\"$desc\"}"
			first=false
		done
		echo "]"
	else
		printf "%-12s %-18s %s\n" "TASK" "CATEGORY" "DESCRIPTION"
		printf "%-12s %-18s %s\n" "----" "--------" "-----------"
		for task in "${TASKS[@]}"; do
			local name=$(basename "$task" .sh)
			local category=$(grep "^# Category:" "$task" | sed 's/# Category: //')
			local desc=$(grep "^# Task:" "$task" | sed 's/# Task: //')
			printf "%-12s %-18s %s\n" "$name" "$category" "${desc:0:50}"
		done
	fi
}

get_filtered_tasks() {
	if [[ -z "$SELECTED_TASKS" ]]; then
		echo "${TASKS[@]}"
	else
		local filtered=()
		IFS=',' read -ra selected <<< "$SELECTED_TASKS"
		for task in "${TASKS[@]}"; do
			local name=$(basename "$task" .sh)
			local num="${name#task-}"
			for sel in "${selected[@]}"; do
				if [[ "$num" == "$sel" ]]; then
					filtered+=("$task")
					break
				fi
			done
		done
		echo "${filtered[@]}"
	fi
}

check_ssh() {
    local TARGET_ONE_HOSTNAME="${TARGET_ONE_HOSTNAME:-$NODE1}"
    local TARGET_ONE_IP="${TARGET_ONE_IP:-$NODE1_IP}"
    local TARGET_TWO_HOSTNAME="${TARGET_TWO_HOSTNAME:-$NODE2}"
    local TARGET_TWO_IP="${TARGET_TWO_IP:-$NODE2_IP}"
	echo -e "\n${YELLOW}--- SSH Connectivity ---${NC}"
	if [[ -n "$ROOT_PASSWORD" ]]; then
		echo "     Using sshpass with ROOT_PASSWORD"
	else
		echo "     Using key-based authentication"
	fi
	if [[ -n "$TARGET_ONE_HOSTNAME" ]]; then
		if run_ssh "$TARGET_ONE_HOSTNAME" exit &>/dev/null || run_ssh "$TARGET_ONE_IP" exit &>/dev/null; then
			echo -e "${GREEN}[OK]${NC} Can SSH to node1"
		else
			echo -e "${RED}[FAIL]${NC} Cannot SSH to node1 ($TARGET_ONE_HOSTNAME / $TARGET_ONE_IP)"
		fi
	fi
	if [[ -n "$TARGET_TWO_IP" ]]; then
		if run_ssh "$TARGET_TWO_HOSTNAME" exit &>/dev/null || run_ssh "$TARGET_TWO_IP" exit &>/dev/null; then
			echo -e "${GREEN}[OK]${NC} Can SSH to node2"
		else
			echo -e "${RED}[FAIL]${NC} Cannot SSH to node2 ($TARGET_TWO_HOSTNAME / $TARGET_TWO_IP)"
		fi
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
	check_ssh "$NODE1 $NODE1_IP $NODE2 $NODE2_IP"

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

	if [[ "$LIST_TASKS" == true ]]; then
		list_tasks "$JSON_OUTPUT"
		exit 0
	fi

	if [[ "$DRY_RUN" == true ]]; then
		dry_run
		exit 0
	fi

    if [[ "$CHECK_SSH" == true ]]; then 
        if [[ $# -ne 4 && $# -ne 0 ]]; then
                        echo "check_ssh needs four arguments: <node1-hostname> <node1-ip> <node2-hostname> <node2-ip>" >&2
                        exit 1
        else
            shift
            local TARGET_ONE_HOSTNAME="$1"
            local TARGET_ONE_IP="$2"
            local TARGE_TWO_HOSTNAME="$3"
            local TARGET_TWO_IP="$4"
            check_ssh "$TARGET_ONE_HOSTNAME" "$TARGET_ONE_IP" "$TARGET_TWO_HOSTNAME" "$TARGET_TWO_IP"
        fi
        # Defaults to calling check_ssh with global variables
        check_ssh
            exit 0
    fi

	check_sudo
	[[ "$SKIP_REBOOT" == false ]] && check_reboot
	load_config
	[[ ${#TASKS[@]} -eq 0 ]] && error_exit "No tasks found in checks/"
	check_violations

	# Get filtered tasks if --tasks specified
	local run_tasks
	read -ra run_tasks <<< "$(get_filtered_tasks)"
	[[ ${#run_tasks[@]} -eq 0 ]] && error_exit "No matching tasks found"

	for task in "${run_tasks[@]}"; do
		evaluate_task "$task"
	done
	check_outcome
}

main "$@"
