#!/bin/bash
# Neekon Saadat - Personal Worklog Script, Prints git log with diffs since date until date, excluding doxygen html and latex directories 
git log -p --since='Jul 14 2025' --until='Jul 19 2025' -- . ':!html' ':!latex' >> ../worklog/gitlog_Jul142025-Jul192025.txt
