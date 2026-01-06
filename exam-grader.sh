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
TARGET_OVERRIDE=""

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

# Low-level SSH probe - tests if we can connect to a target
# Returns 0 on success, 1 on failure
# Usage: ssh_probe <target>
ssh_probe() {
    local target="$1"
    # Use sshpass if password is set
    if [[ -n "$ROOT_PASSWORD" ]]; then
       sshpass -p "$ROOT_PASSWORD" ssh $SSH_OPTS root@"$target" exit &>/dev/null
    else
       ssh $SSH_OPTS root@"$target" exit &>/dev/null
    fi
    return $?
}

# Probe a node trying hostname first, then IP
# Outputs the successful target or empty string
# Usage: ssh_probe_node <hostname> <ip>
ssh_probe_node() {
    local hostname="$1"
    local ip="$2"

    if [[ -n "$hostname" ]] && ssh_probe "$hostname"; then
        echo "$hostname"
        return 0
    elif [[ -n "$ip" ]] && ssh_probe "$ip"; then
        echo "$ip"
        return 0
    fi
    return 1
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
    echo "  --target=VM       Override target VM (node1, node2, or both)"
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
            --target=*)
                TARGET_OVERRIDE="${1#*=}"
                if [[ "$TARGET_OVERRIDE" != "node1" && "$TARGET_OVERRIDE" != "node2" && "$TARGET_OVERRIDE" != "both" ]]; then
                    echo "Invalid target: $TARGET_OVERRIDE (must be node1, node2, or both)"
                    exit 1
                fi
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
	# Root check skipped for API/JSON mode - SSH uses sshpass with password
	[[ "$JSON_OUTPUT" == true ]] && return 0
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
	
	# Extract Expected IP (Smart Grading)
	local expected_ip=$(grep "^# EXPECTED_IP:" "$task" | sed 's/# EXPECTED_IP: //' | tr -d ' \r')
	local target=$(grep "^# Target:" "$task" | sed 's/# Target: //' | tr -d ' \r')
	
	# Determine which node vars to potentially override
	local target_node="node1"
	if [[ "$target" == "node2" ]] || [[ "$CURRENT_TASK" == *"node2"* && "$CURRENT_TASK" != *"node1"* ]]; then
	    target_node="node2"
	fi
	
	# Smart Connectivity Check
	if [[ -n "$expected_ip" ]]; then
	    local original_ip=""
	    local node_var=""

	    if [[ "$target_node" == "node2" ]]; then
	        original_ip="$NODE2_IP"
	        node_var="NODE2_IP"
	    else
	        original_ip="$NODE1_IP"
	        node_var="NODE1_IP"
	    fi

	    # Case 1: Expected IP is active -> Use it and proceed
	    if ssh_probe "$expected_ip"; then
	        eval "$node_var='${expected_ip}'"
	        [[ "$JSON_OUTPUT" == false ]] && echo -e "${GREEN}[INFO]${NC} Task $CURRENT_TASK: Detected new IP $expected_ip active. Using it for grading."
	    
        # Case 2: Expected IP unreachable, trying Original IP
	    else
            # Case 3: Original IP is active -> Task likely failed (network settings incorrect)
	        if ssh_probe "$original_ip"; then
                [[ "$JSON_OUTPUT" == false ]] && echo -e "${RED}[FAIL]${NC} Task $CURRENT_TASK: Target IP $expected_ip unreachable, but host is accessible via $original_ip. Task failed."
                # We do NOT update the IP, so the script will try to grade on original_ip and likely fail checks
                # Or we could just fail fast here? The user asked: "if the target ip doesnt work, but host works, task failed"
                # Let's let the checks run (and fail) on the original IP so they see *what* failed
                
            # Case 4: Both IPs unreachable -> Connection Error (Cannot Grade)
            else
                [[ "$JSON_OUTPUT" == false ]] && echo -e "${RED}[ERROR]${NC} Task $CURRENT_TASK: Could not reach node via Target ($expected_ip) or Original ($original_ip) IP."
                if [[ "$JSON_OUTPUT" == true ]]; then
                     echo "{\"task\":\"$CURRENT_TASK\",\"category\":\"$CURRENT_CATEGORY\",\"check\":\"Connectivity Check\",\"passed\":false,\"points\":0,\"message\":\"Critical: Connection lost to both $expected_ip and $original_ip\"}," >> "${RESULTS_JSON_FILE}" 
                else
                     echo -e "${RED}CRITICAL:${NC} Connection lost. Cannot grade this task."
                fi
                return 1
	        fi
	    fi
	fi

	if [[ "$JSON_OUTPUT" == false ]]; then
		echo -e "\n${YELLOW}=== Checking: ${CURRENT_TASK} ===${NC}"
	fi
	source "$task"
	
	# Restore IPs if compromised (though variables are local to function scope in bash if declared local, 
	# but NODE1_IP is global. So we must restore!)
	if [[ -n "$expected_ip" ]]; then
	    if [[ "$target_node" == "node2" && -n "$original_node2_ip" ]]; then
	        NODE2_IP="$original_node2_ip"
	    elif [[ "$target_node" == "node1" && -n "$original_node1_ip" ]]; then
	        NODE1_IP="$original_node1_ip"
	    fi
	fi
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
		local first=true
		local entries=()
		for task in "${TASKS[@]}"; do
			local name=$(basename "$task" .sh)
			local category=$(grep "^# Category:" "$task" | sed 's/# Category: //')
			local desc=$(grep "^# Task:" "$task" | sed 's/# Task: //')
			local target=$(grep "^# Target:" "$task" | sed 's/# Target: //')
			# Default target based on description if not specified
			if [[ -z "$target" ]]; then
				if [[ "$desc" == *"node2"* ]] && [[ "$desc" != *"node1"* ]]; then
					target="node2"
				elif [[ "$desc" == *"node1"* ]] && [[ "$desc" != *"node2"* ]]; then
					target="node1"
				elif [[ "$desc" == *"both"* ]] || [[ "$desc" == *"node1"* && "$desc" == *"node2"* ]]; then
					target="both"
				else
					target="node1"  # Default
				fi
			fi
			# Escape quotes in description
			desc="${desc//\"/\\\"}"
			entries+=("{\"id\":\"$name\",\"category\":\"$category\",\"description\":\"$desc\",\"target\":\"$target\"}")
		done
		# Join with commas and output
		local IFS=,
		echo "[${entries[*]}]"
	else
		printf "%-12s %-8s %-18s %s\n" "TASK" "TARGET" "CATEGORY" "DESCRIPTION"
		printf "%-12s %-8s %-18s %s\n" "----" "------" "--------" "-----------"
		for task in "${TASKS[@]}"; do
			local name=$(basename "$task" .sh)
			local category=$(grep "^# Category:" "$task" | sed 's/# Category: //')
			local desc=$(grep "^# Task:" "$task" | sed 's/# Task: //')
			local target=$(grep "^# Target:" "$task" | sed 's/# Target: //' || echo "node1")
			printf "%-12s %-8s %-18s %s\n" "$name" "${target:-node1}" "$category" "${desc:0:45}"
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

# Check if config file exists and has required values
# Returns JSON object with config status
# Exit code: 0 = valid, 1 = missing file, 2 = missing values
check_config() {
    local config_file="${1:-$CONFIG_FILE}"
    local missing=()

    if [[ ! -f "$config_file" ]]; then
        echo '{"ok":false,"error":"config_not_found","file":"'"$config_file"'"}'
        return 1
    fi

    source "$config_file"

    [[ -z "$NODE1_IP" ]] && missing+=("NODE1_IP")
    [[ -z "$NODE2_IP" ]] && missing+=("NODE2_IP")

    if [[ ${#missing[@]} -gt 0 ]]; then
        local missing_json=$(printf ',"%s"' "${missing[@]}")
        missing_json="[${missing_json:1}]"
        echo '{"ok":false,"error":"missing_values","missing":'"$missing_json"'}'
        return 2
    fi

    echo '{"ok":true,"node1":"'"$NODE1"'","node1_ip":"'"$NODE1_IP"'","node2":"'"$NODE2"'","node2_ip":"'"$NODE2_IP"'"}'
    return 0
}

# Check SSH connectivity and output JSON
# Returns JSON array with connection status for each node
# Exit code = number of failed connections
check_ssh() {
    local node1_hostname="${1:-$NODE1}"
    local node1_ip="${2:-$NODE1_IP}"
    local node2_hostname="${3:-$NODE2}"
    local node2_ip="${4:-$NODE2_IP}"

    local failures=0
    local results=()
    
    # Filter based on TARGET_OVERRIDE
    local check_n1=true
    local check_n2=true
    if [[ "$TARGET_OVERRIDE" == "node1" ]]; then check_n2=false; fi
    if [[ "$TARGET_OVERRIDE" == "node2" ]]; then check_n1=false; fi

    # Check node1
    if [[ "$check_n1" == true ]]; then
        local node1_target=""
        local node1_ok=false
        node1_target=$(ssh_probe_node "$node1_hostname" "$node1_ip")
        if [[ -n "$node1_target" ]]; then
            node1_ok=true
        else
            ((failures++))
            node1_target="${node1_hostname:-$node1_ip}"
        fi
        results+=("{\"node\":\"node1\",\"ok\":$node1_ok,\"target\":\"$node1_target\"}")
    else
        # Placeholder if skipped
         results+=("{\"node\":\"node1\",\"ok\":false,\"skipped\":true}")
    fi

    # Check node2
    if [[ "$check_n2" == true ]]; then
        local node2_target=""
        local node2_ok=false
        node2_target=$(ssh_probe_node "$node2_hostname" "$node2_ip")
        if [[ -n "$node2_target" ]]; then
            node2_ok=true
        else
            ((failures++))
            node2_target="${node2_hostname:-$node2_ip}"
        fi
        results+=("{\"node\":\"node2\",\"ok\":$node2_ok,\"target\":\"$node2_target\"}")
    else
         # Placeholder if skipped
         results+=("{\"node\":\"node2\",\"ok\":false,\"skipped\":true}")
    fi

    # Output JSON array
    echo "[${results[0]},${results[1]}]"

    return $failures
}

# Orchestrate dry run checks
# In JSON mode: outputs structured JSON object
# In human mode: outputs human-readable results
dry_run() {
    local config_result
    local ssh_result
    local config_ok=false
    local ssh_failures=0

    # Check config
    config_result=$(check_config)
    local config_rc=$?
    [[ $config_rc -eq 0 ]] && config_ok=true

    # Load config for SSH check if valid
    if [[ "$config_ok" == true ]]; then
        source "$CONFIG_FILE"
        ssh_result=$(check_ssh)
        ssh_failures=$?
    fi

    if [[ "$JSON_OUTPUT" == true ]]; then
        # JSON output mode
        local tasks_json="["
        local first=true
        for task in "${TASKS[@]}"; do
            local name=$(basename "$task" .sh)
            [[ "$first" == false ]] && tasks_json+=","
            tasks_json+="\"$name\""
            first=false
        done
        tasks_json+="]"

        cat <<EOF
{
  "config": $config_result,
  "ssh": ${ssh_result:-null},
  "tasks": $tasks_json,
  "task_count": ${#TASKS[@]},
  "ready": $([ "$config_ok" == true ] && [ "$ssh_failures" -eq 0 ] && echo true || echo false)
}
EOF
    else
        # Human-readable output mode
        echo -e "${YELLOW}=== DRY RUN MODE ===${NC}\n"

        echo -e "${GREEN}[OK]${NC} Script is executable"

        # Config status
        if [[ "$config_ok" == true ]]; then
            echo -e "${GREEN}[OK]${NC} Config file found: $CONFIG_FILE"
            echo "     NODE1=$NODE1 (IP: ${NODE1_IP:-not set})"
            echo "     NODE2=$NODE2 (IP: ${NODE2_IP:-not set})"
        else
            echo -e "${RED}[FAIL]${NC} Config issue: $config_result"
            echo "     Run: cp config.example config && vim config"
        fi

        # SSH status
        if [[ -n "$ssh_result" ]]; then
            echo -e "\n${YELLOW}--- SSH Connectivity ---${NC}"
            if [[ -n "$ROOT_PASSWORD" ]]; then
                echo "     Using sshpass with ROOT_PASSWORD"
            else
                echo "     Using key-based authentication"
            fi

            # Parse JSON results for human display
            local node1_ok=$(echo "$ssh_result" | grep -oP '"node":"node1"[^}]*"ok":\K(true|false)')
            local node1_target=$(echo "$ssh_result" | grep -oP '"node":"node1"[^}]*"target":"\K[^"]+')
            local node2_ok=$(echo "$ssh_result" | grep -oP '"node":"node2"[^}]*"ok":\K(true|false)')
            local node2_target=$(echo "$ssh_result" | grep -oP '"node":"node2"[^}]*"target":"\K[^"]+')

            if [[ "$node1_ok" == "true" ]]; then
                echo -e "${GREEN}[OK]${NC} Can SSH to node1 ($node1_target)"
            else
                echo -e "${RED}[FAIL]${NC} Cannot SSH to node1 ($node1_target)"
            fi

            if [[ "$node2_ok" == "true" ]]; then
                echo -e "${GREEN}[OK]${NC} Can SSH to node2 ($node2_target)"
            else
                echo -e "${RED}[FAIL]${NC} Cannot SSH to node2 ($node2_target)"
            fi
        fi

        # Task files
        echo -e "\n${YELLOW}--- Task Files ---${NC}"
        echo "Found ${#TASKS[@]} task files in checks/"
        for task in "${TASKS[@]}"; do
            echo "  - $(basename "$task")"
        done

        echo -e "\n${GREEN}Dry run complete.${NC} Run without --dry-run to execute checks."
    fi
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
        # Load config to get node defaults
        if [[ -f "$CONFIG_FILE" ]]; then
            source "$CONFIG_FILE"
        fi
        # check_ssh uses defaults from config or environment
        check_ssh
        exit $?
    fi

	check_sudo
	[[ "$SKIP_REBOOT" == false ]] && check_reboot
	load_config
	[[ ${#TASKS[@]} -eq 0 ]] && error_exit "No tasks found in checks/"

	# Apply target VM override if specified
	if [[ -n "$TARGET_OVERRIDE" ]]; then
		if [[ "$JSON_OUTPUT" == false ]]; then
			echo -e "${YELLOW}Target override: $TARGET_OVERRIDE${NC}"
		fi
		case "$TARGET_OVERRIDE" in
			node1)
				# Redirect all node2 checks to node1
				NODE2_IP="$NODE1_IP"
				NODE2="$NODE1"
				;;
			node2)
				# Redirect all node1 checks to node2
				NODE1_IP="$NODE2_IP"
				NODE1="$NODE2"
				;;
			both)
				# Default behavior - no override needed
				;;
		esac
	fi

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
