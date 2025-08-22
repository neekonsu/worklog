# Inquis Gen 2 - Gen 3 Codebase Suggestions for Zach S.
*The following suggestions are derived from code reviewed in the main branch of inquis_gen_2_2 <877e567d7b8383b5dc6bacf775bbc0a010b0521e> and inquis_gen_3_0 <9dfa6d65ccb128b5cd307f8082603f34d296797b>*

## GEN3

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
- 104 function never called
[15h10 22 aug 2025 ~ faster to drop these questions and comments into powerpoint from the getgo]
**Suggestions:**

#### LOG
**Questions:**
- note to self to check where emit_log_error_once is called; may be unsafe given warning about static/dynamic string usage
- note to self to make suggestion regarding base case of empty comment in emit_log_comment_record, which returns instead of emitting associated default comment, allowing for accidentally implementing silent errors (should not be possible)
- 
**Suggestions:**

### HANDLE

### COMMON
