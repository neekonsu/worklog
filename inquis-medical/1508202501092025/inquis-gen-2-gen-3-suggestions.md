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

### **Grand total custom code (*.c excl. headers): 12,019 lines**
---

## GEN3

### Condensed Report on Dead Code to Follow Up Later

- CLI commands are not dead, they are accessed via function pointer dispatch which Zach implemented through macros
- **BBStr API**: bbstr_list_del_matches, bbstr_join, hex_dump, string_buffer_check → All dead code
- **SD Card API**: sd_card_read_file_binary, sd_card_open_read_only

---
## CMS

### CLI
- **Line 85**: Could you verify sd_card_mount() behavior and confirm whether emitting non-blocking errors when exceptions occur is the intended design
- **Line 101**: Consider reviewing check_string_allocates(0,0) to ensure the check is safe and comprehensive for potential string memory leaks
- **Line 96**: Consider ensuring config_file_contents bbstr is deleted in else branch
- **Line 115**: CMD_CHECK_IS may be redundant (consider consolidating to one system-wide implementation) → CMD_CHECK_IS leads back to a function in CLI; consider calling that printf directly with a conditional
- **Line 120**: CMD_CHECK_IS used instead of if (...) {emit_log_comment_record(...)} → Consider standardizing error handling across all modules; this might warrant a separate module
- **Line 110**: _cmd_gpio() could benefit from type validation for argv contents when argc matches expected count; argc keys the gpio command type but assumes argv is correct afterward; consider adding validation checks
- **Line 151**: _cmd_led() could benefit from type validation; consider adding typechecks to argv
- **Line 183**: Consider adding docstrings to each CLI command that cover the subcommands; since subcommands are keyed by argc, documenting what each argc value does would improve usability
- **Line 192**: what is the purpose of distinguishing argc 3 and 4; the logic is the same
- **CLI argument validation**: Consider adding type/value checks to all CLI commands at the beginning; currently commands assume argument contents are appropriate if argc is within range
- **pet_watchdog**: Could you clarify the purpose of pet_watchdog
- **Line 280**: The 'done' flag is never toggled in the loop; only break is called. Consider toggling the flag at the appropriate point
- **Line 275**: Consider setting last_time to get_time_ms()
- **Line 280**: Consider what happens if buffer fills before 500ms? While potentially unlikely (could you verify sample frequency), the inquis_assert could be replaced with a loopback to create a rolling 250-sample buffer since we sample until we can average 500ms
- **Line 422**: Including this line and others, consider adding input validation for arguments; consider validating inputs proactively rather than letting atoi or other functions fail
- **Line 438**: Variable 'i' is not incremented; if this was intended as a temporary change, consider reverting
- **Line 450**: _setup_audio implements clot audio loading; consider renaming, reimplementing, or removing to better reflect the function's purpose
- **Line 458**: This print statement could be clearer; since no arguments aren't accepted, consider changing to something like "no args received, exiting"
- **Line 465**: Could you clarify why sd is set to false here but true later for the same setup condition (debug mode true)
- **Line 514**: Inconsistent argument validation; current argc-style checks could expect a specific count rather than using '>=' comparison
- **Line 593**: Preprocessor directives might not be needed since this command serves an atomic function: testing loopback
- **Line 627**: preprocessor directive not needed, this code can become a new cli command; there is already a crit function shortly after, why not use this?
- **Line 668**: from here to end of function, crit section might not be needed since this entire function is critical.
- **Line 677**: Consider reviewing the result of this empirical test; is this explained by fastest timing before hitting basic overhead, or is it meaningful?
- **Line 677**: Consider collecting empirical code into another review. We could replace these values with forward design for stronger justification of results.
- **Line 729**: here and in previous extern, consider including the file or running the test right here; this limits visibility in static tools. What's the reason for this approach?
- **Line 725**: Preprocessor directive might not be needed for this testing-only CLI command
- **Line 745**: unit tests could all be atomic. Consider ensuring messages are clear.
- **Line 740**: preprocessor directive might not be needed
- **Line 742**: elif only appears here; if we wanted to catch the third case here, we could catch it everywhere. Consider removing directives for consistency.
- **Line 763**: consider replacing externs by including tests. Handling tests will be a separate meeting. Unit tests could be separated from cli. Integration tests can live here and could be included. Consider improving printing of test results.
- **Line 807**: appropriate to rename function to _cmd_test_watchdog
- **Line 840**: consider removing empty capture health check
- **Line 1110**: this might not need to be a function unless we want to beautify errors or create an error type with a long output format.

### CMS COMM STATE
- **Line 88** (cms_comm_state.c): Consider reviewing all different assert implementations used across the codebase and consolidating to a single assert implementation if possible
- **Line 97** (cms_comm_state.c): redundant break statements in switch case
- **Line 110**: Packet n_bytes is used but never validated against packet size. Consider setting a global packet size for generating FIFO packets/slots and referencing this size in memcpy. Otherwise, if n_bytes can vary per Packet instance, size validation could occur before memcpy
- **Line 91** (cms_comm_state.c): Consider setting start_cycle_ms to get_time_ms() during initialization
- **Line 124**: Preprocessor directive might not be needed; consider collecting into atomic unit test instead
- **Line 136** (cms_comm_state.c): consider removing redundant variable cms_comm_n_replies
- **Line 153**: default branch might be redundant if it only contains break. Consider making this an error condition as it indicates non-existent state was passed, possibly indicating corruption or a bug. Current implementation fails silently which could mask issues.
- **Line 31** (cms_comm_state.c): in header, COMM_STATE_N_STATES in CommStateVal is never referenced, consider removing from struct or implementing

### CMS DEVICES
- **Line 164** (cms_devices.c): This provides a good foundation for error logging, but would benefit from broader adoption across the codebase

### CMS INQUIS MAIN
- **Line 47**: Consider completing the self-test implementation

### CMS LOG WRITER
- **Line 73** (cms_log_writer.c): consider determining appropriate value
- **Line 122**: This loop could be optimized. If we only write uppercase LOG<NUMBER> filenames, the CHECK_CHARS operation may be unnecessary. Consider using strcmp to find the highest numbered filename, then extracting and incrementing that number for the next filename (parsing only one string instead of each). This would change complexity from O(n * strparse) to O(n * strcmp)
- **Line 176** (cms_log_writer.c): This abstraction may not be necessary since fatfs is already included in this file. It could obscure logic by requiring developers to step into the API. Consider removing "one line abstractions" (API functions with single lines or return statements) as they may not improve readability. If this pattern exists to replace function names like f_sync with sd_card_flush (functional to symbolic naming), consider using comments for context instead of creating wrapper methods
- **Lines 171 vs 180** (cms_log_writer.c): Consider finding all areas where we are inconsistent (return 0 vs NOERR, inquis_assert vs TRY_CHECK_IS, etc) and agreeing on **one** standard. Multiple ways of writing the same logic requires the reader to understand the differences and may make contributing more challenging.
- **Line 174** (cms_log_writer.c): Consider the implications of ignoring the true state of the file handle.
- **Line 191**: Consider the potential issue where _log_sdcard_close fails silently, and we call it when we detect _log_sdcard_is_open. This toggles the boolean but not the filehandle (which remains dirty). When we subsequently call sd_card_open_read_write with the new file handle, this could lead to unpredictable behavior. FatFS might either throw an error on f_open or succeed with the file handle in an inconsistent state. The latter case is particularly problematic since by the time we call f_write, it might fail with FR_DISK_ERR, write to the wrong sector, or fail silently creating empty files. The remedy would be a full open-write-close cycle to reset. Consider catching and explicitly handling FatFS errors in _log_sdcard_close and ..._init, including handling file handle mismatches using the open-write-reset sequence. Inconsistencies can arise between file handle and filesystem state where the handle points to one location/size/buffer while the filesystem file has different properties. This cached data structure mismatch with the actual disk state could lead to problematic file operations (potential corruption, lost data, missed writes). This could be avoided through detection and synchronization of the file handle with the filesystem
- **Line 207** (cms_log_writer.c): consider removing dead code
- **Line 225** (cms_log_writer.c): consider removing dead code
- **Line 303** (cms_log_writer.c): consider replacing preprocessor directive and collecting integration tests.
- **Line 383** (cms_log_writer.c): use standard abstraction naming such as get_<private_variable_name>

### CMS STATE
- **Line 68** (cms_state.c): global state variable breaks encapsulation, make static and provide accessor functions; not necessary to expose for testing purposes. Low priority item
- **Line 70** (cms_state.c): same feedback, avoid exposing and access with get function
- **Line 83** (cms_state.c): typo in macro name SD_REQUIRED_FOR_DEVELOPEMENT, could be DEVELOPMENT
- **Line 86** (cms_state.c): preprocessor directive for runtime logic, consider using runtime boolean check instead
- **Line 106**: three volt rail will not be zero. Define and compare against constant POST_MIN_3V3_RAIL_VOLTAGE 
- **Line 112**: same magic number issue for 5V rail check
- **Line 118**: same magic number issue for 12V rail check
- **Line 124**: same magic number issue for battery voltage check
- **Voltage rail minimums**: Consider setting voltage rail minimums conservatively (+0/-0.5V) and setting battery minimums based on joulemeter/empirical data on expected operation time available at specific voltages (could be an R&D step when qualifying any change to battery model or vendor). Consider setting minimum for 5-10mins of operation so no unit is deployed that dies right when the interventionalist is prepared to aspirate.
- **Line 144**: function _power_is_in_range always returns true, consider implementing or removing
- **Line 166**: consider adding null check on fifo_writ_get_ptr return value before use
- **Line 191**: using assert for runtime safety check, consider using proper error handling instead
- **Line 299** (cms_state.c): direct hardware control in state logic, consider moving to abstraction layer; cms_state could invoke commands to devices (using their respective APIs) to maintain code isolation and readability (i.e. avoiding expressions like _set_valve_function(cms_state, config, false); which are false abstractions equivalent to pasting the hardware control code in the switch case). Each device API could have a set of commands and responses (including errors) which can be tabulated just like the FSM states. The transaction between the FSM and Device APIs could follow a consistent format with all device invocations being transparent at a plain-english level when reading the FSM code, and the responses and errors are specified and collected into the API code so that we can statically determine that our FSM code is extensive in handling all possible responses from the devices it invokes. If we encounter unforeseen errors in testing, we could update the device API (atomic updates) and device API spec/table (adding responses and errors) which we can then handle in the associated FSMs, statically verify that our handling is extensive, and once again have safe, traceable, readable code. Changes to device operation such as driving times and voltages could reside solely in the appropriate API, thus preserving the correctness of FSM code after atomic changes to device/hardware-level code.
- **Line 314** (cms_state.c): Consider converting all if/else code in each switch case into a preamble of boolean expressions to serve as predicates and switch statements within each FSM state for handling said predicates; The FSM and state transitions implements the device's state-transition matrix, even if we have not yet created this at the documentation level. Nested switches could provide clearer implementations of the state-transition matrix than switches with nested if statements. For states with many child predicates (a state which can transition to a large number of other states; i.e. high connectivity node), using one consistent syntactic structure could be beneficial.
- **Line 353** (cms_state.c): complex boolean condition spans multiple lines, extract to case's preamble as a standalone bool variable assigned to the whole expression for clarity.
- **Line 424**: unconditionally overwrites co2_ok state (if co2_ok is false then we reach PISTON_STATE_60_CONFIRMING_STOP and set it true, we are able to aspirate with the real condition being co2_ok false), consider removing this line entirely or adding comments to explain why
- **Line 508** (cms_state.c): unchecked _set_valve_state_and_latch, consider following rule set by function/assert
- **Line 554**: this computation could be performed once per tick, wrapped into cms_state
- **Line 564** (cms_state.c): timer_latch may be redundant, consider replacing with the logic; only two references
- **Line 598**: consider wrapping time delta computations into cms_state fields once per tick since they reference the times stored in cms_state
- **Line 624** (cms_state.c): we expose all cms_state modifications in this case, but we abstract them to short functions elsewhere. I propose migrating all cms_state modifications from function to case unless repeated more than twice; function abstractions not neecessary to implement abstraction of an API obfuscate the logic.
- **Line 735** (cms_state.c): consider removing 'false' prefix from or-only conditionals, redundant and will short-circuit if 'and's are added later
- **Line 748** (cms_state.c): make this whole statement a single assignment for clarity.
- **Line 785** (cms_state.c): suggest collecting computations directly influencing sensing state into one location in fsm; harder to evaluate when distributed across code.
- **Line 935** (cms_state.c): entire commented case block LED_STATE_900_VACUUM_STATE_CYCLE, consider removing dead code, we can retrieve from commit if needed
- **Line 971** (cms_state.c): consider collecting all prelude code from _update_X_state functions into a single tick-start function that sets fields in cms_state to be used elsewhere; consider storing the values we use for state transitions in cms_state instead of just-in-time variables, which ensures single point of modification to change computation behind a given value.
- **Line 1005** (cms_state.c): redundant true condition in if statement; consider removing all redundant hardcoded values in conditionals to reduce risk
- **Line 1006** (cms_state.c): we sometimes compute this in the prelude (e.g. is_imp_state_3) and sometimes in the conditional predicate. Consider picking one approach and applying it consistently; computing boolean statements in the predicate could provide better visibility of the state transition logic in each case. Consider keeping the state transition logic within the case.
- **Line 1045** (cms_state.c): commented audio_play call, consider implementing or removing
- **Line 1102** (cms_state.c): consolidate preprocessor directives
- **Line 1129** (cms_state.c): consolidate preprocessor directives: multiple test injection blocks scattered in main loop, extract to handle_integration_tests function
- **Line 1217** (cms_state.c): consolidate preprocessor directives: test packet availability override in production code, move to test mock layer
- **Line 1282** (cms_state.c): consolidate preprocessor directives: test CRC corruption in production code, move to test mock abstraction
- **Line 1392** (cms_state.c): dead timeout logic: confirm whether we want to restore this
- **Line 1494**: six consecutive ADC samples in main loop causing performance bottleneck, cache results with periodic asynchronous sampling

## HANDLE
### HAN STATE
- **Line 90** (han_state.c): hand_state includes interrupt context with comm_reply_callback()
- **Line 119** (han_state.c): *config never used
- **Line 124** (han_state.c): Consider simplifying the n_errors++ ... n_errors == 0 pattern; suggest returning -1 or true on first error encounter, 0 or false otherwise
- **Line 146**: consider implementing _power_is_in_range(); what data are we awaiting
- **Line 172**: consider implementing catching null fifo pointers (most likely caused by active or dead lock, which could be addressed in the logic.)
- **Line 255** (han_state.c): consider implementing timer latch here, it is only called twice and implements a few conditionals
- **Line 278** (han_state.c): consider implementing specific error states with same catchall behavior to give us the option to handle these errors individually later. STATE_OTHER_ERROR for the truly wildcard errors, and specific errors otherwise.
- **Line 312** (han_state.c): consider removing all hardcoded predicates to prevent accidental short-circuit on later modification
- **Line 320** (han_state.c): like timer_latch, consider replacing timer_elapsed with the implementation, this oneliner might not need to live in common/ as a new function; no side-effects or abstraction necessitating function definition.
- **Line 332** (han_state.c): specific error state needed routed to HAN_STATE_REMAIN case
- **Line 428** (han_state.c): consider separating debug code from production code
- **Line 443** (han_state.c): ineresting that default is 2000_ERROR while elsewhere we freeze state with HAN_STATE_REMAIN. In some cases, I see how STATE_REMAIN loops until we transition out, but could we create more detailed states to reflect specific error states and have the default by STATE_REMAIN or STATE_XXXX_DEFAULT?
- **Line 472** (han_state.c): Consider storing local _comm_... values in a struct compatible with HandleStatusPacket for direct assignment
- **Line 493**: Consider catching and logging, it would be helpful to know if these occur 
- **Line 499**: Consider logging collisions as above and determining the reply delay needed. UART analyzer will clarify frame timings and the appropriate delay, 25ms isn't incredibly long but may be too long for higher throughputs we might want down the line.

## COMMON
### COMMON
- **Line 337**: Consider completing or removing stack_check()
- **Line 289** (common.c): Note that inquis_assert_failed is never called

### LOG
- **Line 110** (log.c): Error string pointer tracking is inefficient, there is information in repeated, non-fatal errors, so we should delegate responsibility of desired error logic to caller

### BBSTR
- **BBSTR API** (bbstr.c): Consider checking if there is a need for BBSTR API instead of using C string. We could either build a better string than C's implementation or use their implementation; might not need both.

### LED DRIVER
- **Line 129** (led_driver.c): err != 0 ? 1 : 0 can be simplified to err ? 1 : 0

---

