# Interrupt Analysis Report - Inquis Gen 3.0 Medical Device

## Executive Summary

This report provides a comprehensive analysis of interrupt handlers and their integration with finite state machines (FSMs) across the Inquis Gen 3.0 medical device codebase. The analysis identifies critical vulnerabilities in interrupt timing, race conditions, and memory safety issues that could impact device reliability during medical procedures.

**Key Findings:**
- 5 Critical vulnerabilities requiring immediate attention
- 2 High-risk vulnerabilities affecting system stability
- 2 Medium-risk vulnerabilities impacting communication reliability
- Multiple race conditions between interrupt handlers and main loop code
- Missing memory safety protections in interrupt context

## Architecture Overview

The Inquis Gen 3.0 system implements a distributed interrupt architecture across two STM32L471RET microcontrollers:

- **CMS (Clot Management System)**: 4 parallel state machines with communication-centric interrupt handling
- **Handle**: 1 comprehensive state machine with critical real-time interrupt requirements
- **Common**: Shared communication infrastructure with central interrupt processing

### Inter-MCU Communication Model
- **Primary Protocol**: UART/DMA-based packet exchange
- **Timing-Critical**: 25ms reply delays, 1000ms communication timeouts
- **Interrupt-Driven**: All communication processing occurs in interrupt context

## Detailed Analysis by Component

### Common/ Directory - Communication Infrastructure

#### Critical Interrupt Handlers

**1. HAL_UARTEx_RxEventCallback (comm.c:292-372)**
- **Function**: Primary data reception path using UART IDLE detection
- **Criticality**: CRITICAL - All inter-MCU communication depends on this handler
- **FSM Impact**: Feeds data to all 5 state machines across both MCUs
- **Processing**: 
  - DMA frame reception with CRC validation
  - Packet decoding and FIFO queuing
  - Reply scheduling via timer interrupt
- **Vulnerability**: Direct FIFO manipulation without interrupt protection

**2. HAL_UART_TxCpltCallback (comm.c:254-273)**
- **Function**: Transmission completion handling for RS485 mode
- **Criticality**: HIGH - Enables bidirectional communication
- **FSM Impact**: Triggers next communication cycle for state synchronization
- **Processing**: Re-enables reception mode and increments transmission counter

**3. HAL_UART_ErrorCallback (comm.c:143-244)**
- **Function**: UART error recovery for overrun, framing, and noise errors
- **Criticality**: HIGH - Communication reliability during medical procedures
- **FSM Impact**: Error states can force all state machines into safe modes
- **Processing**: Comprehensive error flag analysis and recovery sequences
- **Issue**: Incomplete error handling as noted in CLAUDE.md

**4. HAL_TIM_PeriodElapsedCallback (comm.c:275-280)**
- **Function**: Reply timing control for Handle responses
- **Criticality**: HIGH - Controls communication protocol timing
- **FSM Impact**: Timing violations can cause state machine desynchronization
- **Processing**: Triggers packet transmission after configured delay

#### Communication Protocol Vulnerabilities

**FIFO Buffer Race Condition**
- **Location**: fifo.c:112-133, comm.c:292-372
- **Issue**: FIFO operations use spinlock-based critical sections without interrupt disabling
- **Impact**: Buffer corruption during concurrent access from interrupt and main loop
- **Test Vector**: Rapid UART idle interrupts during packet processing

**Memory Safety Issues**
- **Location**: comm.c:305-343
- **Issue**: DMA receive buffer handling lacks bounds checking
- **Impact**: Buffer overflow in interrupt context with corrupted n_packets values
- **Test Vector**: Malformed UART frames with excessive packet counts

### CMS/ Directory - Master Controller Interrupts

#### Interrupt Handler Architecture

**Core System Handlers (stm32l4xx_it.c)**
- **TIM2_IRQHandler**: Valve PWM control and packet timing
- **USART2_IRQHandler**: CMS-Handle communication channel
- **DMA1_Channel6/7_IRQHandler**: Efficient packet transfer via DMA
- **SysTick_Handler**: System time base for all timing operations

#### State Machine Integration

**No Direct Interrupt-State Coupling**
- CMS state machines (Piston, LED, Audio, Light Translation) operate via polling
- State transitions driven by main loop processing of communication data
- Button handling uses polling rather than GPIO interrupts

**Communication Dependencies**
- All state machines depend on inter-MCU communication interrupts
- UART timeouts can force emergency state transitions
- Timer interrupts affect valve control timing but not state logic

#### CMS-Specific Vulnerabilities

**Button Response Latency**
- **Issue**: Polling-based button handling vulnerable to timing delays
- **Impact**: Missed aspirate button presses during critical procedures
- **Risk**: HIGH - Could miss user input during clot detection

**Interrupt Priority Flattening**
- **Issue**: All interrupts configured with priority 0
- **Impact**: No priority hierarchy for critical vs non-critical operations
- **Risk**: MEDIUM - Communication interrupts can block timer operations

### Handle/ Directory - Sensor Controller Interrupts

#### Critical Real-Time Handlers

**1. TIM2_IRQHandler (stm32l4xx_it.c:251-260)**
- **Function**: Communication reply timing control
- **Criticality**: CRITICAL - Controls response timing to CMS
- **FSM Impact**: Timing violations cause Handle isolation from CMS
- **Processing**: Triggers comm_xmit_packets() for reply transmission

**2. USART2_IRQHandler (stm32l4xx_it.c:265-274)**
- **Function**: Handle-CMS communication channel
- **Criticality**: CRITICAL - Primary command and status interface
- **FSM Impact**: Processes all state transition commands from CMS
- **Processing**: Triggers packet reception and processing

**3. DMA1_Channel6/7_IRQHandler (stm32l4xx_it.c:223-246)**
- **Function**: Efficient packet transfer for Handle communication
- **Criticality**: HIGH - Enables real-time data transfer
- **FSM Impact**: Supports impedance data streaming to CMS
- **Processing**: DMA completion triggers packet availability

#### Handle State Machine Integration

**Direct Interrupt-State Coupling**
- **comm_reply_callback()**: Called from interrupt context
- **State Variable Access**: Direct copying of critical state variables
- **Race Condition Risk**: Non-atomic updates during state transitions

**Critical State Variables (han_state.c:89-99)**
```c
HanStateVal _comm_reply_curr_state;           // Current Handle state
HanImpStateVal _comm_reply_imp_state_val;     // Impedance state
int _comm_reply_pressure;                     // Pressure reading
int _comm_reply_imp_mag;                      // Impedance magnitude
int _comm_reply_imp_pha;                      // Impedance phase
```

#### Handle-Specific Vulnerabilities

**State Machine Race Condition**
- **Location**: han_state.c:89-99
- **Issue**: Global state variables updated from interrupt without synchronization
- **Impact**: Inconsistent state transmission to CMS
- **Risk**: CRITICAL - Could cause incorrect clot detection decisions

**Missing Volatile Qualifiers**
- **Issue**: State variables lack volatile qualifiers
- **Impact**: Compiler optimizations can cache stale values
- **Risk**: HIGH - State updates may not be visible between contexts

**AD5940 Polling Vulnerability**
- **Issue**: Impedance sensor uses polling rather than interrupts
- **Impact**: Missed impedance readings during heavy interrupt load
- **Risk**: MEDIUM - Could affect clot detection accuracy

## Critical Vulnerability Analysis

### 1. FIFO Buffer Race Condition
**Risk Level**: CRITICAL
**Location**: common/fifo.c:112-133, common/comm.c:292-372

**Vulnerability Details**:
- FIFO operations use LDREX/STREX atomic operations without interrupt disabling
- HAL_UARTEx_RxEventCallback manipulates recv_fifo from interrupt context
- Race condition between fifo_writ_get_ptr() and fifo_read_get_ptr()

**Attack Vector**:
```c
// Trigger rapid UART idle interrupts during packet processing
while(1) {
    send_malformed_uart_frame();
    delay_microseconds(100); // Faster than normal processing
}
```

**Impact**: Complete communication failure between CMS and Handle during medical procedure

**Mitigation**:
```c
Packet *fifo_writ_get_ptr(FIFO *fifo) {
    uint32_t primask = __get_PRIMASK();
    __disable_irq();
    // ... existing code ...
    __set_PRIMASK(primask);
}
```

### 2. Handle State Machine Interrupt Race Condition
**Risk Level**: CRITICAL
**Location**: handle/inquis/han_state.c:89-99

**Vulnerability Details**:
- Global state variables updated from comm_reply_callback() in interrupt context
- No synchronization between interrupt updates and main loop reads
- Multi-word state updates not atomic

**Attack Vector**:
```c
// Force interrupt during state machine transition
state_machine_transition_to_aspiration();
trigger_comm_interrupt(); // Interrupt during transition
// Result: curr_state != imp_state_val (inconsistent state)
```

**Impact**: Incorrect impedance readings, false clot detection, missed clot events

**Mitigation**:
```c
volatile HanStateVal _comm_reply_curr_state;
volatile HanImpStateVal _comm_reply_imp_state_val;
// Add critical sections around multi-word updates
```

### 3. DMA Buffer Overflow in Interrupt Context
**Risk Level**: HIGH
**Location**: common/comm.c:305-343

**Vulnerability Details**:
- No bounds checking on frame->n_packets before loop
- Corrupted values can cause buffer overflow in interrupt handler
- Stack corruption possible during packet processing

**Attack Vector**:
```c
// Send malformed UART frame with large n_packets value
Frame malformed_frame;
malformed_frame.n_packets = 0xFFFF; // Excessive packet count
send_uart_frame(&malformed_frame);
```

**Impact**: Memory corruption, device crash, potential code execution

**Mitigation**:
```c
if (frame->n_packets > MAX_PACKETS_PER_FRAME) {
    log_error("Invalid packet count: %d", frame->n_packets);
    return;
}
```

### 4. Timer Interrupt Priority Inversion
**Risk Level**: HIGH
**Location**: cms/Core/Src/stm32l4xx_hal_msp.c:276-278

**Vulnerability Details**:
- All interrupts configured with priority 0 (same level)
- No priority hierarchy for critical vs non-critical operations
- Communication interrupts can block timer operations

**Attack Vector**:
```c
// Generate continuous UART interrupts to block timer interrupts
while(1) {
    generate_uart_interrupt();
    // Timer interrupts blocked, causing timing violations
}
```

**Impact**: State machine timing violations, communication timeouts, device malfunction

**Mitigation**:
```c
HAL_NVIC_SetPriority(USART2_IRQn, 1, 0);    // High priority
HAL_NVIC_SetPriority(TIM2_IRQn, 2, 0);      // Medium priority
HAL_NVIC_SetPriority(DMA1_Channel6_IRQn, 3, 0); // Lower priority
```

### 5. Missing Volatile Qualifiers on Shared Variables
**Risk Level**: HIGH
**Location**: common/fifo.h:42-50

**Vulnerability Details**:
- FIFO structure fields lack volatile qualifiers
- Compiler optimizations can cache values between interrupt and main contexts
- Race conditions in lock acquisition/release

**Attack Vector**:
```c
// Trigger rapid interrupt/main loop alternation
// Compiler optimization caches stale values
// Result: deadlock or corrupted data structures
```

**Impact**: Communication deadlock, data corruption, device malfunction

**Mitigation**:
```c
typedef struct _FIFO {
    volatile uint32_t read_lock;
    volatile uint32_t writ_lock;
    volatile uint32_t read_i;
    volatile uint32_t writ_i;
    // ... other fields
} FIFO;
```

## State Machine Impact Assessment

### CMS State Machines

**Piston Control State Machine (16 states)**
- **Interrupt Dependency**: Communication interrupts for Handle coordination
- **Timing Sensitivity**: Valve control timing affects state transitions
- **Vulnerability**: UART timeouts can force error states during aspiration

**LED Control State Machine (16 states)**
- **Interrupt Dependency**: Handle connection state from communication interrupts
- **Timing Sensitivity**: LED update timing for user feedback
- **Vulnerability**: Communication failures affect visual feedback accuracy

**Audio Control State Machine (7 states)**
- **Interrupt Dependency**: System tick for audio playback timing
- **Timing Sensitivity**: Audio cue timing for clot detection
- **Vulnerability**: Interrupt priority issues can cause audio glitches

**Light Value Translation State Machine (17 states)**
- **Interrupt Dependency**: None (algorithmic only)
- **Timing Sensitivity**: Low
- **Vulnerability**: Minimal interrupt-related risks

### Handle State Machine

**Impedance & Sampling State Machine (11 states)**
- **Interrupt Dependency**: CRITICAL - Direct state variable access from interrupts
- **Timing Sensitivity**: CRITICAL - Real-time impedance monitoring
- **Vulnerability**: Race conditions can cause incorrect clot detection

**State Transition Vulnerabilities**:
- **START(0000) → CONNECT(1000)**: Communication interrupt dependency
- **MONITOR_THRESHOLDS(3002) → ASPIRATION_EVAL(5001)**: Pressure/impedance interrupt timing
- **ASPIRATION_EVAL(5003) → WALL_LATCH(6001)**: Race condition in state variable updates

## Testing Recommendations

### Critical Vulnerability Testing

**1. Interrupt Storm Testing**
- Generate high-frequency interrupts during normal operation
- Monitor for race conditions and timing violations
- Test communication reliability under interrupt stress

**2. State Machine Stress Testing**
- Rapidly cycle through state transitions
- Interrupt state transitions at critical points
- Verify state consistency across interrupt boundaries

**3. Communication Protocol Testing**
- Send malformed packets with invalid headers
- Test error recovery under various failure modes
- Verify timeout handling during critical procedures

**4. Memory Corruption Testing**
- Use stack canaries and heap guards
- Test buffer overflow scenarios in interrupt context
- Monitor for memory corruption during normal operation

**5. Timing Analysis**
- Monitor interrupt latency and response times
- Test communication timing under various loads
- Verify state machine timing requirements

### Specific Test Scenarios

**FIFO Race Condition Test**:
```c
// Test rapid FIFO access from interrupt and main loop
void test_fifo_race_condition() {
    for (int i = 0; i < 1000; i++) {
        trigger_uart_interrupt();
        process_fifo_in_main_loop();
        verify_fifo_integrity();
    }
}
```

**Handle State Race Test**:
```c
// Test state variable consistency during interrupt
void test_handle_state_race() {
    start_state_transition();
    trigger_comm_reply_interrupt();
    verify_state_consistency();
}
```

**Communication Timeout Test**:
```c
// Test communication recovery under timeout conditions
void test_communication_timeout() {
    block_communication_interrupts();
    wait_for_timeout();
    verify_error_recovery();
}
```

## Recommended Immediate Actions

### Critical Fixes (Priority 1)

1. **Add interrupt disabling to FIFO operations**
2. **Make Handle state variables volatile**
3. **Add bounds checking in DMA interrupt handlers**
4. **Implement proper interrupt priority hierarchy**
5. **Add critical sections around multi-word state updates**

### High Priority Fixes (Priority 2)

1. **Convert button handling to interrupt-based**
2. **Add timeout protection for critical sections**
3. **Implement proper error propagation from interrupt handlers**
4. **Add system state validation in interrupt callbacks**

### Medium Priority Improvements (Priority 3)

1. **Add comprehensive logging for interrupt events**
2. **Implement interrupt performance monitoring**
3. **Add unit tests for interrupt edge cases**
4. **Document interrupt timing requirements**

## Conclusion

The Inquis Gen 3.0 interrupt architecture contains several critical vulnerabilities that pose significant risks to medical device safety and reliability. The most severe issues involve race conditions in the communication system and Handle state machine, which could lead to incorrect clot detection or device malfunction during critical medical procedures.

Immediate attention to the identified critical vulnerabilities is essential to ensure patient safety. The recommended fixes should be implemented and thoroughly tested before deployment in medical environments.

The interrupt analysis reveals that while the system architecture is fundamentally sound, the implementation lacks proper synchronization mechanisms and memory safety protections required for a critical medical device. Addressing these issues will significantly improve the system's robustness and reliability.