#Inquis Gen 2 - Gen 3 Codebase Suggestions for Zach S.
*The following suggestions are derived from code reviewed in the main branch of inquis_gen_2_2 <877e567d7b8383b5dc6bacf775bbc0a010b0521e> and inquis_gen_3_0 <9dfa6d65ccb128b5cd307f8082603f34d296797b>*

**Process:** 1. Read all functions and make commentary in this file or grab callgraphs/screenshots of code and collect into google slides presentation. 2. Organize remarks into slideshow and consolidate items originating from the same module or repetitive patterns that span multiple modules 3. Pull main and branch to implement all changes, then review PR with Zach.

## GEN3
---
### Condensed report on dead code to follow up later
- CLI commands are not dead, they are accessed via function pointer dispatch which Zach implemented through macros
- **BBStr API**: bbstr_list_del_matches, bbstr_join, hex_dump, string_buffer_check -> All dead code
- **SD Card API**: sd_card_read_file_binary, sd_card_open_read_only
- 
---
### CMS
#### CLI
**Questions:**
- 81 what is cfg_overload for
- _<funName> -> local and <funName> -> global?
- 85 n t s to check sd_card_mount() and see why/if it is okay to emit non-blocking error if error thrown
- 101 n t s to check check_string_allocates(0,0) if the check is safe / comprehensive for potential string memory leaks
- 96 config_file_contents bbstr not deleted in else branch
- 115 CMD_CHECK_IS is a redundant assert (we need only one system wide realistically) -> CMD_CHECK_IS leads back to a function in CLI; couldn't we call that printf directly with a conditional?
- 117 What is GPIO_Typedef; what is it for
- 120 CMD_CHECK_IS used instead of if (...) {emit_log_comment_record(...)} -> We should have one way to handle errors visible to all modules; should even be a separate module
- n t s to check whether 'function pointer dispatch' is a safe way to define the cli; pointers are dynamically allocated, are they sequential or reserved by name?
- 110 _cmd_gpio() unsafe, no typechecks for argv contents when argc matches expected count; argc keys type of gpio command, assumes argv is correct after this point; add checks
- 151 _cmd_led() unsafe; add typechecks to argv
- 183 n t s to give each cli command a docstring which covers the subcommands; subcommands keyed by argc, best to list what each argc does for user
- 192 what is the purpose of distinguishing argc 3 and 4; the logic is the same
- n t s in cli, ever command should begin with type/value checks on all args; all commands assume contents are appropriate if argc is within range.
- n t s what does pet_watchdog exist for
- 280 done never toggled in loop; only break called. should toggle at some point
- 275 last_time should be set to get_time_ms
- 280 what happens if buffer filled before 500ms? Perhaps unlikely (check sample freq) but inquis_assert could just be replaced with a loopback to make this a rolling 250 sample buffer given we just sample until we can average 500ms.
- 422 including but not limited to this line, add checks for arg inputs; better to catch ourselves than letting atoi or other functions fail
- 438 i not incremented; was this supposed to be a temp change? suggest revert
- 450 _setup_audio implements loading clot audio; suggest renaming, reimplementing, or removing to reflect function name.
- 
[15h10 22 aug 2025 ~ faster to drop these questions and comments into powerpoint from the getgo]
[15h59 22 au 2025 ~ leaving textual commentary and oneliners here and using slides for visual content like doxygen graphs] 
**Suggestions:**

#### LOG
**Questions:**
- note to self to check where emit_log_error_once is called; may be unsafe given warning about static/dynamic string usage
- note to self to make suggestion regarding base case of empty comment in emit_log_comment_record, which returns instead of emitting associated default comment, allowing for accidentally implementing silent errors (should not be possible)
- 
**Suggestions:**

### HANDLE

### COMMON
