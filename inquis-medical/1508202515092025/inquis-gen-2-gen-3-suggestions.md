# Inquis Gen 2 - Gen 3 Codebase Suggestions for Zach S.
*The following suggestions are derived from code reviewed in the main branch of inquis_gen_2_2 <877e567d7b8383b5dc6bacf775bbc0a010b0521e> and inquis_gen_3_0 <9dfa6d65ccb128b5cd307f8082603f34d296797b>*

## GEN3

### CMS
#### CLI
**Questions:**
- what is cfg_overload for
- _<funName> -> local and <funName> -> global?
- n t s to check sd_card_mount() and see why/if it is okay to emit non-blocking error if error thrown
- n t s to check check_string_allocates(0,0) if the check is safe / comprehensive for potential string memory leaks
**Suggestions:**

#### LOG
**Questions:**
- note to self to check where emit_log_error_once is called; may be unsafe given warning about static/dynamic string usage
- note to self to make suggestion regarding base case of empty comment in emit_log_comment_record, which returns instead of emitting associated default comment, allowing for accidentally implementing silent errors (should not be possible)
- 
**Suggestions:**

### HANDLE

### COMMON
