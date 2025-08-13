#!/usr/bin/env bash

# Enhanced Git Repository Version Tracker
# Displays version information for local, origin, and upstream git repositories
# with configurable upstream branch and clear, readable output format.
#
# Installation:
# 1. Save this script to ~/.local/bin/version.sh or ~/version.sh
# 2. Make it executable: chmod +x ~/.local/bin/version.sh
# 3. Add ~/.local/bin to PATH if using ~/.local/bin location
#
# Usage Examples:
# ~/version.sh                    # Check current directory
# ~/version.sh .                  # Check current directory (explicit)
# ~/version.sh /path/to/repo      # Check specific repository path
# ./version.sh                    # If script is inside the repository

set -euo pipefail  # Enable strict error handling

# Default configuration
readonly DEFAULT_UPSTREAM_BRANCH="main"
readonly SCRIPT_NAME="$(basename "${0}")"

# Display usage information
show_usage() {
    cat << EOF >&2
Usage: ${SCRIPT_NAME} [PATH] [OPTIONS]

Display version information for git repository including local, origin, and upstream states.

ARGUMENTS:
    PATH                            Path to git repository (default: current directory)

OPTIONS:
    -u, --upstream-branch BRANCH    Set upstream branch name (default: ${DEFAULT_UPSTREAM_BRANCH})
    -a, --all                       Show all remotes (not just origin and upstream)
    -v, --verbose                   Enable verbose output with commit hashes
    -h, --help                      Show this help message

EXAMPLES:
    ${SCRIPT_NAME}                          # Check current directory
    ${SCRIPT_NAME} .                        # Check current directory (explicit)
    ${SCRIPT_NAME} /path/to/repo            # Check specific repository
    ${SCRIPT_NAME} . -u develop             # Use 'develop' as upstream branch
    ${SCRIPT_NAME} /path/to/repo --verbose  # Show commit hashes for specific repo
    ${SCRIPT_NAME} --all                    # Show all remotes (not just origin/upstream)
    ${SCRIPT_NAME} -a -v                    # Show all remotes with verbose output
    ${SCRIPT_NAME} --help                   # Show this help message

INSTALLATION:
    # Option 1: System-wide accessible
    sudo cp ${SCRIPT_NAME} /usr/local/bin/version
    sudo chmod +x /usr/local/bin/version

    # Option 2: User-specific (recommended)
    cp ${SCRIPT_NAME} ~/.local/bin/version.sh
    chmod +x ~/.local/bin/version.sh
    # Add to ~/.bashrc or ~/.zshrc: export PATH="\$HOME/.local/bin:\$PATH"

    # Option 3: Home directory
    cp ${SCRIPT_NAME} ~/version.sh
    chmod +x ~/version.sh

EOF
}

# Parse command line arguments
parse_arguments() {
    local repo_path="."
    local upstream_branch="${DEFAULT_UPSTREAM_BRANCH}"
    local verbose=false
    local show_all_remotes=false

    # First argument might be a path (if it doesn't start with -)
    if [[ $# -gt 0 && "${1}" != -* ]]; then
        repo_path="$1"
        shift
    fi

    while [[ $# -gt 0 ]]; do
        case $1 in
            -u|--upstream-branch)
                [[ -z "${2:-}" ]] && { echo "Error: --upstream-branch requires a branch name" >&2; exit 1; }
                upstream_branch="$2"
                shift 2
                ;;
            -a|--all)
                show_all_remotes=true
                shift
                ;;
            -h|--help)
                # This should never be reached due to early detection in main function
                show_usage
                exit 0
                ;;
            -v|--verbose)
                verbose=true
                shift
                ;;
            *)
                echo "Error: Unknown option '$1'" >&2
                echo "Use --help for usage information." >&2
                exit 1
                ;;
        esac
    done

    echo "${repo_path}|${upstream_branch}|${verbose}|${show_all_remotes}"
}

# Validate git repository path
validate_git_repo() {
    local repo_path="$1"

    # Resolve and validate the path
    if [[ ! -d "${repo_path}" ]]; then
        echo "Error: Directory '${repo_path}' does not exist" >&2
        return 1
    fi

    # Get absolute path for cleaner output
    local abs_path
    abs_path=$(cd "${repo_path}" && pwd) || {
        echo "Error: Cannot access directory '${repo_path}'" >&2
        return 1
    }

    # Check if it's a git repository (without changing directory)
    if ! git -C "${abs_path}" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        echo "Error: '${abs_path}' is not a git repository" >&2
        return 1
    fi

    # Return the absolute path for display purposes
    echo "${abs_path}"
}

# Get remote information safely
get_remote_info() {
    local repo_path="$1"
    local remote_name="$2"
    local branch_name="$3"
    local verbose="$4"

    if git -C "${repo_path}" remote get-url "${remote_name}" >/dev/null 2>&1; then
        git -C "${repo_path}" fetch "${remote_name}" >/dev/null 2>&1 || return 1

        local hash version
        hash=$(git -C "${repo_path}" rev-parse "${remote_name}/${branch_name}" 2>/dev/null) || return 1
        version=$(git -C "${repo_path}" describe "${remote_name}/${branch_name}" --tags --always 2>/dev/null) || return 1

        if [[ "${verbose}" == "true" ]]; then
            echo "${version}|${hash}"
        else
            echo "${version}|"
        fi
        return 0
    fi
    return 1
}

# Get local repository information
get_local_info() {
    local repo_path="$1"
    local verbose="$2"

    local hash version current_branch
    hash=$(git -C "${repo_path}" rev-parse HEAD 2>/dev/null) || return 1
    version=$(git -C "${repo_path}" describe HEAD --tags --always 2>/dev/null) || return 1
    current_branch=$(git -C "${repo_path}" symbolic-ref --short HEAD 2>/dev/null) || echo "HEAD (detached)"

    if [[ "${verbose}" == "true" ]]; then
        echo "${version}|${hash}|${current_branch}"
    else
        echo "${version}||${current_branch}"
    fi
}

# Check for local modifications
has_local_modifications() {
    local repo_path="$1"
    [[ -n "$(git -C "${repo_path}" status --porcelain 2>/dev/null)" ]]
}

# Get all remotes except origin and upstream
get_additional_remotes() {
    local repo_path="$1"

    # Get all remotes
    local all_remotes
    all_remotes=$(git -C "${repo_path}" remote 2>/dev/null) || return 1

    # Filter out origin and upstream
    local additional_remotes=""
    while IFS= read -r remote; do
        if [[ -n "$remote" && "$remote" != "origin" && "$remote" != "upstream" ]]; then
            additional_remotes+="${remote}"$'\n'
        fi
    done <<< "$all_remotes"

    # Remove trailing newline and return
    additional_remotes=${additional_remotes%$'\n'}

    if [[ -n "$additional_remotes" ]]; then
        echo "$additional_remotes"
        return 0
    fi
    return 1
}

# Display additional remotes information
display_additional_remotes() {
    local repo_path="$1"
    local current_branch="$2"
    local verbose="$3"

    local additional_remotes
    additional_remotes=$(get_additional_remotes "${repo_path}") || return 1

    echo
    echo "🔗 Additional Remotes:"

    while IFS= read -r remote_name; do
        [[ -z "$remote_name" ]] && continue

        if remote_info=$(get_remote_info "${repo_path}" "${remote_name}" "${current_branch}" "${verbose}"); then
            IFS='|' read -r remote_version remote_hash <<< "${remote_info}"

            if [[ "${verbose}" == "true" ]]; then
                echo "📡 ${remote_name}:        ${remote_version} (${remote_hash:0:8}) [${current_branch}]"
            else
                echo "📡 ${remote_name}:        ${remote_version} [${current_branch}]"
            fi

            # Compare local with this remote
            local remote_full_hash local_hash
            remote_full_hash=$(git -C "${repo_path}" rev-parse "${remote_name}/${current_branch}" 2>/dev/null)
            local_hash=$(git -C "${repo_path}" rev-parse HEAD 2>/dev/null)

            if [[ -n "$remote_full_hash" && -n "$local_hash" ]]; then
                if [[ "$local_hash" != "$remote_full_hash" ]]; then
                    echo "   Status:        ⚠️  Local differs from ${remote_name}"
                else
                    echo "   Status:        ✅ Up to date with ${remote_name}"
                fi
            fi
        else
            echo "📡 ${remote_name}:        Not accessible or missing branch [${current_branch}]"
        fi
    done <<< "$additional_remotes"
}

# Check if repository has worktrees and get worktree information
get_worktree_info() {
    local repo_path="$1"
    local verbose="$2"

    # Check if worktrees exist
    local worktree_list
    worktree_list=$(git -C "${repo_path}" worktree list --porcelain 2>/dev/null) || return 1

    # Count worktrees (more than 1 means we have additional worktrees)
    local worktree_count
    worktree_count=$(echo "${worktree_list}" | grep -c "^worktree " || echo "0")

    if [[ ${worktree_count} -le 1 ]]; then
        return 1  # No additional worktrees
    fi

    echo "${worktree_list}"
}

# Parse worktree information and create table data
parse_worktree_data() {
    local repo_path="$1"
    local worktree_list="$2"
    local upstream_branch="$3"
    local verbose="$4"

    local current_worktree=""
    local current_branch=""
    local current_head=""
    local current_locked=""
    local worktree_data=""

    while IFS= read -r line; do
        case "$line" in
            "worktree "*)
                # Save previous worktree data if exists
                if [[ -n "$current_worktree" ]]; then
                    worktree_data+="${current_worktree}|${current_branch}|${current_head}|${current_locked}"$'\n'
                fi

                # Start new worktree
                current_worktree="${line#worktree }"
                current_branch=""
                current_head=""
                current_locked=""
                ;;
            "HEAD "*)
                current_head="${line#HEAD }"
                ;;
            "branch "*)
                current_branch="${line#branch refs/heads/}"
                ;;
            "locked"*)
                current_locked="locked"
                ;;
            "detached")
                current_branch="HEAD (detached)"
                ;;
        esac
    done <<< "$worktree_list"

    # Don't forget the last worktree
    if [[ -n "$current_worktree" ]]; then
        worktree_data+="${current_worktree}|${current_branch}|${current_head}|${current_locked}"
    fi

    echo "$worktree_data"
}

# Generate worktree table
display_worktree_table() {
    local repo_path="$1"
    local upstream_branch="$2"
    local verbose="$3"

    local worktree_list
    worktree_list=$(get_worktree_info "${repo_path}" "${verbose}") || return 1

    local worktree_data
    worktree_data=$(parse_worktree_data "${repo_path}" "${worktree_list}" "${upstream_branch}" "${verbose}")

    echo
    echo "🌳 Git Worktrees:"
    echo

    # Collect all row data first to calculate proper column widths
    local rows=()
    local max_version=7 max_upstream=8 max_origin=6 max_status=6 max_branch=6
    local max_hash=4 max_locked=4 max_dir=9

    # Get current repository's absolute path for comparison
    local current_repo_path
    current_repo_path=$(cd "${repo_path}" && pwd)

    # Process each worktree to collect data and calculate max widths
    while IFS='|' read -r wt_path wt_branch wt_head wt_locked; do
        [[ -z "$wt_path" ]] && continue

        # Get local version and status for this worktree
        local wt_version wt_hash wt_status
        wt_version=$(git -C "${wt_path}" describe HEAD --tags --always 2>/dev/null || echo "unknown")
        wt_hash=$(git -C "${wt_path}" rev-parse HEAD 2>/dev/null || echo "unknown")

        # Check if worktree has modifications
        if has_local_modifications "${wt_path}"; then
            wt_status="Modified"
        else
            wt_status="Clean"
        fi

        # Compare with upstream
        local upstream_status="N/A"
        if [[ -n "$wt_branch" && "$wt_branch" != "HEAD (detached)" ]]; then
            local upstream_hash
            upstream_hash=$(git -C "${wt_path}" rev-parse "upstream/${upstream_branch}" 2>/dev/null)
            if [[ -n "$upstream_hash" ]]; then
                if [[ "$wt_hash" == "$upstream_hash" ]]; then
                    upstream_status="✅-Synced"
                else
                    upstream_status="⚠️ -Behind"
                fi
            else
                upstream_status="❌-Missing"
            fi
        fi

        # Compare with origin
        local origin_status="N/A"
        if [[ -n "$wt_branch" && "$wt_branch" != "HEAD (detached)" ]]; then
            local origin_hash
            origin_hash=$(git -C "${wt_path}" rev-parse "origin/${wt_branch}" 2>/dev/null)
            if [[ -n "$origin_hash" ]]; then
                if [[ "$wt_hash" == "$origin_hash" ]]; then
                    origin_status="✅-Synced"
                else
                    origin_status="⚠️ -Behind"
                fi
            else
                origin_status="❌-Missing"
            fi
        fi

        # Check if this is the current worktree and add marker
        local branch_display="$wt_branch"
        if [[ "$wt_path" == "$current_repo_path" ]]; then
            branch_display="${wt_branch} 📍"
        fi

        # Store row data
        local row_data="${wt_version}|${wt_hash:0:8}|${upstream_status}|${origin_status}|${wt_status}|${wt_locked:-unlocked}|${branch_display}|${wt_path}"
        rows+=("$row_data")

        # Update max widths (including the marker for branch display)
        [[ ${#wt_version} -gt $max_version ]] && max_version=${#wt_version}
        [[ ${#upstream_status} -gt $max_upstream ]] && max_upstream=${#upstream_status}
        [[ ${#origin_status} -gt $max_origin ]] && max_origin=${#origin_status}
        [[ ${#wt_status} -gt $max_status ]] && max_status=${#wt_status}
        [[ ${#branch_display} -gt $max_branch ]] && max_branch=${#branch_display}

        if [[ "${verbose}" == "true" ]]; then
            [[ ${#wt_hash} -gt $max_hash ]] && max_hash=${#wt_hash}
            [[ ${#wt_locked} -gt $max_locked ]] && max_locked=${#wt_locked}
            local dir_name=$(basename "${wt_path}")
            [[ ${#dir_name} -gt $max_dir ]] && max_dir=${#dir_name}
        fi

    done <<< "$worktree_data"

    # Print headers with calculated widths
    if [[ "${verbose}" == "true" ]]; then
        printf "%-${max_version}s  %-${max_upstream}s  %-${max_origin}s  %-${max_status}s  %-${max_branch}s  %-${max_hash}s  %-${max_dir}s  %-${max_locked}s\n" \
            "Version" "Upstream" "Origin" "Status" "Branch" "Hash" "Directory" "Lock"
        printf "%-${max_version}s  %-${max_upstream}s  %-${max_origin}s  %-${max_status}s  %-${max_branch}s  %-${max_hash}s  %-${max_dir}s  %-${max_locked}s\n" \
            "$(printf '%*s' $max_version | tr ' ' '-')" \
            "$(printf '%*s' $max_upstream | tr ' ' '-')" \
            "$(printf '%*s' $max_origin | tr ' ' '-')" \
            "$(printf '%*s' $max_status | tr ' ' '-')" \
            "$(printf '%*s' $max_branch | tr ' ' '-')" \
            "$(printf '%*s' $max_hash | tr ' ' '-')" \
            "$(printf '%*s' $max_dir | tr ' ' '-')" \
            "$(printf '%*s' $max_locked | tr ' ' '-')"
    else
        printf "%-${max_version}s  %-${max_upstream}s  %-${max_origin}s  %-${max_status}s  %-${max_branch}s\n" \
            "Version" "Upstream" "Origin" "Status" "Branch"
        printf "%-${max_version}s  %-${max_upstream}s  %-${max_origin}s  %-${max_status}s  %-${max_branch}s\n" \
            "$(printf '%*s' $max_version | tr ' ' '-')" \
            "$(printf '%*s' $max_upstream | tr ' ' '-')" \
            "$(printf '%*s' $max_origin | tr ' ' '-')" \
            "$(printf '%*s' $max_status | tr ' ' '-')" \
            "$(printf '%*s' $max_branch | tr ' ' '-')"
    fi

    # Print data rows with proper alignment
    for row in "${rows[@]}"; do
        IFS='|' read -r wt_version wt_hash upstream_status origin_status wt_status wt_locked branch_display wt_path <<< "$row"

        if [[ "${verbose}" == "true" ]]; then
            local dir_name=$(basename "${wt_path}")
            printf "%-${max_version}s  %-${max_upstream}s  %-${max_origin}s  %-${max_status}s  %-${max_branch}s  %-${max_hash}s  %-${max_dir}s  %-${max_locked}s\n" \
                "${wt_version}" "${upstream_status}" "${origin_status}" "${wt_status}" "${branch_display}" "${wt_hash}" "${dir_name}" "${wt_locked}"
        else
            printf "%-${max_version}s  %-${max_upstream}s  %-${max_origin}s  %-${max_status}s  %-${max_branch}s\n" \
                "${wt_version}" "${upstream_status}" "${origin_status}" "${wt_status}" "${branch_display}"
        fi
    done
}

# Format and display version information
display_version_info() {
    local repo_path="$1"
    local upstream_branch="$2"
    local verbose="$3"
    local show_all_remotes="$4"

    echo "=== Git Repository Version Information ==="
    echo "📁 Repository:     ${repo_path}"
    echo

    # Get local information
    local local_info current_branch local_version local_hash
    local_info=$(get_local_info "${repo_path}" "${verbose}")
    IFS='|' read -r local_version local_hash current_branch <<< "${local_info}"

    echo "📍 Current Branch: ${current_branch}"

    if [[ "${verbose}" == "true" ]]; then
        echo "🏠 Local Version:  ${local_version} (${local_hash:0:8})"
    else
        echo "🏠 Local Version:  ${local_version}"
    fi

    # Check for local modifications
    if has_local_modifications "${repo_path}"; then
        echo "⚠️  Status:         Modified (uncommitted changes)"
    else
        echo "✅ Status:         Clean"
    fi

    echo

    # Get upstream information
    if upstream_info=$(get_remote_info "${repo_path}" "upstream" "${upstream_branch}" "${verbose}"); then
        IFS='|' read -r upstream_version upstream_hash <<< "${upstream_info}"

        if [[ "${verbose}" == "true" ]]; then
            echo "⬆️  Upstream:      ${upstream_version} (${upstream_hash:0:8}) [${upstream_branch}]"
        else
            echo "⬆️  Upstream:      ${upstream_version} [${upstream_branch}]"
        fi

        # Compare local with upstream
        local upstream_full_hash
        upstream_full_hash=$(git -C "${repo_path}" rev-parse "upstream/${upstream_branch}" 2>/dev/null)
        if [[ "${local_hash:-$(git -C "${repo_path}" rev-parse HEAD)}" != "${upstream_full_hash}" ]]; then
            echo "   Status:        ⚠️  Local differs from upstream"
        else
            echo "   Status:        ✅ Up to date with upstream"
        fi
        echo
    else
        echo "⬆️  Upstream:      Not configured or unreachable"
        echo
    fi

    # Get origin information
    if origin_info=$(get_remote_info "${repo_path}" "origin" "${current_branch}" "${verbose}"); then
        IFS='|' read -r origin_version origin_hash <<< "${origin_info}"

        if [[ "${verbose}" == "true" ]]; then
            echo "🌐 Origin:        ${origin_version} (${origin_hash:0:8}) [${current_branch}]"
        else
            echo "🌐 Origin:        ${origin_version} [${current_branch}]"
        fi

        # Compare local with origin
        local origin_full_hash
        origin_full_hash=$(git -C "${repo_path}" rev-parse "origin/${current_branch}" 2>/dev/null)
        if [[ "${local_hash:-$(git -C "${repo_path}" rev-parse HEAD)}" != "${origin_full_hash}" ]]; then
            echo "   Status:        ⚠️  Local differs from origin"
        else
            echo "   Status:        ✅ Up to date with origin"
        fi
    else
        echo "🌐 Origin:        Not configured or unreachable"
    fi

    # Display additional remotes if --all flag is used
    if [[ "${show_all_remotes}" == "true" ]]; then
        display_additional_remotes "${repo_path}" "${current_branch}" "${verbose}" || true
    fi

    # Display worktree information if worktrees exist
    display_worktree_table "${repo_path}" "${upstream_branch}" "${verbose}" || true
}

# Main function
git_repo_version() {
    # Check for help flag first, before any processing
    for arg in "$@"; do
        if [[ "$arg" == "-h" || "$arg" == "--help" ]]; then
            show_usage
            return 0
        fi
    done

    # Parse arguments
    local args_result
    args_result=$(parse_arguments "$@")
    IFS='|' read -r repo_path upstream_branch verbose show_all_remotes <<< "${args_result}"

    # Validate environment and get absolute path
    local abs_repo_path
    abs_repo_path=$(validate_git_repo "${repo_path}") || return 1

    # Display version information
    display_version_info "${abs_repo_path}" "${upstream_branch}" "${verbose}" "${show_all_remotes}"
}

# Auto-run when executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    git_repo_version "$@"
fi