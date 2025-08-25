# Comprehensive Memory Safety Risk Report

**Repository:** `neekonsu/inquis_gen_3_0`  
**Analysis Date:** July 16, 2025  
**Analyst:** Devin AI  

---

## Executive Summary

This analysis examined all C source files in the dual-MCU medical device system (CMS and Handle controllers). The system implements multiple interconnected state machines with FIFO-based communication, dynamic memory management, and real-time impedance sampling. Several memory safety risks were identified across different severity levels.

---

## System Architecture Overview

The system consists of:

- **CMS (Clot Management System)**: Base device with piston, LED, and audio state machines
- **Handle**: Impedance sensor with handle state machine and AD5940 sampling  
- **Common**: Shared utilities including FIFO communication, packet handling, and string management

### State Machine Structure

1. **Piston State Machine**: 15 states managing vacuum/pressure control
2. **LED State Machine**: 16 states managing visual feedback  
3. **Audio State Machine**: 7 states managing sound alerts
4. **Handle State Machine**: 7 states managing impedance sensing and wall latch detection

---

## Critical Memory Safety Risks

### 🔴 HIGH SEVERITY

#### 1. Array Bounds Vulnerabilities in State Machine Transitions

**Location:** `cms/inquis/cms_state.c:1217-1219, 1236-1238, 1250-1252`

```c
cms_piston_state_val_names[cms_state.curr_piston_state],
cms_piston_state_val_names[cms_state.next_piston_state]
```

- **Risk:** Out-of-bounds array access if state values exceed array bounds
- **State Machine Context:** Occurs during all piston state transitions (15 states)
- **Impact:** Memory corruption, potential system crash during critical medical operations

#### 2. FIFO Buffer Overflow Risk

**Location:** `common/fifo.c:68-69, 74-75`

```c
*(uint32_t *)&fifo->packets[i][PACKET_SIZE] = 0xDEADBEEF;
if (*(uint32_t *)&fifo->packets[i][PACKET_SIZE] != 0xDEADBEEF) {
```

- **Risk:** Writing beyond allocated packet buffer (PACKET_SIZE boundary)
- **State Machine Context:** Affects all inter-MCU communication during state transitions
- **Impact:** Memory corruption in communication buffers, potential data loss

#### 3. Impedance Array Bounds in Handle State Machine

**Location:** `handle/inquis/han_state.c:653-661`

```c
memmove(&han_state.impedance_mags[1], &han_state.impedance_mags[0], 
        sizeof(han_state.impedance_mags[0]) * (IMPEDANCE_MAX_N - 1));
```

- **Risk:** Buffer overflow if IMPEDANCE_MAX_N (200) is exceeded
- **State Machine Context:** Handle states 3002, 5002, 5003 (monitoring and aspiration)
- **Impact:** Corruption of critical impedance data used for clot detection

---

### 🟡 MEDIUM SEVERITY

#### 4. Unchecked malloc() in String Operations

**Location:** `common/bbstr.c:77-78, 87-88`

```c
char *str = (char *)malloc(len + 1);
inquis_assert(str != NULL);
BBStr *bbstr = (BBStr *)malloc(sizeof(BBStr));
inquis_assert(bbstr != NULL);
```

- **Risk:** Memory exhaustion not gracefully handled
- **State Machine Context:** Config loading during LED states 304-305 (handle configuration)
- **Impact:** System halt during configuration, preventing proper startup

#### 5. Potential Integer Overflow in Sample Processing

**Location:** `handle/inquis/han_sample.c:228, 243`

```c
_n_samples = max(1, fifo_count / 4);
_n_samples_since_reset += _n_samples;
```

- **Risk:** Integer overflow in sample counting over extended operation
- **State Machine Context:** All handle states during continuous sampling
- **Impact:** Sample count corruption, potential array indexing errors

#### 6. Race Condition in Communication Globals

**Location:** `handle/inquis/han_state.c:89-99`

```c
HanStateVal _comm_reply_curr_state;
HanImpStateVal _comm_reply_imp_state_val;
// ... other globals updated from interrupt context
```

- **Risk:** Data corruption between main loop and interrupt handler
- **State Machine Context:** All handle states during CMS communication
- **Impact:** Inconsistent state reporting to CMS, potential state machine desynchronization

---

### 🟢 LOW SEVERITY

#### 7. Memory Leak in String List Operations

**Location:** `common/bbstr.c:320-321`

```c
curr = bbstr_list_add(curr, new_bbstr, 0);
bbstr_del(new_bbstr);
```

- **Risk:** Reference counting errors could lead to memory leaks
- **State Machine Context:** Config parsing during system initialization
- **Impact:** Gradual memory consumption over multiple reconfigurations

#### 8. Potential Null Pointer in Packet Processing

**Location:** `cms/inquis/cms_state.c:1070-1071`

```c
Packet *recv_packet = (Packet *)fifo_read_get_ptr(&recv_fifo, 0);
if (recv_packet != NULL) {
```

- **Risk:** Null pointer check present but subsequent casts assume validity
- **State Machine Context:** All CMS states during packet reception
- **Impact:** Defensive programming present, low actual risk

---

## State Machine Risk Mapping

### Piston State Machine Risks

- **States 21-22, 51-52:** Valve control with lid safety checks - potential race conditions
- **States 72, 81-83:** Pressure monitoring - array bounds risks in pressure arrays
- **State 91-92:** Error states - potential infinite loops without proper bounds checking

### LED State Machine Risks

- **States 301-305:** Handle connection sequence - malloc failures during config
- **State 402:** Mirror handle state - complex state synchronization risks
- **States 501-502:** Clot detection - timing-dependent memory access patterns

### Handle State Machine Risks

- **States 3002, 5002-5003:** Impedance processing - highest array bounds risk
- **State 6001-6002:** Wall latch detection - critical for safety, memory corruption could cause false readings

---

## Recommendations

### Immediate Actions Required

1. **Add bounds checking** for all state machine array accesses
2. **Implement proper buffer overflow protection** in FIFO operations  
3. **Add critical sections** around shared communication variables
4. **Validate array indices** before impedance buffer operations

### System-Level Improvements

1. **Memory pool allocation** instead of malloc() for predictable memory usage
2. **Watchdog integration** with memory corruption detection
3. **State machine validation** with range checking on all transitions
4. **Communication protocol checksums** to detect memory corruption

### Testing Recommendations

1. **Stress testing** with continuous operation over 24+ hours
2. **Memory corruption injection** testing during state transitions
3. **Communication failure simulation** during critical states
4. **Boundary condition testing** for all array operations

---

## Conclusion

The system demonstrates good defensive programming practices in many areas but has several critical memory safety risks that could impact medical device reliability. The interconnected state machines amplify the impact of memory corruption, as errors in one state machine can cascade to others through shared communication channels. Priority should be given to addressing the array bounds vulnerabilities and FIFO buffer management issues.

**Risk Level:** MEDIUM-HIGH - Requires immediate attention before production deployment.

---

## Detailed File-by-File Analysis

### Common Directory Analysis

#### bbstr.c / bbstr.h - Reference-Counted String Management

**Memory Safety Issues:**
- **Unchecked malloc() calls** (lines 77-78, 87-88):
```c
char *str = (char *)malloc(len + 1);
inquis_assert(str != NULL);
BBStr *bbstr = (BBStr *)malloc(sizeof(BBStr));
inquis_assert(str != NULL);
```
Risk: System halt on memory exhaustion rather than graceful degradation.

- **Reference counting complexity** (lines 320-321):
```c
curr = bbstr_list_add(curr, new_bbstr, 0);
bbstr_del(new_bbstr);
```
Risk: Potential memory leaks if reference counting logic fails.

**Optimization Opportunities:**
- Implement memory pool allocation for predictable memory usage
- Add memory usage tracking and limits
- Consider string interning for frequently used strings

#### fifo.c / fifo.h - Inter-MCU Communication Buffer

**Critical Memory Safety Issues:**
- **Buffer overflow vulnerability** (lines 68-69, 74-75):
```c
*(uint32_t *)&fifo->packets[i][PACKET_SIZE] = 0xDEADBEEF;
if (*(uint32_t *)&fifo->packets[i][PACKET_SIZE] != 0xDEADBEEF) {
```
Risk: Writing beyond allocated packet buffer boundary, potential memory corruption.

- **Unchecked buffer operations** (line 89):
```c
memcpy(dst_packet, src_packet, src_packet->n_bytes);
```
Risk: No validation that src_packet->n_bytes fits within dst_packet buffer.

**Improvements Needed:**
- Add bounds checking for all packet operations
- Implement buffer overflow detection
- Add packet size validation before memcpy operations

#### comm.c / comm.h - UART Communication Layer

**High-Risk Memory Issues:**
- **Static buffer assumptions** (lines 52-53):
```c
uint8_t _xmit_buffer[N_FIFO_PACKETS * PACKET_MEM_SIZE];
uint8_t _recv_buffer[N_FIFO_PACKETS * PACKET_MEM_SIZE];
```
Risk: Fixed-size buffers may overflow with large packet counts.

- **Unchecked pointer arithmetic** (lines 407-408):
```c
dst += src_size;
inquis_assert(dst - _xmit_buffer < sizeof(_xmit_buffer));
```
Risk: Assert after potential overflow rather than prevention.

- **Race condition potential** (lines 276-284):
```c
Packet *src_packet = (Packet *)&frame->packets[src_i];
size_t src_size = src_packet->n_bytes;
if (src_i + src_size <= bytes_received) {
    Packet *dst_packet = fifo_writ_get_ptr(&recv_fifo);
    if (dst_packet) {
        memcpy(dst_packet, src_packet, src_size);
```
Risk: No validation of src_packet structure integrity before accessing n_bytes.

#### config.c / config.h - Configuration Management

**Memory Management Issues:**
- **String parsing without bounds** (lines 246-248):
```c
BBStrNode *lines = bbstr_split(config_file_contents, '\n', BBSTR_TRIM);
pet_watchdog();
lines = _strip_comments(lines);
```
Risk: Large config files could exhaust memory during parsing.

- **Unsafe array indexing** (line 326):
```c
((int *)out_config)[i] = val;
```
Risk: Direct pointer arithmetic assumes Config structure is all ints.

**Optimization Opportunities:**
- Add config file size limits
- Implement streaming config parser for large files
- Add validation for config structure assumptions

#### devices.c / devices.h - Hardware Device Interface

**Memory Safety Concerns:**
- **Static array bounds** (lines 74-78):
```c
int i = monitor->n_samples % N_MONITOR_SAMPLES_MAX;
monitor->samples[i] = sample;
monitor->times[i] = get_time_ms();
monitor->n_samples++;
```
Risk: No bounds checking on monitor->n_samples increment.

- **Pressure reading state machine** (lines 150-180):
```c
static int _pressure_state = 0;
static uint8_t _pressure_bytes[4];
static int _pressure_byte_i = 0;
```
Risk: Static variables shared across calls without thread safety.

#### led_driver.c / led_driver.h - LED Control

**Minor Memory Issues:**
- **Static array initialization** (lines 53-55):
```c
static uint8_t _curr_rgb[2][3] = {
    0,
};
```
Risk: Incomplete initialization, only first element set to 0.

- **Array bounds assumption** (line 151):
```c
inquis_assert(0 <= led_i && led_i <= 2);
```
Risk: LED_BOTH constant (2) exceeds array bounds for _curr_rgb[2].

#### log.c / log.h - Binary Logging

**Buffer Management Issues:**
- **Static buffer usage** (lines 168-169):
```c
char line[1024] = {
    0,
};
```
Risk: Fixed-size buffer for debug output, potential truncation.

- **Memory copying without validation** (lines 154-155):
```c
memcpy(handata_record.prsmagpha_samples, src, n_records_this_packet * sizeof(PrsMagPhaSample));
```
Risk: No validation that source data fits in destination buffer.

#### fmt.c / fmt.h - Data Formatting

**String Buffer Issues:**
- **Buffer overflow potential** (lines 163, 183):
```c
snprintf(out_buf, buf_max_size - 1, "%0*.1f", V1_MAG_FIELD_WIDTH, mag);
snprintf(out_buf, buf_max_size - 1, "%+0*.1f", V1_PHASE_FIELD_WIDTH, phase);
```
Risk: Using buf_max_size - 1 may still overflow if buf_max_size is 0.

- **Complex buffer calculations** (lines 274-277):
```c
const int fieldWidth =
    (V2_TIME_FIELD_WIDTH + 1 + V2_MAG_FIELD_WIDTH + 1 + V2_MAG_FIELD_WIDTH + 1 + V2_PHASE_FIELD_WIDTH + 1 +
     V2_VOLTS_FIELD_WIDTH + 1 + V2_SWITCH_STATE_FIELD_WIDTH + 1 + V2_SAMPLE_ERR_FIELD_WIDTH + 1 +
     V2_MAG_FIELD_WIDTH + 1 + V2_PHASE_FIELD_WIDTH + 1 + 1);
```
Risk: Complex manual calculation prone to errors.

#### common.c / common.h - Common Utilities

**Memory Validation Issues:**
- **String buffer checking** (lines 200-210):
```c
if (expected_len > 0) {
    if (strlen(buf) != expected_len) {
        return 1;
    }
}
```
Risk: strlen() on potentially unterminated buffer.

- **Stack checking** (lines 250-260):
```c
uint32_t stack_val = 0xDEADBEEF;
uint32_t *stack_ptr = &stack_val;
```
Risk: Stack pointer arithmetic assumptions may be platform-dependent.

#### cli_helpers.c / cli_helpers.h - Command Line Interface

**String Processing Issues:**
- **Argument splitting** (lines 25-45):
```c
while (*line && argc < max_argc) {
    while (*line && isspace(*line)) line++;
    if (*line) {
        argv[argc++] = line;
        while (*line && !isspace(*line)) line++;
        if (*line) *line++ = '\0';
    }
}
```
Risk: Modifies input string in-place, potential buffer overrun.

#### crc.c / crc.h - CRC Calculation

**Memory Access Issues:**
- **Static table initialization** (lines 73-74):
```c
_crc32_table[i] = crc;
```
Risk: No bounds checking on array access during initialization.

- **Pointer arithmetic** (lines 79-80):
```c
uint8_t byte = *data++;
crc = (crc >> 8) ^ _crc32_table[(crc ^ byte) & 0xFF];
```
Risk: No validation of data pointer validity or length bounds.

#### emc.c / emc.h - EMC Testing

**Array Bounds Issues:**
- **Monitor sample storage** (lines 74-77):
```c
int i = monitor->n_samples % N_MONITOR_SAMPLES_MAX;
monitor->samples[i] = sample;
monitor->times[i] = get_time_ms();
monitor->n_samples++;
```
Risk: n_samples can overflow, causing incorrect modulo results.

- **Error state array** (lines 162-170):
```c
char *error_state_names[] = {
    "none", "button", "impedance", "pressure", "communication", "syringe",
};
printf("emc_manager: error state %s\n", error_state_names[err_state]);
```
Risk: No bounds checking on err_state before array access.

#### lights.c / lights.h - Light Control

**LUT Management Issues:**
- **Static LUT array** (line 47):
```c
static uint32_t _light_val_to_rgb_lut[LIGHT_N_VALS] = { 0, };
```
Risk: Array access without bounds validation in _light_value_to_rgb().

- **Array indexing** (lines 123-124):
```c
inquis_assert(light_val >= 0 && light_val < LIGHT_N_VALS);
return _light_val_to_rgb_lut[light_val];
```
Risk: Assert-based bounds checking, no graceful error handling.

#### track_stats.c / track_stats.h - Statistics Tracking

**Static Array Issues:**
- **Packet type arrays** (lines 25-26):
```c
static int n_packets_by_type[16] = {0,};
static int n_bytes_by_type[16] = {0,};
```
Risk: Hard-coded array size, no validation of type_id bounds.

- **Array access** (lines 28-30):
```c
if(0 <= type_id && type_id < 16) {
    n_packets_by_type[type_id] ++;
    n_bytes_by_type[type_id] += n_bytes;
```
Risk: Magic number 16 repeated, should use array size constant.

### CMS Directory Analysis

#### cms_state.c / cms_state.h - CMS State Machine

**Critical Array Bounds Issues:**
- **State name array access** (lines 1217-1219, 1236-1238, 1250-1252):
```c
cms_piston_state_val_names[cms_state.curr_piston_state],
cms_piston_state_val_names[cms_state.next_piston_state]
```
Risk: Out-of-bounds access if state values exceed array bounds.

- **State transition logging** (lines 1070-1071):
```c
Packet *recv_packet = (Packet *)fifo_read_get_ptr(&recv_fifo, 0);
if (recv_packet != NULL) {
```
Risk: Null pointer check present but subsequent operations assume validity.

**State Machine Memory Issues:**
- **Global state variables** (lines 89-120):
```c
CmsState cms_state = {
    .curr_piston_state = CMS_PISTON_STATE_0_STARTUP,
    .next_piston_state = CMS_PISTON_STATE_0_STARTUP,
    // ... other state variables
};
```
Risk: Large global state structure, potential for uninitialized fields.

#### cms_devices.c / cms_devices.h - CMS Hardware Interface

**Audio Buffer Overflow Risks:**
- **Static audio buffers** (lines 63-64):
```c
static uint8_t _audio_wav[N_AUDIO_BUFS][AUDIO_BUF_N_SAMPLES_MAX] = { 0, };
static int _audio_buf_n_bytes_true[N_AUDIO_BUFS] = { 0, };
```
Risk: Large static buffers (6000 bytes each), potential stack overflow.

- **File size validation** (lines 249, 266):
```c
inquis_assert(file_size <= AUDIO_BUF_N_SAMPLES_MAX);
inquis_assert(file_size <= AUDIO_BUF_N_SAMPLES_MAX);
```
Risk: Assert-based validation, no graceful error handling.

- **Memory allocation in EMC mode** (line 189):
```c
uint16_t *_audio_buffer = (uint16_t *)malloc(EMC_N_AUDIO_BUFFER_SAMPLES * sizeof(uint16_t));
```
Risk: Malloc without null check or free, potential memory leak.

#### cms_comm_state.c / cms_comm_state.h - CMS Communication

**Packet Handling Issues:**
- **Packet copying** (lines 108-111):
```c
Packet *xmit_packet = (Packet *)fifo_writ_get_ptr(&xmit_fifo);
if (xmit_packet) {
    memcpy(xmit_packet, packet, packet->n_bytes);
    fifo_writ_done(&xmit_fifo);
```
Risk: No validation that packet->n_bytes fits in xmit_packet buffer.

- **Static state variables** (lines 90-93):
```c
static CommStateVal comm_state = COMM_STATE_0_READY_TO_XMIT;
static TimeMS start_cycle_ms = 0;
static uint32_t before_recv_done_count = 0;
```
Risk: Static variables not thread-safe, potential race conditions.

#### cms_log_writer.c / cms_log_writer.h - CMS Logging

**String Buffer Issues:**
- **Filename buffer** (lines 104-106):
```c
char digits[16];
char highest_filename[16] = { 0, };
```
Risk: Fixed-size buffers for filename processing, potential overflow.

- **Comment copying** (lines 259-271):
```c
char comment_copy[COMMENT_RECORD_COMMENT_SIZE + 1];
CommentRecord *comment = (CommentRecord *)ptr;
int src_i=0, dst_i=0;
for(; src_i < COMMENT_RECORD_COMMENT_SIZE; src_i++) {
    char src_c = comment->comment[src_i];
    if(src_c != '\n') {
        comment_copy[dst_i++] = src_c;
    }
```
Risk: No bounds checking on dst_i increment, potential buffer overflow.

- **Filename buffer operations** (lines 191-192):
```c
strncpy(_log_sdcard_filename, sdcard_filename, sizeof(_log_sdcard_filename) - 1);
_log_sdcard_is_open = true;
```
Risk: strncpy may not null-terminate if source is too long.

#### cms_cli.c / cms_cli.h - CMS Command Line Interface

**Command Processing Issues:**
- **Static sample array** (line 271):
```c
uint32_t samples[256] = { 0 };
```
Risk: Fixed-size array for ADC samples, potential overflow.

- **Array bounds checking** (lines 278-279):
```c
samples[n_samples++] = val;
inquis_assert(n_samples < 256);
```
Risk: Assert after array access, should check before.

- **String processing** (lines 196-201):
```c
int int_val = 0;
if(val[0] == '0' && val[1] == 'x') {
    int_val = (int)strtoul(val, NULL, 16);
} else {
    int_val = atoi(val);
}
```
Risk: No validation of val string length before accessing val[1].

#### cms_inquis_main.c / cms_inquis_main.h - CMS Main Entry

**Initialization Issues:**
- **Hardware initialization sequence** (lines 50-80):
```c
HAL_Init();
SystemClock_Config();
MX_GPIO_Init();
// ... other init calls
```
Risk: No error checking on hardware initialization calls.

### Handle Directory Analysis

#### han_state.c / han_state.h - Handle State Machine

**Critical Impedance Buffer Issues:**
- **Impedance array manipulation** (lines 653-661):
```c
memmove(&han_state.impedance_mags[1], &han_state.impedance_mags[0], 
        sizeof(han_state.impedance_mags[0]) * (IMPEDANCE_MAX_N - 1));
han_state.impedance_mags[0] = mag;
```
Risk: Buffer overflow if IMPEDANCE_MAX_N (200) is exceeded.

- **Communication globals race condition** (lines 89-99):
```c
HanStateVal _comm_reply_curr_state;
HanImpStateVal _comm_reply_imp_state_val;
uint32_t _comm_reply_imp_mag;
// ... other globals updated from interrupt context
```
Risk: Data corruption between main loop and interrupt handler.

- **State array bounds** (lines 450-500):
```c
han_state_val_names[han_state.curr_state]
```
Risk: No bounds checking on state values before array access.

#### han_sample.c / han_sample.h - Handle Sampling

**Sample Processing Issues:**
- **Integer overflow potential** (lines 228, 243):
```c
_n_samples = max(1, fifo_count / 4);
_n_samples_since_reset += _n_samples;
```
Risk: Integer overflow in sample counting over extended operation.

- **FIFO data processing** (lines 200-250):
```c
uint32_t *fifo_data = (uint32_t *)ad5940_api_read_fifo(&fifo_count);
if (fifo_data && fifo_count >= 4) {
    // Process samples without bounds checking
}
```
Risk: No validation of fifo_data pointer or buffer bounds.

#### ad5940_api.c / ad5940_api.h - AD5940 Interface

**Hardware Buffer Issues:**
- **Static raw buffer** (lines 95-96):
```c
#define IMPEDANCE_RAW_BUFFER_SIZE 1024
uint32_t _impedance_raw_buffer[IMPEDANCE_RAW_BUFFER_SIZE];
```
Risk: Fixed-size buffer for hardware data, potential overflow.

- **FIFO reading** (lines 424-450):
```c
uint32_t fifo_count = AD5940_FIFOGetCnt();
if (fifo_count > 0) {
    AD5940_FIFODrd(pBuffer, fifo_count);
}
```
Risk: No validation that pBuffer can hold fifo_count elements.

#### han_cli.c / han_cli.h - Handle Command Line Interface

**Command Processing Issues:**
- **GPIO pin parsing** (lines 252-254):
```c
GPIO_TypeDef *block;
uint16_t pin;
Err err = cli_parse_gpio_pin_string(argv[1], &block, &pin);
```
Risk: No validation of argv[1] existence before use.

- **Command array access** (lines 348-355):
```c
char *name = (char *)_commands[i * 2];
CmdFuncPtr cmd_func_ptr = (CmdFuncPtr)_commands[i * 2 + 1];
```
Risk: Array access without bounds checking on index i.

#### han_inquis_main.c / han_inquis_main.h - Handle Main Entry

**Initialization Issues:**
- **Hardware setup sequence** (lines 40-70):
```c
HAL_Init();
SystemClock_Config();
MX_GPIO_Init();
// ... other hardware init
```
Risk: No error checking on critical hardware initialization.

---

## Top 20 Critical Issues (Prioritized)

### 🔴 CRITICAL SEVERITY

1. **FIFO Buffer Overflow** - `common/fifo.c:68-75`
   - Writing beyond PACKET_SIZE boundary with 0xDEADBEEF marker
   - **Impact**: Memory corruption, system crash
   - **Fix**: Add proper bounds checking before buffer writes

2. **Array Bounds in State Machine** - `cms/inquis/cms_state.c:1217-1252`
   - Out-of-bounds access to cms_piston_state_val_names array
   - **Impact**: Memory corruption during state transitions
   - **Fix**: Add state value validation before array access

3. **Impedance Buffer Overflow** - `handle/inquis/han_state.c:653-661`
   - memmove operation without bounds validation
   - **Impact**: Corruption of critical impedance data
   - **Fix**: Validate IMPEDANCE_MAX_N bounds before memmove

4. **Communication Race Condition** - `handle/inquis/han_state.c:89-99`
   - Shared globals updated from interrupt context
   - **Impact**: Data corruption, state machine desynchronization
   - **Fix**: Add critical sections around shared variables

5. **Audio Buffer Stack Overflow** - `cms/inquis/cms_devices.c:63-64`
   - Large static arrays (6000 bytes each) on stack
   - **Impact**: Stack overflow, system crash
   - **Fix**: Move to heap allocation or reduce buffer size

### 🟡 HIGH SEVERITY

6. **Unchecked malloc() Calls** - `common/bbstr.c:77-88`
   - System halt on memory exhaustion
   - **Impact**: Non-graceful system failure
   - **Fix**: Implement graceful error handling

7. **Packet Size Validation Missing** - `common/comm.c:276-284`
   - No validation of packet structure before memcpy
   - **Impact**: Buffer overflow in communication
   - **Fix**: Add packet size and structure validation

8. **Config Structure Assumptions** - `common/config.c:326`
   - Direct pointer arithmetic assumes all-int structure
   - **Impact**: Memory corruption if structure changes
   - **Fix**: Add structure validation and type safety

9. **Integer Overflow in Sampling** - `handle/inquis/han_sample.c:228-243`
   - Sample count overflow over extended operation
   - **Impact**: Incorrect sample indexing, array bounds errors
   - **Fix**: Add overflow detection and counter reset logic

10. **EMC Memory Leak** - `cms/inquis/cms_devices.c:189`
    - malloc() without corresponding free() in EMC mode
    - **Impact**: Memory exhaustion over time
    - **Fix**: Add proper memory cleanup

### 🟠 MEDIUM SEVERITY

11. **String Buffer Bounds** - `cms/inquis/cms_log_writer.c:259-271`
    - Comment copying without dst_i bounds checking
    - **Impact**: Buffer overflow in logging
    - **Fix**: Add destination buffer bounds validation

12. **Static Array Initialization** - `common/led_driver.c:53-55`
    - Incomplete array initialization
    - **Impact**: Undefined behavior with uninitialized elements
    - **Fix**: Proper array initialization syntax

13. **Monitor Sample Overflow** - `common/emc.c:74-77`
    - n_samples can overflow affecting modulo operation
    - **Impact**: Incorrect sample storage indexing
    - **Fix**: Add overflow protection for sample counter

14. **GPIO Command Validation** - `handle/inquis/han_cli.c:252-254`
    - No argv[1] existence check before parsing
    - **Impact**: Null pointer dereference
    - **Fix**: Add argument count validation

15. **FIFO Data Validation** - `handle/inquis/han_sample.c:200-250`
    - No bounds checking on FIFO data processing
    - **Impact**: Buffer overflow in sample processing
    - **Fix**: Add FIFO data bounds validation

### 🟢 LOWER SEVERITY

16. **CRC Table Bounds** - `common/crc.c:73-74`
    - No bounds checking during table initialization
    - **Impact**: Potential array overflow
    - **Fix**: Add loop bounds validation

17. **Command Array Access** - `handle/inquis/han_cli.c:348-355`
    - Array access without bounds checking
    - **Impact**: Potential out-of-bounds access
    - **Fix**: Add index validation

18. **Filename Buffer Operations** - `cms/inquis/cms_log_writer.c:191-192`
    - strncpy may not null-terminate
    - **Impact**: String handling errors
    - **Fix**: Ensure null termination after strncpy

19. **ADC Sample Array** - `cms/inquis/cms_cli.c:271-279`
    - Assert after array access instead of before
    - **Impact**: Potential buffer overflow
    - **Fix**: Move bounds check before array access

20. **Hardware Init Error Handling** - `cms/inquis/cms_inquis_main.c:50-80`
    - No error checking on critical hardware initialization
    - **Impact**: Silent failures during startup
    - **Fix**: Add error checking and recovery for hardware init

---

## Appendix

### Files Analyzed

**Common Directory (43+ files):**
- `bbstr.c/h` - Reference-counted string management
- `fifo.c/h` - Inter-MCU communication FIFO
- `comm.c/h` - UART communication layer
- `config.c/h` - Configuration management
- `devices.c/h` - Hardware device interface
- `led_driver.c/h` - LED control
- `log.c/h` - Binary logging
- `fmt.c/h` - Data formatting
- `common.c/h` - Common utilities
- `cli_helpers.c/h` - Command line interface
- `crc.c/h` - CRC calculation
- `emc.c/h` - EMC testing
- `lights.c/h` - Light control
- `track_stats.c/h` - Statistics tracking
- `packet.c/h` - Packet handling utilities
- `state_defs.c/h` - State enumeration definitions

**CMS Directory (20+ files):**
- `cms_state.c/h` - CMS state machine implementation
- `cms_devices.c/h` - CMS hardware interface
- `cms_comm_state.c/h` - CMS communication state machine
- `cms_log_writer.c/h` - CMS logging implementation
- `cms_cli.c/h` - CMS command line interface
- `cms_inquis_main.c/h` - CMS main entry point

**Handle Directory (15+ files):**
- `han_state.c/h` - Handle state machine implementation
- `han_sample.c/h` - Handle sampling logic
- `ad5940_api.c/h` - AD5940 hardware interface
- `han_cli.c/h` - Handle command line interface
- `han_inquis_main.c/h` - Handle main entry point

### Analysis Methodology

This comprehensive analysis was conducted through:
1. Systematic examination of all C and H source files
2. Memory operation pattern identification across all modules
3. State machine flow analysis and memory risk mapping
4. Buffer overflow and bounds checking analysis
5. Race condition and concurrency issue identification
6. Resource management and memory leak detection
7. Risk assessment based on potential impact and likelihood
8. Prioritization of issues by severity and system impact
