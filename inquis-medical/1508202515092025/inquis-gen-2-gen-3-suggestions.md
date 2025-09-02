# Inquis Gen 2 - Gen 3 Codebase Suggestions for Zach S.

*The following suggestions are derived from code reviewed in the main branch of inquis_gen_3_0 <9dfa6d65ccb128b5cd307f8082603f34d296797b>*

**Process:** 
1. Read all functions and make commentary in this file or grab callgraphs/screenshots of code and collect into google slides presentation. 
2. Organize remarks into slideshow and consolidate items originating from the same module or repetitive patterns that span multiple modules 
3. Pull main and branch to implement all changes, then review PR with Zach.

---

## Custom Source Code Line Counts

### CMS .c files:
- cms_inquis_main.c: 52 lines
- cms_comm_state.c: 156 lines
- sd_card.c: 231 lines
- cms_emc.c: 247 lines
- cms_log_writer.c: 386 lines
- cms_devices.c: 429 lines
- fatfs_sd_card.c: 567 lines
- cms_cli.c: 1,133 lines
- cms_state.c: 1,650 lines

**Total CMS: 4,851 lines**

### Handle .c files:
- han_inquis_main.c: 75 lines
- ad5940_glue.c: 108 lines
- ad5940_overloads.c: 108 lines
- han_emc.c: 217 lines
- han_cli.c: 252 lines
- han_sample.c: 332 lines
- ad5940_api.c: 503 lines
- han_state.c: 868 lines

**Total Handle: 2,463 lines**

### Common .c files:
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

**Total Common: 4,705 lines**

### **Grand total custom code: 12,019 lines**
---

## GEN3

### Condensed Report on Dead Code to Follow Up Later

- CLI commands are not dead, they are accessed via function pointer dispatch which Zach implemented through macros
- **BBStr API**: bbstr_list_del_matches, bbstr_join, hex_dump, string_buffer_check → All dead code
- **SD Card API**: sd_card_read_file_binary, sd_card_open_read_only

---
## CMS

### CLI
- **Line 81**: what is cfg_overload for
- **Line 85**: Please verify sd_card_mount() behavior and confirm whether emitting non-blocking errors when exceptions occur is the intended design
- **Line 101**: Consider reviewing check_string_allocates(0,0) to ensure the check is safe and comprehensive for potential string memory leaks
- **Line 96**: config_file_contents bbstr not deleted in else branch
- **Line 115**: CMD_CHECK_IS appears redundant (suggest consolidating to one system-wide implementation) → CMD_CHECK_IS leads back to a function in CLI; consider calling that printf directly with a conditional
- **Line 117**: What is GPIO_Typedef; what is it for
- **Line 120**: CMD_CHECK_IS used instead of if (...) {emit_log_comment_record(...)} → Consider standardizing error handling across all modules; this might warrant a separate module
- **Function pointer dispatch**: Please review whether 'function pointer dispatch' is a safe approach for the CLI; clarification needed on whether pointers are dynamically allocated, sequential, or reserved by name
- **Line 110**: _cmd_gpio() lacks type validation for argv contents when argc matches expected count; argc keys the gpio command type but assumes argv is correct afterward; suggest adding validation checks
- **Line 151**: _cmd_led() lacks type validation; suggest adding typechecks to argv
- **Line 183**: Consider adding docstrings to each CLI command that cover the subcommands; since subcommands are keyed by argc, documenting what each argc value does would improve usability
- **Line 192**: what is the purpose of distinguishing argc 3 and 4; the logic is the same
- **CLI argument validation**: Consider adding type/value checks to all CLI commands at the beginning; currently commands assume argument contents are appropriate if argc is within range
- **pet_watchdog**: Please clarify the purpose of pet_watchdog
- **Line 280**: The 'done' flag is never toggled in the loop; only break is called. Consider toggling the flag at the appropriate point
- **Line 275**: Consider setting last_time to get_time_ms()
- **Line 280**: Consider what happens if buffer fills before 500ms? While potentially unlikely (please verify sample frequency), the inquis_assert could be replaced with a loopback to create a rolling 250-sample buffer since we sample until we can average 500ms
- **Line 422**: Including this line and others, consider adding input validation for arguments; it's preferable to validate inputs proactively rather than letting atoi or other functions fail
- **Line 438**: Variable 'i' is not incremented; if this was intended as a temporary change, consider reverting
- **Line 450**: _setup_audio implements clot audio loading; consider renaming, reimplementing, or removing to better reflect the function's purpose
- **Line 458**: This print statement could be clearer; since no arguments aren't accepted, consider changing to something like "no args received, exiting"
- **Line 465**: Please clarify why sd is set to false here but true later for the same setup condition (debug mode true)
- **Line 514**: Inconsistent argument validation; current argc-style checks should expect a specific count rather than using '>=' comparison
- **Line 529** (cms_cli.c): delete line not needed
- **Line 593** (cms_cli.c): Preprocessor directives may not be needed since this command serves an atomic function: testing loopback
- **Line 627** (cms_cli.c): preprocessor directive not needed, this code can become a new cli command; there is already a crit function shortly after, why not use this?
- **Line 641** (cms_cli.c): remove code in question
- **Line 668**: n t s there are references to interrupts relating to setup and timer; investigate interrupts since mike thinks we are 'interruptless'
- **Line 668**: from here to end of function, crit section not needed since this entire function is critical.
- **Line 677**: n t s review the result of this empirical test; is this explained by fastest timing before hitting basic overhead, or meaningful?
- **Line 677**: n t s collect empirical code into another review. We should replace these values with forward design, otherwise we have weak justification of results.
- **Line 729**: here and in previous extern, better to include the file or to run the test right here; limits visibility in static tools. Reason for this approach?
- **Line 725**: Preprocessor directive may not be needed for this testing-only CLI command
- **Line 745**: unit tests should all be atomic. No messages should be confusing.
- **Line 740**: preprocessor directive not needed
- **Line 742**: elif only shows up here / nowhere else; if we wanted to catch the third case here, we should have caught it everywhere. directives should all be removed regardless.
- **Line 763**: replace externs by including tests. Handling tests will be a separate meeting. Unit tests live in software thus should not be mixed into cli. Integration tests can live here and should be included. Can improve printing the test results.
- **Line 807**: appropriate to rename function to _cmd_test_watchdog
- **Line 840**: delete empty capture health check
- **Line 1110**: this doesn't need to be a function unless we want to beautify errors or create an error type with a long output format.

**Notes:**
- [15h10 22 aug 2025 ~ faster to drop these questions and comments into powerpoint from the getgo]
- [15h59 22 aug 2025 ~ leaving textual commentary and oneliners here and using slides for visual content like doxygen graphs] 

### CMS COMM STATE
- **Line 88** (cms_comm_state.c): Consider reviewing all different assert implementations used across the codebase and consolidating to a single assert implementation if possible
- **Line 97** (cms_comm_state.c): redundant break statements in switch case
- **Line 110**: Packet n_bytes is used but never validated against packet size. Consider setting a global packet size for generating FIFO packets/slots and referencing this size in memcpy. Otherwise, if n_bytes can vary per Packet instance, size validation should occur before memcpy
- **Line 91** (cms_comm_state.c): Consider setting start_cycle_ms to get_time_ms() during initialization
- **Line 124**: Preprocessor directive may not be needed; consider collecting into atomic unit test instead
- **Line 136** (cms_comm_state.c): delete redundant variable cms_comm_n_replies
- **Line 153**: default branch redundant if only contains break. Realistically, this should be an error condition as it indicates non-existent state was passed, likely corruption or bug in code. Current implementation fails silently which works against us.
- **Line 31** (cms_comm_state.c): in header, COMM_STATE_N_STATES in CommStateVal is never referenced, delete from struct or implement

### CMS DEVICES
- **Line 164** (cms_devices.c): This provides a good foundation for error logging, but would benefit from broader adoption across the codebase

### CMS INQUIS MAIN
- **Line 47**: Consider completing the self-test implementation

### CMS LOG WRITER
- **Line 73** (cms_log_writer.c): determine appropriate value
- **Line 122**: This loop could be optimized. If we only write uppercase LOG<NUMBER> filenames, the CHECK_CHARS operation may be unnecessary. Consider using strcmp to find the highest numbered filename, then extracting and incrementing that number for the next filename (parsing only one string instead of each). This would change complexity from O(n * strparse) to O(n * strcmp)
- **Line 176** (cms_log_writer.c): This abstraction may not be necessary since fatfs is already included in this file. It could obscure logic by requiring developers to step into the API. Consider removing "one line abstractions" (API functions with single lines or return statements) as they may not improve readability. If this pattern exists to replace function names like f_sync with sd_card_flush (functional to symbolic naming), consider using comments for context instead of creating wrapper methods
- **Lines 171 vs 180** (cms_log_writer.c): Let's find all areas where we are inconsistent (return 0 vs NOERR, inquis_assert vs TRY_CHECK_IS, etc) and agree on **one** standard. Every new way of writing the same logic requires the reader to judge why and impedes contributing code in the absence of explanation.
- **Line 174** (cms_log_writer.c): why? We ignore the true state of the file handle.
- **Line 191**: Consider the potential issue where _log_sdcard_close fails silently, and we call it when we detect _log_sdcard_is_open. This toggles the boolean but not the filehandle (which remains dirty). When we subsequently call sd_card_open_read_write with the new file handle, this could lead to unpredictable behavior. FatFS might either throw an error on f_open or succeed with the file handle in an inconsistent state. The latter case is particularly problematic since by the time we call f_write, it might fail with FR_DISK_ERR, write to the wrong sector, or fail silently creating empty files. The remedy would be a full open-write-close cycle to reset. Consider catching and explicitly handling FatFS errors in _log_sdcard_close and ..._init, including handling file handle mismatches using the open-write-reset sequence. Inconsistencies can arise between file handle and filesystem state where the handle points to one location/size/buffer while the filesystem file has different properties. This cached data structure mismatch with the actual disk state could lead to problematic file operations (potential corruption, lost data, missed writes). This could be avoided through detection and synchronization of the file handle with the filesystem
- **Line 207** (cms_log_writer.c): remove dead code
- **Line 225** (cms_log_writer.c): remove dead code
- **Line 303** (cms_log_writer.c): replace preprocessor directive and collect integration tests.
- **Line 383** (cms_log_writer.c): use standard abstraction naming such as get_<private_variable_name>

### CMS STATE
- **Line 68** (cms_state.c): global state variable breaks encapsulation, make static and provide accessor functions; not necessary to expose for testing purposes. Low priority item
- **Line 70** (cms_state.c): same feedback, avoid exposing and access with get function
- **Line 83** (cms_state.c): typo in macro name SD_REQUIRED_FOR_DEVELOPEMENT, should be DEVELOPMENT
- **Line 86** (cms_state.c): preprocessor directive for runtime logic, use runtime boolean check instead
- **Line 106**: three volt rail will not be zero. Define and compare against constant POST_MIN_3V3_RAIL_VOLTAGE 
- **Line 112**: same magic number issue for 5V rail check
- **Line 118**: same magic number issue for 12V rail check
- **Line 124**: same magic number issue for battery voltage check
- **Voltage rail minimums**: n t s to set voltage rail minimums conservatively (+0/-0.5V) and to set battery minimums based on joulemeter/emperical data on expected operation time available at specific voltages (should be R&D step when qualifying any change to battery model or vendor). Realistic to set minimum for 5-10mins of operation so no unit is deployed that dies right when the interventionalist is prepared to aspirate.
- **Line 144**: dead function _power_is_in_range always returns true, implement or remove
- **Line 166**: no null check on fifo_writ_get_ptr return value before use
- **Line 191**: using assert for runtime safety check, use proper error handling instead
- **Line 299** (cms_state.c): direct hardware control in state logic, move to abstraction layer; cms_state should invoke commands to devices (using their respective APIs) to maintain code isolation and readability (i.e. avoiding expressions like _set_valve_function(cms_state, config, false); which are false abstractions equivalent to pasting the hardware control code in the switch case). Each device API should have a set of commands and responses (including errors) which can be tabulated just like the FSM states. The transaction between the FSM and Device APIs follow a consistent format with al device invokations being transparent at a plain-english level when reading the FSM code, and the responses and errors are specified and collected into the API code so that we can statically determine that our FSM code is extensive in handling all possible responses from the devices it invokes. If we encounter unforeseen errors in testing, we update the device API (atomic updates) and device API spec/table (adding responses and errors) which we can then handle in the associated FSMs, statically verify that our handling is extensive, and once again have safe, traceable, readable code. Changes to device operation such as driving times and voltages reside solely in the appropriate API, thus preserving the correctness of FSM code after atomic changes to device/hardware-level code.
- **Line 314** (cms_state.c): n t s that all if/else code in each switch case should be converted into a preamble of boolean expressions to serve as predicates and switch statements within each FSM state for handling said predicates; The FSM and state transitions implements the device's state-transition matrix, even if we have not yet created this at the documentation level. Nested switches are much clearer implementations of the state-transition matrix than switches with nested if statements. For states with many child predicates (a state which can transition to a large number of other states; i.e. high connectivity node), the need to use one consistent syntactic structure is clear.
- **Line 353** (cms_state.c): complex boolean condition spans multiple lines, extract to case's preamble as a standalone bool variable assigned to the whole expression for clarity.
- **Line 424**: unconditionally overwrites co2_ok state (if co2_ok is false then we reach PISTON_STATE_60_CONFIRMING_STOP and set it true, we are able to aspirate with the real condition being co2_ok false), remove this line entirely or qualify why in comments
- **Line 508** (cms_state.c): unchecked _set_valve_state_and_latch, should follow rule set by function/assert
- **Line 554**: this computation should be performed once per tick, wrapped into cms_state
- **Line 564** (cms_state.c): timer_latch is redundant, replace with the logic; only two references
- **Line 598**: consider wrapping time delta computations into cms_state fields once per tick since they reference the times stored in cms_state
- **Line 624** (cms_state.c): we expose all cms_state modifications in this case, but we abstract them to short functions elsewhere. I propose migrating all cms_state modifications from function to case unless repeated more than twice; function abstractions not neecessary to implement abstraction of an API obfuscate the logic.
- **Line 735** (cms_state.c): remove 'false' prefix from or-only conditionals, redundant and will short-circuit if 'and's are added later
- **Line 748** (cms_state.c): make this whole statement a single assignment for clarity.
- **Line 785** (cms_state.c): suggest collecting computations directly influencing sensing state into one location in fsm; harder to evaluate when distributed across code.
- **Line 935** (cms_state.c): entire commented case block LED_STATE_900_VACUUM_STATE_CYCLE, remove dead code, we can retreive from commit if needed
- **Line 971** (cms_state.c): collect all prelude code from _update_X_state functions into a single tick-start function that sets fields in cms_state to be used elsewhere; better to store the values we use for state transitions in cms_state instead of just-in-time variables, and ensures single point of modification to change computation behind a given value.
- **Line 1005** (cms_state.c): redundant true condition in if statement; let's remove all redundant hardcoded values in conditionals, needless risk
- **Line 1006** (cms_state.c): we sometimes compute this in the prelude (e.g. is_imp_state_3) and sometimes in the conditional predicate. I recommend we pick one approach and apply it consisitently, and computing boolean statements in the predicate is the best approach for full visibility of the state transition logic in each case. We don't want to separate the state transition logic from the case.
- **Line 1045** (cms_state.c): commented audio_play call, implement or remove
- **Line 1102** (cms_state.c): consolidate preprocessor directives
- **Line 1129** (cms_state.c): consolidate preprocessor directives: multiple test injection blocks scattered in main loop, extract to handle_integration_tests function
- **Line 1217** (cms_state.c): consolidate preprocessor directives: test packet availability override in production code, move to test mock layer
- **Line 1282** (cms_state.c): consolidate preprocessor directives: test CRC corruption in production code, move to test mock abstraction
- **Line 1392** (cms_state.c): dead timeout logic: confirm whether we want to restore this
- **Line 1494**: six consecutive ADC samples in main loop causing performance bottleneck, cache results with periodic asynchronous
sampling

## HANDLE
### HAN STATE
- **Line 90** (han_state.c): hand_state includes interrupt context with comm_reply_callback()
- **Line 119** (han_state.c): *config never used
- **Line 124** (han_state.c): Consider simplifying the n_errors++ ... n_errors == 0 pattern; suggest returning -1 or true on first error encounter, 0 or false otherwise
- **Line 146**: implement _power_is_in_range(); what data are we awaiting
- **Line 172**: implement catching null fifo pointers (most likely caused by active or dead lock, which should be written out of logic.)
- **Line 255** (han_state.c): implement timer latch here, it is only called twice and implements a few conditionals
- **Line 278** (han_state.c): consider implementing specific error states with same catchall behavior to give us the option to handle these errors individually later. STATE_OTHER_ERROR for the truly wildcard errors, and specific errors otherwise.
- **Line 312** (han_state.c): remove all hardcoded predicates to prevent accidental short-circuit on later modification
- **Line 320** (han_state.c): like timer_latch, replace timer_elapsed with the implementation, this oneliner doesn't need to live in common/ as a new function; no side-effects or abstraction necessitating function definition.
- **Line 332** (han_state.c): specific error state needed routed to HAN_STATE_REMAIN case
- **Line 428** (han_state.c): debug code should not mix with production code
- **Line 443** (han_state.c): ineresting that default is 2000_ERROR while elsewhere we freeze state with HAN_STATE_REMAIN. In some cases, I see how STATE_REMAIN loops until we transition out, but could we create more detailed states to reflect specific error states and have the default by STATE_REMAIN or STATE_XXXX_DEFAULT?
- **Line 472** (han_state.c): Consider storing local _comm_... values in a struct compatible with HandleStatusPacket for direct assignment
- **Line 493**: Catch and log, we need to know if these occur 
- **Line 499**: Log collisions as above and determine the reply delay needed. UART analyzer will clarify frame timings and the appropriate delay, 25ms isn't incredibly long but still too long for higher throughputs we may want down the line.

## COMMON
### COMMON
- **Line 337**: Consider completing or removing stack_check()
- **Line 289** (common.c): Note that inquis_assert_failed is never called

### LOG
- **Line 110** (log.c): Error string pointer tracking is inefficient, there is information in repeated, non-fatal errors, so we should delegate responsibility of desired error logic to caller

### BBSTR
- **BBSTR API** (bbstr.c): n t s to check if there is a need for BBSTR API instead of using C string. Either we build a better string than C's implementation or use their binary; no reason to include both.

### LED DRIVER
- **Line 129** (led_driver.c): err != 0 ? 1 : 0 can be simplified to err ? 1 : 0

---

## FUNCTIONAL VS NON-FUNCTIONAL CATEGORIZATION

*Analysis of all suggestions categorized by their impact on device functionality, safety, and performance versus code maintenance and quality.*

### FUNCTIONAL SUGGESTIONS
*These suggestions, if implemented, would influence device functionality, prevent errors, or improve performance.*

- **Line 424** (cms_state.c): unconditionally overwrites co2_ok state (if co2_ok is false then we reach PISTON_STATE_60_CONFIRMING_STOP and set it true, we are able to aspirate with the real condition being co2_ok false), remove this line entirely or qualify why in comments
- **Line 166** (cms_state.c): no null check on fifo_writ_get_ptr return value before use
- **Line 191** (cms_state.c): using assert for runtime safety check, use proper error handling instead
- **Voltage rail minimums** (cms_state.c): n t s to set voltage rail minimums conservatively (+0/-0.5V) and to set battery minimums based on joulemeter/emperical data on expected operation time available at specific voltages (should be R&D step when qualifying any change to battery model or vendor). Realistic to set minimum for 5-10mins of operation so no unit is deployed that dies right when the interventionalist is prepared to aspirate.
- **Line 106** (cms_state.c): three volt rail will not be zero. Define and compare against constant POST_MIN_3V3_RAIL_VOLTAGE 
- **Line 112** (cms_state.c): same magic number issue for 5V rail check
- **Line 118** (cms_state.c): same magic number issue for 12V rail check
- **Line 124** (cms_state.c): same magic number issue for battery voltage check
- **Line 191** (cms_log_writer.c): Let _log_sdcard_close fail silently as it currently may, and we call it when we detect _log_sdcard_is_open. This toggles the bool but not the filehandle (still dirty). Now, we call sd_card_open_read_write at the new fh and get unpredictable behavior. Fatfs will either throw an error on f_open or succeed but the fh is in an inconsistent state, which is worse, since we will have long moved on from here by the time we call f_write, which will either fail with FR_DISK_ERR, write to the wrong sector, or fail silently and write empty files with the remedy being a full open-write-close cycle to reset. Recommended change is to catch and explicitly handle fatfs errors in _log_sdcard_close and ..._init, catching and handling fh mismatch using the o-w-r sequence. Inconsistency will arise between fh and fs state; fh points to file at sector X with size Y and buffer with data Z, but fs file may be at different sector w/ different size and data; the cached datastructure intended to reflect fs state differs from data on disk/SD, and continuing with a mismatch leads to headless file operations (potential for corruption, lost data, missed writes, etc). Avoidable with detection and synchronization of fh with fs.
- **Line 110** (cms_comm_state.c): packet n bytes used but never checked against packet size. Recommend setting a global packet size used for generating fifo packets/slots to fill and referencing this global size in memcpy, otherwise this looks like the n bytes can be different for each Packet instance, which means we should check size before memcpy.
- **Line 153** (cms_comm_state.c): default branch redundant if only contains break. Realistically, this should be an error condition as it indicates non-existent state was passed, likely corruption or bug in code. Current implementation fails silently which works against us.
- **Line 110** (cms_cli.c): _cmd_gpio() unsafe, no typechecks for argv contents when argc matches expected count; argc keys type of gpio command, assumes argv is correct after this point; add checks
- **Line 151** (cms_cli.c): _cmd_led() unsafe; add typechecks to argv
- **Line 438** (cms_cli.c): i not incremented; was this supposed to be a temp change? suggest revert
- **Line 280** (cms_cli.c): what happens if buffer filled before 500ms? Perhaps unlikely (check sample freq) but inquis_assert could just be replaced with a loopback to make this a rolling 250 sample buffer given we just sample until we can average 500ms.
- **Line 172** (han_state.c): implement catching null fifo pointers (most likely caused by active or dead lock, which should be written out of logic.)
- **Line 493** (han_state.c): Catch and log, we need to know if these occur 
- **Line 499** (han_state.c): Log collisions as above and determine the reply delay needed. UART analyzer will clarify frame timings and the appropriate delay, 25ms isn't incredibly long but still too long for higher throughputs we may want down the line.
- **Line 1494** (cms_state.c): six consecutive ADC samples in main loop causing performance bottleneck, cache results with periodic asynchronous sampling
- **Line 554** (cms_state.c): this computation should be performed once per tick, wrapped into cms_state
- **Line 598** (cms_state.c): consider wrapping time delta computations into cms_state fields once per tick since they reference the times stored in cms_state
- **Line 122** (cms_log_writer.c): This is a slow loop. If we only write allcaps LOG<NUMBER>, unnecessary to CHECK_CHARS. Instead, strcmp each filename to skim the greatest, then strip the number and produce the next filename (only fully parse one string, the highest value filename instead of each). O(n * strcmp) instead of O(n * strparse).
- **Line 47** (cms_inquis_main.c): finish implementing self-tests
- **Line 144** (cms_state.c): dead function _power_is_in_range always returns true, implement or remove
- **Line 146** (han_state.c): implement _power_is_in_range(); what data are we awaiting
- **Line 337** (common.c): finish or prune stack_check()

### NON-FUNCTIONAL SUGGESTIONS
*These suggestions would assist with code maintenance and quality without appreciable impact on device operation.*

- **Line 81** (cms_cli.c): what is cfg_overload for
- **_<funName> vs <funName>** (cms_cli.c): local vs global pattern?
- **Line 85** (cms_cli.c): n t s to check sd_card_mount() and see why/if it is okay to emit non-blocking error if error thrown
- **Line 101** (cms_cli.c): n t s to check check_string_allocates(0,0) if the check is safe / comprehensive for potential string memory leaks
- **Line 96** (cms_cli.c): config_file_contents bbstr not deleted in else branch
- **Line 115** (cms_cli.c): CMD_CHECK_IS is a redundant assert (we need only one system wide realistically) → CMD_CHECK_IS leads back to a function in CLI; couldn't we call that printf directly with a conditional?
- **Line 117** (cms_cli.c): What is GPIO_Typedef; what is it for
- **Line 120** (cms_cli.c): CMD_CHECK_IS used instead of if (...) {emit_log_comment_record(...)} → We should have one way to handle errors visible to all modules; should even be a separate module
- **Function pointer dispatch** (cms_cli.c): n t s to check whether 'function pointer dispatch' is a safe way to define the cli; pointers are dynamically allocated, are they sequential or reserved by name?
- **Line 183** (cms_cli.c): n t s to give each cli command a docstring which covers the subcommands; subcommands keyed by argc, best to list what each argc does for user
- **Line 192** (cms_cli.c): what is the purpose of distinguishing argc 3 and 4; the logic is the same
- **CLI argument validation** (cms_cli.c): n t s in cli, ever command should begin with type/value checks on all args; all commands assume contents are appropriate if argc is within range.
- **pet_watchdog** (cms_cli.c): n t s what does pet_watchdog exist for
- **Line 280** (cms_cli.c): done never toggled in loop; only break called. should toggle at some point
- **Line 275** (cms_cli.c): last_time should be set to get_time_ms
- **Line 422** (cms_cli.c): including but not limited to this line, add checks for arg inputs; better to catch ourselves than letting atoi or other functions fail
- **Line 450** (cms_cli.c): _setup_audio implements loading clot audio; suggest renaming, reimplementing, or removing to reflect function name.
- **Line 458** (cms_cli.c): Found this print confusing; We do not accept no args, change to something like "no args received, exiting"
- **Line 465** (cms_cli.c): why do we set sd false here but true later for the same setup condition (debug mode true)?
- **Line 514** (cms_cli.c): Inconsistent arg checks; current argc style checks should still expect a specific count -- not >=
- **Line 529** (cms_cli.c): delete line not needed
- **Line 593** (cms_cli.c): Preprocessor directives may not be needed since this command serves an atomic function: testing loopback
- **Line 627** (cms_cli.c): preprocessor directive not needed, this code can become a new cli command; there is already a crit function shortly after, why not use this?
- **Line 641** (cms_cli.c): remove code in question
- **Line 668**: n t s there are references to interrupts relating to setup and timer; investigate interrupts since mike thinks we are 'interruptless'
- **Line 668**: from here to end of function, crit section not needed since this entire function is critical.
- **Line 677**: n t s review the result of this empirical test; is this explained by fastest timing before hitting basic overhead, or meaningful?
- **Line 677**: n t s collect empirical code into another review. We should replace these values with forward design, otherwise we have weak justification of results.
- **Line 729**: here and in previous extern, better to include the file or to run the test right here; limits visibility in static tools. Reason for this approach?
- **Line 725**: Preprocessor directive may not be needed for this testing-only CLI command
- **Line 745**: unit tests should all be atomic. No messages should be confusing.
- **Line 740**: preprocessor directive not needed
- **Line 742**: elif only shows up here / nowhere else; if we wanted to catch the third case here, we should have caught it everywhere. directives should all be removed regardless.
- **Line 763**: replace externs by including tests. Handling tests will be a separate meeting. Unit tests live in software thus should not be mixed into cli. Integration tests can live here and should be included. Can improve printing the test results.
- **Line 807**: appropriate to rename function to _cmd_test_watchdog
- **Line 840**: delete empty capture health check
- **Line 1110**: this doesn't need to be a function unless we want to beautify errors or create an error type with a long output format.
- **Line 84** (cms_comm_state.c): packet, not update_packet
- **Line 84**: n t s to see what is meant by "may or may not be sent" in practice; potentially undesirable logic for comms
- **Line 88** (cms_comm_state.c): Consider reviewing all different assert implementations used across the codebase and consolidating to a single assert implementation if possible
- **Line 97** (cms_comm_state.c): redundant break statements in switch case
- **Line 91** (cms_comm_state.c): Consider setting start_cycle_ms to get_time_ms() during initialization
- **Line 124**: Preprocessor directive may not be needed; consider collecting into atomic unit test instead
- **Line 136** (cms_comm_state.c): delete redundant variable cms_comm_n_replies
- **Line 31** (cms_comm_state.c): in header, COMM_STATE_N_STATES in CommStateVal is never referenced, delete from struct or implement
- **Line 164** (cms_devices.c): This provides a good foundation for error logging, but would benefit from broader adoption across the codebase
- **Line 73** (cms_log_writer.c): determine appropriate value
- **Line 176** (cms_log_writer.c): This abstraction may not be necessary since fatfs is already included in this file. It could obscure logic by requiring developers to step into the API. Consider removing "one line abstractions" (API functions with single lines or return statements) as they may not improve readability. If this pattern exists to replace function names like f_sync with sd_card_flush (functional to symbolic naming), consider using comments for context instead of creating wrapper methods
- **Lines 171 vs 180** (cms_log_writer.c): Let's find all areas where we are inconsistent (return 0 vs NOERR, inquis_assert vs TRY_CHECK_IS, etc) and agree on **one** standard. Every new way of writing the same logic requires the reader to judge why and impedes contributing code in the absence of explanation.
- **Line 174** (cms_log_writer.c): why? We ignore the true state of the file handle.
- **Line 207** (cms_log_writer.c): remove dead code
- **Line 225** (cms_log_writer.c): remove dead code
- **Line 303** (cms_log_writer.c): replace preprocessor directive and collect integration tests.
- **Line 383** (cms_log_writer.c): use standard abstraction naming such as get_<private_variable_name>
- **Line 68** (cms_state.c): global state variable breaks encapsulation, make static and provide accessor functions; not necessary to expose for testing purposes. Low priority item
- **Line 70** (cms_state.c): same feedback, avoid exposing and access with get function
- **Line 83** (cms_state.c): typo in macro name SD_REQUIRED_FOR_DEVELOPEMENT, should be DEVELOPMENT
- **Line 86** (cms_state.c): preprocessor directive for runtime logic, use runtime boolean check instead
- **Line 299** (cms_state.c): direct hardware control in state logic, move to abstraction layer; cms_state should invoke commands to devices (using their respective APIs) to maintain code isolation and readability (i.e. avoiding expressions like _set_valve_function(cms_state, config, false); which are false abstractions equivalent to pasting the hardware control code in the switch case). Each device API should have a set of commands and responses (including errors) which can be tabulated just like the FSM states. The transaction between the FSM and Device APIs follow a consistent format with al device invokations being transparent at a plain-english level when reading the FSM code, and the responses and errors are specified and collected into the API code so that we can statically determine that our FSM code is extensive in handling all possible responses from the devices it invokes. If we encounter unforeseen errors in testing, we update the device API (atomic updates) and device API spec/table (adding responses and errors) which we can then handle in the associated FSMs, statically verify that our handling is extensive, and once again have safe, traceable, readable code. Changes to device operation such as driving times and voltages reside solely in the appropriate API, thus preserving the correctness of FSM code after atomic changes to device/hardware-level code.
- **Line 314** (cms_state.c): n t s that all if/else code in each switch case should be converted into a preamble of boolean expressions to serve as predicates and switch statements within each FSM state for handling said predicates; The FSM and state transitions implements the device's state-transition matrix, even if we have not yet created this at the documentation level. Nested switches are much clearer implementations of the state-transition matrix than switches with nested if statements. For states with many child predicates (a state which can transition to a large number of other states; i.e. high connectivity node), the need to use one consistent syntactic structure is clear.
- **Line 353** (cms_state.c): complex boolean condition spans multiple lines, extract to case's preamble as a standalone bool variable assigned to the whole expression for clarity.
- **Line 508** (cms_state.c): unchecked _set_valve_state_and_latch, should follow rule set by function/assert
- **Line 564** (cms_state.c): timer_latch is redundant, replace with the logic; only two references
- **Line 624** (cms_state.c): we expose all cms_state modifications in this case, but we abstract them to short functions elsewhere. I propose migrating all cms_state modifications from function to case unless repeated more than twice; function abstractions not neecessary to implement abstraction of an API obfuscate the logic.
- **Line 735** (cms_state.c): remove 'false' prefix from or-only conditionals, redundant and will short-circuit if 'and's are added later
- **Line 748** (cms_state.c): make this whole statement a single assignment for clarity.
- **Line 785** (cms_state.c): suggest collecting computations directly influencing sensing state into one location in fsm; harder to evaluate when distributed across code.
- **Line 935** (cms_state.c): entire commented case block LED_STATE_900_VACUUM_STATE_CYCLE, remove dead code, we can retreive from commit if needed
- **Line 971** (cms_state.c): collect all prelude code from _update_X_state functions into a single tick-start function that sets fields in cms_state to be used elsewhere; better to store the values we use for state transitions in cms_state instead of just-in-time variables, and ensures single point of modification to change computation behind a given value.
- **Line 1005** (cms_state.c): redundant true condition in if statement; let's remove all redundant hardcoded values in conditionals, needless risk
- **Line 1006** (cms_state.c): we sometimes compute this in the prelude (e.g. is_imp_state_3) and sometimes in the conditional predicate. I recommend we pick one approach and apply it consisitently, and computing boolean statements in the predicate is the best approach for full visibility of the state transition logic in each case. We don't want to separate the state transition logic from the case.
- **Line 1045** (cms_state.c): commented audio_play call, implement or remove
- **Line 1102** (cms_state.c): consolidate preprocessor directives
- **Line 1129** (cms_state.c): consolidate preprocessor directives: multiple test injection blocks scattered in main loop, extract to handle_integration_tests function
- **Line 1217** (cms_state.c): consolidate preprocessor directives: test packet availability override in production code, move to test mock layer
- **Line 1282** (cms_state.c): consolidate preprocessor directives: test CRC corruption in production code, move to test mock abstraction
- **Line 1392** (cms_state.c): dead timeout logic: confirm whether we want to restore this
- **Line 90** (han_state.c): hand_state includes interrupt context with comm_reply_callback()
- **Line 119** (han_state.c): *config never used
- **Line 124** (han_state.c): Consider simplifying the n_errors++ ... n_errors == 0 pattern; suggest returning -1 or true on first error encounter, 0 or false otherwise
- **Line 255** (han_state.c): implement timer latch here, it is only called twice and implements a few conditionals
- **Line 278** (han_state.c): consider implementing specific error states with same catchall behavior to give us the option to handle these errors individually later. STATE_OTHER_ERROR for the truly wildcard errors, and specific errors otherwise.
- **Line 312** (han_state.c): remove all hardcoded predicates to prevent accidental short-circuit on later modification
- **Line 320** (han_state.c): like timer_latch, replace timer_elapsed with the implementation, this oneliner doesn't need to live in common/ as a new function; no side-effects or abstraction necessitating function definition.
- **Line 332** (han_state.c): specific error state needed routed to HAN_STATE_REMAIN case
- **Line 428** (han_state.c): debug code should not mix with production code
- **Line 443** (han_state.c): ineresting that default is 2000_ERROR while elsewhere we freeze state with HAN_STATE_REMAIN. In some cases, I see how STATE_REMAIN loops until we transition out, but could we create more detailed states to reflect specific error states and have the default by STATE_REMAIN or STATE_XXXX_DEFAULT?
- **Line 472** (han_state.c): Consider storing local _comm_... values in a struct compatible with HandleStatusPacket for direct assignment
- **Line 289** (common.c): Note that inquis_assert_failed is never called
- **Line 110** (log.c): Error string pointer tracking is inefficient, there is information in repeated, non-fatal errors, so we should delegate responsibility of desired error logic to caller
- **BBSTR API** (bbstr.c): n t s to check if there is a need for BBSTR API instead of using C string. Either we build a better string than C's implementation or use their binary; no reason to include both.
- **Line 129** (led_driver.c): err != 0 ? 1 : 0 can be simplified to err ? 1 : 0