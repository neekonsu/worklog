#!/bin/bash

# extract_gitlog_summary.sh
# Script to extract and summarize git log information for worklog documentation
# Author: Generated for Neekon Saadat worklog processing
# Date: July 20, 2025
#
# Usage: extract_gitlog_summary.sh <working_directory> <output_directory>
# This script will:
# 1. Change to the working directory (must be a git repository)
# 2. Generate a gitlog file using: git log --author="neekon" --author="saadat" --pretty=format:"%H%nAuthor: %an <%ae>%nDate: %ad%nSubject: %s%n%b" --patch --date=local
# 3. Analyze the gitlog and save results to the output directory
# Note: Excludes html and latex folders to avoid Doxygen-generated content

set -e  # Exit on any error

# Check if required arguments are provided
if [[ $# -lt 2 ]]; then
    echo "Usage: $0 <working_directory> <output_directory> [start_date] [end_date]"
    echo "Example: $0 /path/to/git/repo ./analysis_output"
    echo "Example: $0 /path/to/git/repo ./analysis_output \"2025-08-01\" \"2025-08-31\""
    echo ""
    echo "Arguments:"
    echo "  working_directory: Path to git repository to analyze"
    echo "  output_directory:  Directory where analysis results will be saved"
    echo "  start_date:       Optional start date (YYYY-MM-DD format)"
    echo "  end_date:         Optional end date (YYYY-MM-DD format)"
    echo ""
    echo "The script will generate a gitlog from the working directory using:"
    echo "git log --author=\"neekon\" --author=\"saadat\" --pretty=format:\"%H%nAuthor: %an <%ae>%nDate: %ad%nSubject: %s%n%b\" --patch --date=local"
    echo "with exclusions for html and latex folders (Doxygen-generated content)."
    echo "If date range is specified, --since and --until will be added to the git log command."
    exit 1
fi

# Configuration - convert to absolute paths
WORKING_DIR="$1"
OUTPUT_DIR="$2"
START_DATE="$3"
END_DATE="$4"

# Convert to absolute path if needed
if [[ ! "$WORKING_DIR" = /* ]]; then
    WORKING_DIR="$(pwd)/$WORKING_DIR"
fi

if [[ ! "$OUTPUT_DIR" = /* ]]; then
    OUTPUT_DIR="$(pwd)/$OUTPUT_DIR"
fi

echo "=== Git Log Analysis Script ==="
echo "Working directory: $WORKING_DIR"
echo "Output directory: $OUTPUT_DIR"
echo

# Validate working directory exists and is a git repository
if [[ ! -d "$WORKING_DIR" ]]; then
    echo "Error: Working directory '$WORKING_DIR' does not exist!"
    exit 1
fi

if [[ ! -d "$WORKING_DIR/.git" ]]; then
    echo "Error: Working directory '$WORKING_DIR' is not a git repository!"
    exit 1
fi

# Create output directory for analysis results
mkdir -p "$OUTPUT_DIR"

# Generate gitlog file from the working directory
cd "$WORKING_DIR"

# Extract repository name and show available branches
REPO_NAME=$(basename "$(git rev-parse --show-toplevel)")
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)

echo "Available branches in repository '$REPO_NAME':"
echo "=========================================="

# Get all branches (local and remote) and format them nicely
git branch -a | sed 's/^..//' | sed 's/remotes\/origin\///' | sort -u | grep -v '^HEAD' > /tmp/branches.txt

# Number the branches and show current branch
i=1
declare -a branches
while IFS= read -r branch; do
    branches[$i]=$branch
    if [[ "$branch" == "$CURRENT_BRANCH" ]]; then
        echo "$i) $branch (current)"
    else
        echo "$i) $branch"
    fi
    ((i++))
done < /tmp/branches.txt

echo
echo -n "Select branch to analyze (1-$((i-1))) or press Enter for current branch [$CURRENT_BRANCH]: "
read -r choice

# Validate and set branch selection
if [[ -z "$choice" ]]; then
    BRANCH_NAME="$CURRENT_BRANCH"
    echo "Using current branch: $BRANCH_NAME"
elif [[ "$choice" =~ ^[0-9]+$ ]] && [[ "$choice" -ge 1 ]] && [[ "$choice" -lt "$i" ]]; then
    BRANCH_NAME="${branches[$choice]}"
    echo "Selected branch: $BRANCH_NAME"
    
    # Switch to selected branch if it's different from current
    if [[ "$BRANCH_NAME" != "$CURRENT_BRANCH" ]]; then
        echo "Switching to branch '$BRANCH_NAME'..."
        git checkout "$BRANCH_NAME" || {
            echo "Error: Could not switch to branch '$BRANCH_NAME'"
            echo "Using current branch: $CURRENT_BRANCH"
            BRANCH_NAME="$CURRENT_BRANCH"
        }
    fi
else
    echo "Invalid selection. Using current branch: $CURRENT_BRANCH"
    BRANCH_NAME="$CURRENT_BRANCH"
fi

echo
echo "Generating gitlog from repository on branch '$BRANCH_NAME'..."
echo "Excluding html and latex folders to avoid Doxygen-generated content..."
rm -f /tmp/branches.txt

# Build git log command with optional date filtering and exclusions
GIT_LOG_CMD="git log --author=\"Neekon\" --author=\"neekon\" --author=\"Saadat\" --author=\"saadat\""
if [[ -n "$START_DATE" && -n "$END_DATE" ]]; then
    GIT_LOG_CMD="$GIT_LOG_CMD --since=\"$START_DATE\" --until=\"$END_DATE\""
    echo "Filtering commits from $START_DATE to $END_DATE"
elif [[ -n "$START_DATE" ]]; then
    GIT_LOG_CMD="$GIT_LOG_CMD --since=\"$START_DATE\""
    echo "Filtering commits since $START_DATE"
elif [[ -n "$END_DATE" ]]; then
    GIT_LOG_CMD="$GIT_LOG_CMD --until=\"$END_DATE\""
    echo "Filtering commits until $END_DATE"
fi

# Define path exclusions for Doxygen-generated content
PATH_EXCLUSIONS="-- . ':!**/html/**' ':!**/latex/**' ':!html/**' ':!latex/**' ':!*html*' ':!*latex*'"

# Create temporary gitlog to extract date range for filename
TEMP_GITLOG="/tmp/temp_gitlog.txt"
eval "$GIT_LOG_CMD --pretty=format:\"%H%nAuthor: %an <%ae>%nDate: %ad%nSubject: %s%n%b\" --patch --diff-filter=M --date=local $PATH_EXCLUSIONS" > "$TEMP_GITLOG"

# Extract earliest and latest dates from the gitlog
if [[ -s "$TEMP_GITLOG" ]]; then
    EARLIEST_DATE=$(grep "^Date:" "$TEMP_GITLOG" | tail -1 | sed 's/Date: [A-Za-z]* \([A-Za-z]* [0-9][0-9]*\) .* \([0-9]\{4\}\)/\1 \2/')
    LATEST_DATE=$(grep "^Date:" "$TEMP_GITLOG" | head -1 | sed 's/Date: [A-Za-z]* \([A-Za-z]* [0-9][0-9]*\) .* \([0-9]\{4\}\)/\1 \2/')
    
    # Convert dates to numeric format (DDMMYYYY)
    EARLIEST_NUMERIC=$(date -jf "%b %d %Y" "$EARLIEST_DATE" "+%d%m%Y" 2>/dev/null || echo "01012025")
    LATEST_NUMERIC=$(date -jf "%b %d %Y" "$LATEST_DATE" "+%d%m%Y" 2>/dev/null || echo "01012025")
    
    # Create formatted folder name: <repo>-<branch>-<earliest><latest>
    FOLDER_NAME="${REPO_NAME}-${BRANCH_NAME}-${EARLIEST_NUMERIC}${LATEST_NUMERIC}"
    
    # Create filename: gitlog-<repo>-<branch>-<earliest><latest>.txt
    GITLOG_FILENAME="gitlog-${REPO_NAME}-${BRANCH_NAME}-${EARLIEST_NUMERIC}${LATEST_NUMERIC}.txt"
else
    # No commits found, use default naming
    FOLDER_NAME="${REPO_NAME}-${BRANCH_NAME}-empty"
    GITLOG_FILENAME="gitlog-${REPO_NAME}-${BRANCH_NAME}-empty.txt"
fi

# Create the formatted output folder
FORMATTED_OUTPUT_DIR="$OUTPUT_DIR/$FOLDER_NAME"
mkdir -p "$FORMATTED_OUTPUT_DIR"

GITLOG_FILE="$FORMATTED_OUTPUT_DIR/$GITLOG_FILENAME"

# Copy the temporary gitlog to the final location
cp "$TEMP_GITLOG" "$GITLOG_FILE"
rm "$TEMP_GITLOG"

# Return to the directory where the script was called
cd - > /dev/null

echo "Gitlog generated: $GITLOG_FILE"
echo "Processing gitlog data..."

# Function to filter commits by author (case insensitive for neekon or saadat)
# This provides script-level filtering if the git log wasn't pre-filtered
filter_by_author() {
    grep -i -B 3 -A 10 "Author:.*\(Neekon\|neekon\|Saadat\|saadat\)"
}

echo "1. Extracting unique commit dates (filtering for Neekon/Saadat commits)..."
# COMMAND BREAKDOWN: Extract all unique dates from the gitlog and sort them
# grep "^Date:" "$GITLOG_FILE" 
#   - grep: search for pattern in file
#   - "^Date:": regex pattern matching lines starting with "Date:"
#   - ^: beginning of line anchor
#   - "$GITLOG_FILE": input file variable
# | sed 's/Date:.*\([A-Za-z]* [0-9][0-9]\).*/\1/'
#   - |: pipe output from grep to sed
#   - sed: stream editor for filtering and transforming text
#   - 's/PATTERN/REPLACEMENT/': substitute command
#   - Date:.*\([A-Za-z]* [0-9][0-9]\).*: capture group with month + 2-digit day
#   - \( \): create capture group for later reference
#   - .*: match any characters (greedy)
#   - [A-Za-z]*: match any month name (Jan, Feb, etc.)
#   - [0-9][0-9]: match exactly 2 digits for day
#   - \1: reference to first capture group in replacement
# | sort -u
#   - |: pipe sed output to sort
#   - sort: arrange lines in order
#   - -u: unique flag, remove duplicate lines
# > "$FORMATTED_OUTPUT_DIR/commit_dates.txt"
#   - >: redirect output to file (overwrite)
filter_by_author < "$GITLOG_FILE" | grep "^Date:" | sed 's/Date: [A-Za-z]* \([A-Za-z]* [0-9][0-9]*\).*/\1/' | sort -u > "$FORMATTED_OUTPUT_DIR/commit_dates.txt"
echo "Found dates:"
cat "$FORMATTED_OUTPUT_DIR/commit_dates.txt"
echo

echo "2. Counting total commits (Neekon/Saadat only)..."
# COMMAND BREAKDOWN: Count the total number of commits in the log for Neekon/Saadat
# COMMIT_COUNT=$(filter_by_author < "$GITLOG_FILE" | grep -c "^[0-9a-f]\{40\}")
#   - filter_by_author: apply author filtering first
#   - COMMIT_COUNT=: assign result to variable
#   - $( ): command substitution - execute command and capture output
#   - grep: search for pattern in file
#   - -c: count flag, return number of matching lines instead of lines themselves
#   - "^commit": regex pattern matching lines starting with "commit"
#   - ^: beginning of line anchor
COMMIT_COUNT=$(filter_by_author < "$GITLOG_FILE" | grep -c "^[0-9a-f]\{40\}")
echo "Total commits: $COMMIT_COUNT"
echo

echo "3. Extracting commit summaries by date..."
# For each date, extract commit information
while read -r date; do
    echo "Processing commits for $date..."
    
    # COMMAND BREAKDOWN: Extract commit messages and diffs for this date (Neekon/Saadat only)
    # Enhanced extraction to include full commit content with diffs, limited to prevent huge files
    # from autogenerated code. Each commit is limited to 500 lines to keep files manageable.
    #   - filter_by_author: apply author filtering first
    #   - awk: process each commit block separately to apply line limits per commit
    #   - /^[0-9a-f]{40}$/: pattern to identify commit hash lines (start of new commit)
    #   - "Date:.*$date": pattern matching "Date:" followed by any chars, then variable $date
    
    # Extract commits for this date by simply filtering the main gitlog
    # This preserves all original formatting and diff content
    filter_by_author < "$GITLOG_FILE" | awk '
    BEGIN { 
        in_target_commit = 0
        commit_buffer = ""
        target_date = "'"$date"'"
    }
    /^[0-9a-f]{40}$/ { 
        # New commit hash found - output previous commit if it was for target date
        if (in_target_commit && commit_buffer != "") {
            print commit_buffer
        }
        # Reset for new commit
        in_target_commit = 0
        commit_buffer = $0 "\n"
        next
    }
    /^Date:/ {
        # Check if this commit is for our target date
        if ($0 ~ target_date) {
            in_target_commit = 1
        }
        commit_buffer = commit_buffer $0 "\n"
        next
    }
    {
        # Add all lines to buffer - we will filter by date at output time
        commit_buffer = commit_buffer $0 "\n"
    }
    END {
        # Output final commit if it was for target date
        if (in_target_commit && commit_buffer != "") {
            print commit_buffer
        }
    }
    ' > "$FORMATTED_OUTPUT_DIR/commits_$date.txt"
    
    # COMMAND BREAKDOWN: Count commits for this date (Neekon/Saadat only)
    # date_commits=$(filter_by_author < "$GITLOG_FILE" | grep -c "Date:.*$date" || echo "0")
    #   - filter_by_author: apply author filtering first
    #   - date_commits=: assign result to variable
    #   - $( ): command substitution
    #   - grep -c: count matching lines
    #   - "Date:.*$date": same pattern as above
    #   - || echo "0": if grep fails (no matches), output "0" instead
    date_commits=$(filter_by_author < "$GITLOG_FILE" | grep -c "Date:.*$date" || echo "0")
    echo "  - $date_commits commits found"
    
done < "$FORMATTED_OUTPUT_DIR/commit_dates.txt"
echo

echo "4. Extracting notable file changes and samples..."

# COMMAND BREAKDOWN: Extract testing/documentation files
echo "Checking for testing and documentation files..."
NOTABLE_FILES=("testing_notes.md" "Gen_3_0_Robustness_Testing_Strategy" "Memory_Safety_Risk_Report.md" "CLAUDE.md" "Doxyfile" "REMARKS.md" "README.md" "CHANGELOG.md")

for file in "${NOTABLE_FILES[@]}"; do
    if grep -q "$file" "$GITLOG_FILE"; then
        echo "  - Found $file"
    fi
done

# Extract any markdown files created/modified
echo "Checking for markdown files..."
if grep -q "\.md" "$GITLOG_FILE"; then
    echo "  - Found markdown file changes"
fi

# COMMAND BREAKDOWN: Extract recent documentation work (last 2 dates found)
echo "Checking for recent documentation work..."
# Get the last 2 unique dates and create a pattern for them
RECENT_DATES=$(tail -2 "$FORMATTED_OUTPUT_DIR/commit_dates.txt" | paste -sd'|' -)
if [[ -n "$RECENT_DATES" ]]; then
    echo "Found recent commits from dates: $RECENT_DATES"
fi

echo
echo "5. Creating summary report..."

# Generate a summary report
{
    echo "# Git Log Analysis Summary"
    echo "Generated on: $(date)"
    echo "Source file: $GITLOG_FILE"
    echo
    echo "## Date Range Analysis"
    echo "Dates with commits:"
    cat "$FORMATTED_OUTPUT_DIR/commit_dates.txt" | sed 's/^/- /'
    echo
    echo "Total commits: $COMMIT_COUNT"
    echo
    echo "## Daily Commit Breakdown"
    # COMMAND BREAKDOWN: Loop through dates and count commits for each
    # while read -r date; do ... done < "$FORMATTED_OUTPUT_DIR/commit_dates.txt"
    #   - while: loop construct
    #   - read -r date: read one line from input, assign to variable 'date'
    #   - -r: raw mode - don't interpret backslashes as escape characters
    #   - date: variable name to store each line
    #   - do ... done: loop body delimiters
    #   - < "$FORMATTED_OUTPUT_DIR/commit_dates.txt": redirect file as input to while loop
    while read -r date; do
        date_commits=$(filter_by_author < "$GITLOG_FILE" | grep -c "Date:.*$date" || echo "0")
        echo "- $date: $date_commits commits"
    done < "$FORMATTED_OUTPUT_DIR/commit_dates.txt"
    echo
    echo "## Key Files Modified"
    echo "Major documentation and analysis files created/modified:"
    
    # Check for key files mentioned in commits
    for file in "${NOTABLE_FILES[@]}"; do
        if grep -q "$file" "$GITLOG_FILE"; then
            # Try to find the date when this file was modified (Neekon/Saadat commits only)
            FIRST_DATE=$(filter_by_author < "$GITLOG_FILE" | grep -B 10 -A 1 "$file" | grep "Date:" | head -1 | sed 's/Date: [A-Za-z]* \([A-Za-z]* [0-9][0-9]*\).*/\1/' || echo "Unknown date")
            case "$file" in
                "testing_notes.md") echo "- $file ($FIRST_DATE) - System vulnerability documentation" ;;
                "Gen_3_0_Robustness_Testing_Strategy") echo "- $file.md/.pdf ($FIRST_DATE) - Comprehensive testing strategy" ;;
                "Memory_Safety_Risk_Report.md") echo "- $file ($FIRST_DATE) - Memory vulnerability analysis" ;;
                "CLAUDE.md") echo "- $file ($FIRST_DATE) - AI analysis integration" ;;
                "Doxyfile") echo "- $file ($FIRST_DATE) - Documentation generation configuration" ;;
                "REMARKS.md") echo "- $file ($FIRST_DATE) - Comprehensive code analysis remarks" ;;
                *) echo "- $file ($FIRST_DATE) - Documentation file" ;;
            esac
        fi
    done
    
} > "$FORMATTED_OUTPUT_DIR/analysis_summary.md"

echo "6. Analysis complete!"
echo
echo "Results saved to $FORMATTED_OUTPUT_DIR/"
echo "Files created:"
ls -la "$FORMATTED_OUTPUT_DIR/"
echo
echo "View summary: cat $FORMATTED_OUTPUT_DIR/analysis_summary.md"
echo "View individual day commits: cat $FORMATTED_OUTPUT_DIR/commits_*.txt"
