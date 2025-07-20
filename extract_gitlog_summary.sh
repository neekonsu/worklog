#!/bin/bash

# extract_gitlog_summary.sh
# Script to extract and summarize git log information for worklog documentation
# Author: Generated for Neekon Saadat worklog processing
# Date: July 20, 2025

set -e  # Exit on any error

# Configuration
GITLOG_FILE="gitlog_Jul142025-Jul192025.txt"
OUTPUT_DIR="./gitlog_analysis"

echo "=== Git Log Analysis Script ==="
echo "Processing file: $GITLOG_FILE"
echo

# Check if gitlog file exists
if [[ ! -f "$GITLOG_FILE" ]]; then
    echo "Error: $GITLOG_FILE not found!"
    exit 1
fi

# Create output directory for analysis results
mkdir -p "$OUTPUT_DIR"

echo "1. Extracting unique commit dates..."
# COMMAND BREAKDOWN: Extract all unique dates from the gitlog and sort them
# grep "^Date:" "$GITLOG_FILE" 
#   - grep: search for pattern in file
#   - "^Date:": regex pattern matching lines starting with "Date:"
#   - ^: beginning of line anchor
#   - "$GITLOG_FILE": input file variable
# | sed 's/Date:.*\(Jul [0-9][0-9]\).*/\1/'
#   - |: pipe output from grep to sed
#   - sed: stream editor for filtering and transforming text
#   - 's/PATTERN/REPLACEMENT/': substitute command
#   - Date:.*\(Jul [0-9][0-9]\).*: capture group with Jul + 2 digits
#   - \( \): create capture group for later reference
#   - .*: match any characters (greedy)
#   - [0-9][0-9]: match exactly 2 digits
#   - \1: reference to first capture group in replacement
# | sort -u
#   - |: pipe sed output to sort
#   - sort: arrange lines in order
#   - -u: unique flag, remove duplicate lines
# > "$OUTPUT_DIR/commit_dates.txt"
#   - >: redirect output to file (overwrite)
grep "^Date:" "$GITLOG_FILE" | sed 's/Date:.*\(Jul [0-9][0-9]\).*/\1/' | sort -u > "$OUTPUT_DIR/commit_dates.txt"
echo "Found dates:"
cat "$OUTPUT_DIR/commit_dates.txt"
echo

echo "2. Counting total commits..."
# COMMAND BREAKDOWN: Count the total number of commits in the log
# COMMIT_COUNT=$(grep -c "^commit" "$GITLOG_FILE")
#   - COMMIT_COUNT=: assign result to variable
#   - $( ): command substitution - execute command and capture output
#   - grep: search for pattern in file
#   - -c: count flag, return number of matching lines instead of lines themselves
#   - "^commit": regex pattern matching lines starting with "commit"
#   - ^: beginning of line anchor
#   - "$GITLOG_FILE": input file variable
COMMIT_COUNT=$(grep -c "^commit" "$GITLOG_FILE")
echo "Total commits: $COMMIT_COUNT"
echo

echo "3. Extracting commit summaries by date..."
# For each date, extract commit information
while read -r date; do
    echo "Processing commits for $date..."
    
    # COMMAND BREAKDOWN: Extract commit messages and basic info for this date
    # grep -A 5 -B 2 "Date:.*$date" "$GITLOG_FILE" > "$OUTPUT_DIR/commits_$date.txt" || true
    #   - grep: search for pattern in file
    #   - -A 5: After context - include 5 lines after each match
    #   - -B 2: Before context - include 2 lines before each match
    #   - "Date:.*$date": pattern matching "Date:" followed by any chars, then variable $date
    #   - .*: match any characters between "Date:" and the date
    #   - $date: shell variable containing the date being processed
    #   - "$GITLOG_FILE": input file variable
    #   - > "$OUTPUT_DIR/commits_$date.txt": redirect output to date-specific file
    #   - || true: logical OR with true - prevents script exit if grep finds no matches
    grep -A 5 -B 2 "Date:.*$date" "$GITLOG_FILE" > "$OUTPUT_DIR/commits_$date.txt" || true
    
    # COMMAND BREAKDOWN: Count commits for this date
    # date_commits=$(grep -c "Date:.*$date" "$GITLOG_FILE" || echo "0")
    #   - date_commits=: assign result to variable
    #   - $( ): command substitution
    #   - grep -c: count matching lines
    #   - "Date:.*$date": same pattern as above
    #   - || echo "0": if grep fails (no matches), output "0" instead
    date_commits=$(grep -c "Date:.*$date" "$GITLOG_FILE" || echo "0")
    echo "  - $date_commits commits found"
    
done < "$OUTPUT_DIR/commit_dates.txt"
echo

echo "4. Extracting specific file changes and samples..."

# COMMAND BREAKDOWN: Extract July 18 testing notes creation (if exists)
echo "Checking for July 18 testing notes..."
# if grep -q "testing_notes.md" "$GITLOG_FILE"; then
#   - if: conditional statement
#   - grep: search for pattern
#   - -q: quiet flag - suppress output, only return exit status (0=found, 1=not found)
#   - "testing_notes.md": literal string to search for
if grep -q "testing_notes.md" "$GITLOG_FILE"; then
    echo "  - Found testing_notes.md creation"
    # COMMAND BREAKDOWN: Extract diff context for testing notes file
    # grep -B 5 -A 30 "diff --git.*testing_notes.md" "$GITLOG_FILE" | head -30 > "$OUTPUT_DIR/jul18_testing_notes.txt" || true
    #   - grep -B 5 -A 30: 5 lines before, 30 lines after the match
    #   - "diff --git.*testing_notes.md": pattern matching git diff header for the file
    #   - diff --git: literal git diff header start
    #   - .*: any characters between header and filename
    #   - | head -30: pipe to head, limit output to first 30 lines
    #   - head: command to show first N lines
    #   - -30: show first 30 lines
    #   - > "$OUTPUT_DIR/jul18_testing_notes.txt": redirect to output file
    #   - || true: prevent script failure if no matches found
    grep -B 5 -A 30 "diff --git.*testing_notes.md" "$GITLOG_FILE" | head -30 > "$OUTPUT_DIR/jul18_testing_notes.txt" || true
fi

# COMMAND BREAKDOWN: Extract July 17 robustness testing strategy changes
echo "Checking for July 17 robustness strategy..."
if grep -q "Gen_3_0_Robustness_Testing_Strategy" "$GITLOG_FILE"; then
    echo "  - Found robustness testing strategy files"
    # COMMAND BREAKDOWN: Extract robustness strategy diff with limited output
    # grep -A 10 "diff --git.*Gen_3_0_Robustness_Testing_Strategy.md" "$GITLOG_FILE" | head -15 > "$OUTPUT_DIR/jul17_robustness_diff.txt" || true
    #   - grep -A 10: search and include 10 lines after match
    #   - "diff --git.*Gen_3_0_Robustness_Testing_Strategy.md": pattern for git diff of specific file
    #   - .*: wildcard for path between diff --git and filename
    #   - | head -15: pipe to head, show only first 15 lines of grep output
    #   - This combination limits potentially large diff output to manageable size
    grep -A 10 "diff --git.*Gen_3_0_Robustness_Testing_Strategy.md" "$GITLOG_FILE" | head -15 > "$OUTPUT_DIR/jul17_robustness_diff.txt" || true
fi

# COMMAND BREAKDOWN: Extract July 16 memory safety reports
echo "Checking for July 16 memory safety reports..."
if grep -q "Memory_Safety_Risk_Report.md" "$GITLOG_FILE"; then
    echo "  - Found memory safety risk report"
    # COMMAND BREAKDOWN: Extract memory safety report context
    # grep -A 20 "Updated devin-generated reports" "$GITLOG_FILE" | head -15 > "$OUTPUT_DIR/jul16_memory_reports.txt" || true
    #   - grep -A 20: search for pattern and include 20 lines after match
    #   - "Updated devin-generated reports": literal string from commit message
    #   - | head -15: pipe to head, limit to 15 lines (smaller than -A 20)
    #   - This gets commit context but limits output size for readability
    grep -A 20 "Updated devin-generated reports" "$GITLOG_FILE" | head -15 > "$OUTPUT_DIR/jul16_memory_reports.txt" || true
fi

# COMMAND BREAKDOWN: Extract July 14-15 doxygen and documentation work
echo "Checking for July 14-15 documentation work..."
# grep -A 10 -B 2 "Date:.*Jul 15\|Date:.*Jul 14" "$GITLOG_FILE" > "$OUTPUT_DIR/jul14_15_docs.txt" || true
#   - grep: search for pattern
#   - -A 10 -B 2: include 10 lines after and 2 lines before each match
#   - "Date:.*Jul 15\|Date:.*Jul 14": compound pattern using alternation
#   - Date:.*Jul 15: match "Date:" followed by any chars, then "Jul 15"
#   - \|: alternation operator (logical OR) - escaped pipe for literal OR
#   - Date:.*Jul 14: second pattern for July 14 dates
#   - This pattern matches commits from either July 14 OR July 15
grep -A 10 -B 2 "Date:.*Jul 15\|Date:.*Jul 14" "$GITLOG_FILE" > "$OUTPUT_DIR/jul14_15_docs.txt" || true

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
    cat "$OUTPUT_DIR/commit_dates.txt" | sed 's/^/- /'
    echo
    echo "Total commits: $COMMIT_COUNT"
    echo
    echo "## Daily Commit Breakdown"
    # COMMAND BREAKDOWN: Loop through dates and count commits for each
    # while read -r date; do ... done < "$OUTPUT_DIR/commit_dates.txt"
    #   - while: loop construct
    #   - read -r date: read one line from input, assign to variable 'date'
    #   - -r: raw mode - don't interpret backslashes as escape characters
    #   - date: variable name to store each line
    #   - do ... done: loop body delimiters
    #   - < "$OUTPUT_DIR/commit_dates.txt": redirect file as input to while loop
    while read -r date; do
        date_commits=$(grep -c "Date:.*$date" "$GITLOG_FILE" || echo "0")
        echo "- $date: $date_commits commits"
    done < "$OUTPUT_DIR/commit_dates.txt"
    echo
    echo "## Key Files Modified"
    echo "Major documentation and analysis files created/modified:"
    
    # Check for key files mentioned in commits
    if grep -q "testing_notes.md" "$GITLOG_FILE"; then
        echo "- testing_notes.md (July 18) - System vulnerability documentation"
    fi
    if grep -q "Gen_3_0_Robustness_Testing_Strategy" "$GITLOG_FILE"; then
        echo "- Gen_3_0_Robustness_Testing_Strategy.md/.pdf (July 17) - Comprehensive testing strategy"
    fi
    if grep -q "Memory_Safety_Risk_Report.md" "$GITLOG_FILE"; then
        echo "- Memory_Safety_Risk_Report.md (July 16) - Memory vulnerability analysis"
    fi
    if grep -q "CLAUDE.md" "$GITLOG_FILE"; then
        echo "- CLAUDE.md (July 16) - AI analysis integration"
    fi
    if grep -q "Doxyfile" "$GITLOG_FILE"; then
        echo "- Doxyfile (July 14) - Documentation generation configuration"
    fi
    if grep -q "REMARKS.md" "$GITLOG_FILE"; then
        echo "- REMARKS.md (July 14) - Comprehensive code analysis remarks"
    fi
    
} > "$OUTPUT_DIR/analysis_summary.md"

echo "6. Analysis complete!"
echo
echo "Results saved to $OUTPUT_DIR/"
echo "Files created:"
ls -la "$OUTPUT_DIR/"
echo
echo "View summary: cat $OUTPUT_DIR/analysis_summary.md"
echo "View individual day commits: cat $OUTPUT_DIR/commits_*.txt"
