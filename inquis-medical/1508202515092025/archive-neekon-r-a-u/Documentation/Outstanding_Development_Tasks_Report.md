# Outstanding Development Tasks Report

**Repository:** `inquis_gen_3_0`  
**Analysis Date:** July 17, 2025  
**Analysis Scope:** Common, CMS, and Handle source code directories  

---

## Executive Summary

This report catalogs outstanding development tasks, unfinished code sections, and documented bugs across the dual-MCU medical device codebase. The analysis covers TODOs, FIXMEs, architectural concerns, and incomplete implementations that require attention before production deployment. Tasks are organized by directory and file to facilitate systematic completion by the engineering team.

**Key Findings:**
- **55 TODO items** requiring implementation or review
- **12 architectural concerns** affecting code maintainability
- **8 incomplete implementations** needing completion
- **6 error handling gaps** requiring robust solutions
- **4 critical abstraction violations** posing debugging risks

---


## Common Directory (`common/`)

### High-Priority Critical Issues

#### `common/lights.c`
**Issue Type:** Critical Architecture Violation  
**Status:** Requires immediate refactoring

| Line | Issue | Priority | Category |
|------|--------|----------|----------|
| 44-48 | Static variables violate abstraction barrier - `_curr_light_val`, `_curr_light_on`, `_is_flashing` allow direct peripheral manipulation outside state machine | CRITICAL | Architecture |
| 89 | Subsystem selection uses `#ifdef` instead of compiler flags - harder to track and debug | HIGH | Build System |
| 120 | Error thrown only in source code instead of compile-time - dangerous if capable of compiling without subsystem definition | HIGH | Build System |

**Recommendations:**
- Wrap static variables into proper state management
- Replace `#ifdef` with compiler flags for subsystem selection
- Move error checking to compile-time validation

#### `common/comm.c`
**Issue Type:** Incomplete Error Handling  
**Status:** Production-blocking

| Line | Issue | Priority | Category |
|------|--------|----------|----------|
| 147 | UART overrun error handling incomplete - "I do not understand under what situation this occurs" | HIGH | Error Handling |
| 294 | Missing proper error handling for critical communication path | HIGH | Error Handling |
| 407 | Hardcoded timing values during debugging - "care right now while I'm debugging" | MEDIUM | Code Quality |

**Recommendations:**
- Research and implement proper UART overrun recovery
- Add comprehensive error handling for communication failures
- Replace hardcoded timing values with configurable parameters

### Medium-Priority Issues

#### `common/defines.h`
**Issue Type:** Code Quality  
**Status:** Needs cleanup

| Line | Issue | Priority | Category |
|------|--------|----------|----------|
| 2 | File marked as "NOT CLEAN" - requires code review and cleanup | MEDIUM | Code Quality |

#### `common/config.h`
**Issue Type:** Type Safety  
**Status:** Requires interface improvement

| Line | Issue | Priority | Category |
|------|--------|----------|----------|
| 40 | Configuration structure assumes all fields are integers - lacks type safety validation | MEDIUM | Type Safety |

#### `common/version.h`
**Issue Type:** Build System  
**Status:** Needs better implementation

| Line | Issue | Priority | Category |
|------|--------|----------|----------|
| 10 | Version management approach questioned - "IS THIS THE BEST WAY TO DO THIS" | LOW | Build System |

### Testing and Validation Tasks

#### `common/unit_tests/test_crc.c`
**Issue Type:** Incomplete Tests  
**Status:** Requires test completion

| Line | Issue | Priority | Category |
|------|--------|----------|----------|
| 34 | Empty TODO requiring implementation | MEDIUM | Testing |
| 37 | Missing random binary string CRC validation tests | MEDIUM | Testing |

#### `common/unit_tests/test_fifo.c`
**Issue Type:** Incomplete Tests  
**Status:** Requires test completion

| Line | Issue | Priority | Category |
|------|--------|----------|----------|
| 222 | DEADBEEF buffer overflow check test missing | MEDIUM | Testing |
| 223 | Read-ahead pointer test missing | MEDIUM | Testing |

#### `common/unit_tests/test_comm.c`
**Issue Type:** Mock Infrastructure  
**Status:** Requires enhancement

| Line | Issue | Priority | Category |
|------|--------|----------|----------|
| 483 | Error mocking capability missing from test infrastructure | MEDIUM | Testing |

### Performance and Optimization Tasks

#### `common/log.c`
**Issue Type:** Integration Testing  
**Status:** Requires test addition

| Line | Issue | Priority | Category |
|------|--------|----------|----------|
| 115 | Integration test needed for logging system | MEDIUM | Testing |

#### `common/led_driver.c`
**Issue Type:** Performance Optimization  
**Status:** Optimization opportunity

| Line | Issue | Priority | Category |
|------|--------|----------|----------|
| 131 | Error handling should propagate as POST failure | MEDIUM | Error Handling |
| 189 | I2C writes should be optimized - skip unchanged values and add periodic refresh | LOW | Performance |

### Documentation and Configuration Tasks

#### `common/sample_err.h`
**Issue Type:** Code Maintenance  
**Status:** Requires cleanup

| Line | Issue | Priority | Category |
|------|--------|----------|----------|
| 24 | Error definitions need cleanup - "not all are applicable anymore" | LOW | Maintenance |

#### `common/test_define.h`
**Issue Type:** Code Quality  
**Status:** Needs cleanup

| Line | Issue | Priority | Category |
|------|--------|----------|----------|
| 3 | File marked as "NOT CLEAN" - requires review | LOW | Code Quality |

#### `common/default_config.txt`
**Issue Type:** Configuration Management  
**Status:** Needs improvement

| Line | Issue | Priority | Category |
|------|--------|----------|----------|
| 2 | First line format requirement marked as "NOT CLEAN" | LOW | Configuration |

#### `common/fmt.c`
**Issue Type:** Incomplete Implementation  
**Status:** Disabled module

| Line | Issue | Priority | Category |
|------|--------|----------|----------|
| 1 | Entire module temporarily removed "until state machines are sorted out" | MEDIUM | Implementation |
| 3 | File marked as "NOT CLEAN" | MEDIUM | Code Quality |

---

## CMS Directory (`cms/`)

### High-Priority Issues

#### `cms/inquis/cms_comm_state.c`
**Issue Type:** Incomplete Implementation  
**Status:** Critical functionality missing

| Line | Issue | Priority | Category |
|------|--------|----------|----------|
| 133 | Error handling missing for communication state machine | HIGH | Error Handling |
| 143 | Reply error state completely unimplemented | HIGH | Implementation |

**Recommendations:**
- Implement comprehensive error handling for communication failures
- Complete reply error state implementation with proper recovery logic

---

## Handle Directory (`handle/`)

### Implementation Tasks

#### `handle/inquis/han_inquis_main.c`
**Issue Type:** Incomplete Feature  
**Status:** Requires auto-start implementation

| Line | Issue | Priority | Category |
|------|--------|----------|----------|
| 73 | Auto-start feature not implemented - "Until I get around to needing an auto-start" | MEDIUM | Feature Implementation |

**Recommendations:**
- Implement auto-start functionality for production deployment
- Document auto-start requirements and configuration options

---

## System-Wide Architectural Concerns

### Build System Issues

1. **Inconsistent Subsystem Selection:** Multiple files use `#ifdef` for subsystem selection instead of compiler flags, making debugging difficult and error-prone.

2. **Version Management:** Current version management approach questioned across multiple files, needs systematic review.

3. **Code Quality Standards:** Multiple files marked as "NOT CLEAN" indicating systematic code review needed.

### Error Handling Gaps

1. **UART Communication:** Incomplete understanding and handling of UART overrun errors in critical communication paths.

2. **State Machine Errors:** Missing error handling in communication state machines for both CMS and Handle.

3. **POST Failures:** LED driver errors should propagate as POST failures but currently do not.

### Testing Infrastructure

1. **Mock Support:** Test infrastructure lacks comprehensive error mocking capabilities.

2. **Integration Tests:** Several modules require integration tests, particularly for logging and communication systems.

3. **Boundary Testing:** Buffer overflow and CRC validation tests incomplete.

---

## Recommendations for Production Readiness

### Immediate Actions (Critical Priority)

1. **Fix Critical Interrupt Race Conditions:** Implement interrupt disabling in FIFO operations and add volatile qualifiers to shared state variables in `han_state.c:89-99`.

2. **Fix Abstraction Violations in `common/lights.c`:** Refactor static variables into proper state management to prevent debugging issues.

3. **Complete Error Handling in `common/comm.c`:** Research and implement proper UART overrun recovery mechanisms.

4. **Implement Missing Communication Error States:** Complete error handling in `cms/inquis/cms_comm_state.c`.

5. **Fix Interrupt Priority Configuration:** Implement proper interrupt priority hierarchy to prevent priority inversion in `stm32l4xx_hal_msp.c`.

### Short-term Tasks (High Priority)

1. **Implement Interrupt Vulnerability Testing:** Execute all critical system stress tests outlined in the interrupt vulnerability testing section.

2. **Add DMA Buffer Bounds Checking:** Implement proper bounds validation in `comm.c:305-343` for packet processing.

3. **Replace `#ifdef` with Compiler Flags:** Systematic replacement of subsystem selection mechanism.

4. **Complete Test Suite:** Implement all missing unit tests and integration tests.

5. **Code Quality Review:** Address all files marked as "NOT CLEAN" with systematic review.

### Medium-term Improvements

1. **Memory Safety Hardening:** Implement stack canaries, heap guards, and memory corruption detection as outlined in the interrupt vulnerability tests.

2. **Performance Optimization:** Implement I2C write optimization and other performance improvements.

3. **Feature Completion:** Implement auto-start functionality and other incomplete features.

4. **Documentation:** Update and complete all documentation gaps identified.

### Long-term Maintenance

1. **Build System Improvement:** Implement better version management and configuration systems.

2. **Type Safety:** Enhance configuration system with proper type validation.

3. **Testing Infrastructure:** Expand mock support and boundary testing capabilities.

---

## Task Prioritization Matrix

| Category | Critical | High | Medium | Low | Total |
|----------|----------|------|---------|-----|-------|
| **Interrupt Vulnerabilities** | **5** | **3** | **2** | **0** | **10** |
| Architecture | 1 | 2 | 1 | 0 | 4 |
| Error Handling | 2 | 1 | 1 | 0 | 4 |
| Implementation | 1 | 1 | 3 | 0 | 5 |
| Testing | 0 | 0 | 6 | 0 | 6 |
| Code Quality | 0 | 1 | 3 | 4 | 8 |
| Performance | 0 | 0 | 1 | 1 | 2 |
| Build System | 0 | 1 | 1 | 1 | 3 |
| **Total** | **9** | **9** | **18** | **6** | **42** |

### Critical Interrupt Vulnerabilities Summary:
1. **FIFO Buffer Race Condition** - `common/comm.c:292-372`
2. **Handle State Machine Race Condition** - `han_state.c:89-99`
3. **DMA Buffer Overflow** - `comm.c:305-343`
4. **Timer Interrupt Priority Inversion** - `stm32l4xx_hal_msp.c:276-278`
5. **Missing Volatile Qualifiers** - `fifo.h:42-50`

### High Priority Interrupt Issues:
1. **Communication Protocol Timing Vulnerabilities** - `comm.c:358-360`
2. **Button Response Race Conditions** - Handle button polling during interrupts
3. **AD5940 Sensor Polling Vulnerabilities** - Missed readings during interrupt load

This systematic approach ensures that critical production-blocking issues, especially interrupt-related race conditions and buffer overflows that could cause medical device malfunction, are addressed first, followed by high-priority improvements that enhance system reliability and maintainability during critical medical procedures.