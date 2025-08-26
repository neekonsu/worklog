#Inquis Gen 2 - Gen 3 Codebase Suggestions for Zach S.
*The following suggestions are derived from code reviewed in the main branch of inquis_gen_2_2 <877e567d7b8383b5dc6bacf775bbc0a010b0521e> and inquis_gen_3_0 <9dfa6d65ccb128b5cd307f8082603f34d296797b>*

**Process:** 1. Read all functions and make commentary in this file or grab callgraphs/screenshots of code and collect into google slides presentation. 2. Organize remarks into slideshow and consolidate items originating from the same module or repetitive patterns that span multiple modules 3. Pull main and branch to implement all changes, then review PR with Zach.

---
#### Custom source code (.c) linecounts:
CMS .c files:
  - cms_inquis_main.c: 52 lines
  - cms_comm_state.c: 156 lines
  - sd_card.c: 231 lines
  - cms_emc.c: 247 lines
  - cms_log_writer.c: 386 lines
  - cms_devices.c: 429 lines
  - fatfs_sd_card.c: 567 lines
  - cms_cli.c: 1,133 lines
  - cms_state.c: 1,650 lines

  Total CMS: 4,851 lines

  Handle .c files:
  - han_inquis_main.c: 75 lines
  - ad5940_glue.c: 108 lines
  - ad5940_overloads.c: 108 lines
  - han_emc.c: 217 lines
  - han_cli.c: 252 lines
  - han_sample.c: 332 lines
  - ad5940_api.c: 503 lines
  - han_state.c: 868 lines

  Total Handle: 2,463 lines

  Common .c files:
  - track_stats.c: 95 lines
  - crc.c: 99 lines
  - cli_helpers.c: 111 lines
  - test_helpers.c: 132 lines
  - packet.c: 161 lines
  - lights.c: 163 lines
  - emc.c: 189 lines
  - log.c: 208 lines
  - fifo.c: 210 lines
  - led_driver.c: 211 lines
  - state_defs.c: 243 lines
  - config.c: 268 lines
  - retarget.c: 292 lines
  - devices.c: 347 lines
  - bbstr.c: 367 lines
  - common.c: 398 lines
  - comm.c: 440 lines
  - fmt.c: 771 lines

  Total Common: 4,705 lines

  Grand total custom code: 12,019 lines
---
## GEN3
---
### Condensed report on dead code to follow up later
- CLI commands are not dead, they are accessed via function pointer dispatch which Zach implemented through macros
- **BBStr API**: bbstr_list_del_matches, bbstr_join, hex_dump, string_buffer_check -> All dead code
- **SD Card API**: sd_card_read_file_binary, sd_card_open_read_only
---
### CMS
#### CLI
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
- 458 Found this print confusing; We do not accept no args, change to something like "no args received, exiting"
- 465 why do we set sd false here but true later for the same setup condition (debug mode true)?
- 514 Incosistent arg checks; current argc style checks should still expect a specific count -- not >=
- 529 delete line not needed
- 593 preprocessor directives not needed since this command serves atomic function: testing loopback
- 627 preprocessor directive not needed, this code can become a new cli command; there is already a crit function shortly after, why not use this?
- 641 remove code in question
- 668 n t s there are references to interrupts relating to setup and timer; investigate interrupts since mike thinks we are 'interruptless'
- 668 from here to end of function, crit section not needed since this entire function is critical.
- 677 n t s review the result of this emperical test; is this explained by fastest timing before hitting basic overhead, or meaningful?
- 677 n t s collect emperical code into another review. We should replace these values with forward design, otherwise we have weak justification of results.
- 729 here and in previous extern, better to include the file or to run the test right here; limits visibility in static tools. Reason for this approach?
- 725 preprocessor directive not needed for testing-only cli command
- 745 unit tests should all be atomic. No messages should be confusing.
- 740 preprocessor directive not needed
- 742 elif only shows up here / nowhere else; if we wanted to catch the third case here, we should have caught it everywhere. directives should all be removed regardless.
- 763 replace externs by including tests. Handling tests will be a separate meeting. Unit tests live in software thus should not be mixed into cli. Integration tests can live here and should be included. Can improve printing the test results.
- 807 appropriate to rename function to _cmd_test_watchdog
- 840 delete empty capture health check
- 1110 this doesn't need to be a function unless we want to beautify errors or create an error type with a long output format.

[15h10 22 aug 2025 ~ faster to drop these questions and comments into powerpoint from the getgo]
[15h59 22 aug 2025 ~ leaving textual commentary and oneliners here and using slides for visual content like doxygen graphs] 


#### CMS COMM STATE
- 84 packet, not update_packet
- 84 n t s to see what is meant by "may or may not be sent" in practice; potentially undesireable logic for comms
- 88 n t s to collect all of the different asserts used across the codebase and to suggest a single assert.
- 97 redundant break statements in switch case
- 110 packet n bytes used but never checked against packet size. Recommend setting a global packet size used for generating fifo packets/slots to fill and referencing this global size in memcpy, otherwise this looks like the n bytes can be different for each Packet instance, which means we should check size before memcpy.
- 91 start_cycle_ms should be set to get_time_ms() from initialization
- 124 preprocessor directive not needed, collect into atomic unit test instead
- 136 delete redundant variable cms_comm_n_replies
- 153 default branch redundant if only contains break. Realistically, this should be an error condition as it indicates non-existent state was passed, likely corruption or bug in code. Current implementation fails silently which works against us.
- 31 in header, COMM_STATE_N_STATES in CommStateVal is never referenced, delete from struct or implement

#### CMS DEVICES
- 164 n t s that his is not a bad start for creating our error logging, but needs more adoption

#### CMS INQUIS MAIN
- 47 finish implementing self-tests

#### CMS LOG WRITER
- 73 determine appropriate value
- 122 This is a slow loop. If we only write allcaps LOG<NUMBER>, unnecessary to CHECK_CHARS. Instead, strcmp each filename to skim the greatest, then strip the number and produce the next filename (only fully parse one string, the highest value filename instead of each). O(n * strcmp) instead of O(n * strparse).
- 176 abstraction not needed since we already include fatfs in this file. This obfuscates logic/requires stepping into API. Recommend stripping all "one line abstractions" (API functions that contain one line or return statement) since they don't improve readability. If this pattern exists to replace function names like f_sync with sd_card_flush (from functional name to symbolic name) then I recommend using a comment for adding context instead of constructing methods to store meaning in the signature.
- 171 vs 180 Let's find all areas where we are inconsistent (return 0 vs NOERR, inquis_assert vs TRY_CHECK_IS, etc) and agree on **one** standard. Every new way of writing the same logic requires the reader to judge why and impedes contributing code in the absence of explanation.
- 174 why? We ignore the true state of the file handle.
- 191 Let _log_sdcard_close fail silently as it current may, and we call it when we detect _log_sdcard_is_open. This toggles the bool but not the filehandle (still dirty). Now, we call sd_card_open_read_write at the new fh and get unpredictable behavior. Fatfs will either throw an error on f_open or succeed but the fh is in an inconsistent state, which is worse, since we will have long moved on from here by the time we call f_write, which will either fail with FR_DISK_ERR, write to the wrong sector, or fail silently and write empty files with the remedy being a full open-write-close cycle to reset. Recommended change is to catch and explicitly handle fatfs errors in _log_sdcard_close and ..._init, catching and handling fh mismatch using the o-w-r sequence. Inconsistency will arise between fh and fs state; fh points to file at sector X with size Y and buffer with data Z, but fs file may be at different sector w/ different size and data; the cached datastructure intended to reflect fs state differs from data on disk/SD, and continuing with a mismatch leads to headless file operations (potential for corruption, lost data, missed writes, etc). Avoidable with detection and synchronization of fh with fs.
- 207 remove dead code
- 225 remove dead code
- 303 replace preprocessor directive and collect integration tests.
- 383 use standard abstraction naming such as get_<private_variable_name>

#### CMS STATE
- 68 global state variable breaks encapsulation, make static and provide accessor functions
- 83 typo in macro name SD_REQUIRED_FOR_DEVELOPEMENT, should be DEVELOPMENT
- 86 preprocessor directive for runtime logic, use runtime boolean check instead
- 106 three volt rail will not be zero. Define and compare against constant POST_MIN_3V3_RAIL_VOLTAGE 
- 112 same magic number issue for 5V rail check
- 118 same magic number issue for 12V rail check
- 124 same magic number issue for battery voltage check
- n t s to set voltage rail minimums conservatively (+0/-0.5V) and to set battery minimums based on joulometer/emperical data on expected operation time available at specific voltages (should be R&D step when qualifying any change to battery model or vendor). Realistic to set minimum for 5-10mins of operation so no unit is deployed that dies right when the interventionalist is prepared to aspirate.
- 144 dead function _power_is_in_range always returns true, implement or remove
- 166 no null check on fifo_writ_get_ptr return value before use
- 191 using assert for runtime safety check, use proper error handling instead
- 299 direct hardware control in state logic, move to abstraction layer; cms_state should invoke commands to devices (using their respective APIs) to maintain code isolation and readability (i.e. avoiding expressions like _set_valve_function(cms_state, config, false); which are false abstractions equivalent to pasting the hardware control code in the switch case). Each device API should have a set of commands and responses (including errors) which can be tabulated just like the FSM states. The transaction between the FSM and Device APIs follow a consistent format with al device invokations being transparent at a plain-english level when reading the FSM code, and the responses and errors are specified and collected into the API code so that we can statically determine that our FSM code is extensive in handling all possible responses from the devices it invokes. If we encounter unforeseen errors in testing, we update the device API (atomic updates) and device API spec/table (adding responses and errors) which we can then handle in the associated FSMs, statically verify that our handling is extensive, and once again have safe, traceable, readable code. Changes to device operation such as driving times and voltages reside solely in the appropriate API, thus preserving the correctness of FSM code after atomic changes to device/hardware-level code.
- 314 n t s that all if/else code in each switch case should be converted into a preamble of boolean expressions to serve as predicates and switch statements within each FSM state for handling said predicates; The FSM and state transitions implements the device's state-transition matrix, even if we have not yet created this at the documentation level. Nested switches are much clearer implementations of the state-transition matrix than switches with nested if statements. For states with many child predicates (a state which can transition to a large number of other states; i.e. high connectivity node), the need to use one consistent syntactic structure is clear.
- 353 complex boolean condition spans multiple lines, extract to case's preamble as a standalone bool variable assigned to the whole expression for clarity.
- 424 unconditionally overwrites co2_ok state (if co2_ok is false then we reach PISTON_STATE_60_CONFIRMING_STOP and set it true, we are able to aspirate with the real condition being co2_ok false), remove this line entirely or qualify why in comments
- 487 valve operation in error state without lid check, add safety check
- 508 same valve operation without lid check issue
- 521 same valve operation without lid check issue
- 564 side effect timer_latch call in variable declaration section, move to actions
- 601 no post call here?
- 629 block comment explaining state clearing, extract to clear_handle_state function
- 756 dead code with hardcoded false condition, remove false prefix
- 764 same dead code pattern with false prefix
- 771 redundant true condition, remove true prefix
- 921 same redundant true condition
- 935 entire commented case block LED_STATE_900_VACUUM_STATE_CYCLE, remove dead code
- 1005 redundant true condition in if statement
- 1045 commented audio_play call, implement or remove
- 1051 same commented audio call issue
- 1102 test code in production logic, move to separate test harness
- 1129 multiple test injection blocks scattered in main loop, extract to handle_integration_tests function
- 1217 test packet availability override in production code, move to test mock layer
- 1282 test CRC corruption in production code, move to test mock abstraction
- 1392 dead timeout logic with redundant true condition, implement properly or remove
- 1492 comment acknowledges ADC performance issue, implement timer-based sampling
- 1494 six consecutive ADC samples in main loop causing performance bottleneck, cache results with periodic
sampling


#### LOG
- note to self to make suggestion regarding base case of empty comment in emit_log_comment_record, which returns instead of emitting associated default comment, allowing for accidentally implementing silent errors (should not be possible)

### HANDLE

### COMMON
#### COMMON
- 337 finish or prune stack_check()

#### BBSTR
- n t s to check if there is a need for BBSTR API instead of using C string. Either we build a better string than C's implementation or use their binary; no reason to include both.

#### LED DRIVER
- 129 err != 0 ? 1 : 0 can be simplified to err ? 1 : 0

