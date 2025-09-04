# Inquis Gen 3.0 State Machine Analysis Report

## Executive Summary

The Inquis Gen 3.0 system is a sophisticated medical device for clot management that employs multiple interconnected state machines across two STM32L471RET microcontrollers. The system consists of a CMS (Clot Management System) as the master controller and a Handle unit for impedance sensing, with shared common code defining state enumerations and communication protocols. This report provides a comprehensive analysis of all state machines governing the system's operation.

## System Architecture Overview

The system is organized into three main components:

- **CMS (Clot Management System)**: The base device serving as the logic master for user-visible state, housing an SD card for data logging and managing power to the handle
- **Handle**: Connected to CMS via bidirectional data and power connection, responsible for measuring impedance via AD5940 sensor and running impedance-based state detection
- **Common**: Shared code between both systems containing state definitions, communication protocols, and lighting control

## CMS State Machines

The CMS implements four distinct but interconnected state machines that coordinate the overall system behavior:

### 1. Piston Control State Machine

**Purpose**: Controls the syringe mechanism for aspiration and injection cycles
**Implementation**: `_update_piston_state()` in `cms_state.c`
**States**: 16 total states (PISTON_STATE_00_START through PISTON_STATE_92_SYSTEM_ERROR)

**Key State Flow**:
- **Startup Sequence**: START → POST → AWAITING_STOP_AT_FRONT → AWAITING_ASPIRATION
- **Aspiration Cycle**: AWAITING_ASPIRATION → START_MOTION_BACKWARD → ACTIVE_MOTION_BACKWARD → CONFIRMING_STOP → VACUUM_AT_BACK_STOP → VACUUM_HOLDING_AT_BACK
- **Return Cycle**: VACUUM_HOLDING_AT_BACK → START_MOTION_FORWARDS → ACTIVE_MOTION_FORWARDS → AWAITING_STOP_AT_FRONT

**Critical Parameters**:
- TB1 (400ms): Minimum time for backward motion velocity measurement
- TB3 (500ms): Stop confirmation time
- TB4 (500ms): Vacuum establishment time
- Tstack (7000ms): Vacuum stack cycle timeout
- Position thresholds (v1-v8): Define syringe position ranges for 15cc, 10cc, and 5cc shot sizes

**Safety Features**:
- Lid removal detection prevents valve operation
- CO2 depletion detection (states 81-83)
- System error handling with permanent error state (92)
- Pressure monitoring for automatic return cycles

#### Piston Control State Transition Table

| State Code | State Name | Entry Criteria + Entry-From State | Exit Criteria + Exit-To State |
|------------|------------|-----------------------------------|--------------------------------|
| 00 | START | System initialization | Automatic → POST (10) |
| 10 | POST | From START (00) | POST success → AWAITING_STOP_AT_FRONT (30)<br>POST failure → START_SYSTEM_ERROR (91) |
| 21 | START_MOTION_FORWARDS | From VACUUM_HOLDING_AT_BACK (72) when pressure > Ls OR button released after Tup OR new button press when not in 6000 state | Lid closed → ACTIVE_MOTION_FORWARDS (22)<br>Lid open → REMAIN |
| 22 | ACTIVE_MOTION_FORWARDS | From START_MOTION_FORWARDS (21) when lid closed | Elapsed > TR → AWAITING_STOP_AT_FRONT (30)<br>Else → REMAIN |
| 30 | AWAITING_STOP_AT_FRONT | From POST (10), ACTIVE_MOTION_FORWARDS (22) | Position ≥ v7 → AWAITING_ASPIRATION (40)<br>Else → REMAIN |
| 40 | AWAITING_ASPIRATION | From AWAITING_STOP_AT_FRONT (30) | Lid closed AND (button pressed OR vacuum stack timeout) → START_MOTION_BACKWARD (51)<br>Else → REMAIN |
| 51 | START_MOTION_BACKWARD | From AWAITING_ASPIRATION (40), OUT_OF_CO2 (83) | Lid closed → ACTIVE_MOTION_BACKWARD (52)<br>Lid open → REMAIN |
| 52 | ACTIVE_MOTION_BACKWARD | From START_MOTION_BACKWARD (51) when lid closed | Elapsed > TB1 AND position ≤ v6 → CONFIRMING_STOP (60)<br>Elapsed > TB1 AND position > v6 → START_OUT_OF_CO2 (81)<br>Else → REMAIN |
| 60 | CONFIRMING_STOP | From ACTIVE_MOTION_BACKWARD (52) when position ≤ v6 | Elapsed > TB3 AND position in valid range → VACUUM_AT_BACK_STOP (71)<br>Elapsed > TB3 AND position invalid → START_SYSTEM_ERROR (91)<br>Else → REMAIN |
| 71 | VACUUM_AT_BACK_STOP | From CONFIRMING_STOP (60) when position valid | Elapsed > TB4 → VACUUM_HOLDING_AT_BACK (72)<br>Else → REMAIN |
| 72 | VACUUM_HOLDING_AT_BACK | From VACUUM_AT_BACK_STOP (71) | Lid open → REMAIN<br>Pressure > Ls → START_MOTION_FORWARDS (21)<br>Button released AND elapsed Tup AND elapsed 6000 timer → START_MOTION_FORWARDS (21)<br>New button press AND not in 6000 → START_MOTION_FORWARDS (21)<br>Else → REMAIN |
| 81 | START_OUT_OF_CO2 | From ACTIVE_MOTION_BACKWARD (52) when position > v6 | Lid closed → OUT_OF_CO2_AWAIT_BUTTON_UP (82)<br>Lid open → REMAIN |
| 82 | OUT_OF_CO2_AWAIT_BUTTON_UP | From START_OUT_OF_CO2 (81) when lid closed | Button not pressed → OUT_OF_CO2 (83)<br>Else → REMAIN |
| 83 | OUT_OF_CO2 | From OUT_OF_CO2_AWAIT_BUTTON_UP (82) | Lid closed AND button pressed → START_MOTION_BACKWARD (51)<br>Else → REMAIN |
| 91 | START_SYSTEM_ERROR | From POST (10) failure, CONFIRMING_STOP (60) invalid position, timeout/power failure | Lid closed → SYSTEM_ERROR (92)<br>Lid open → REMAIN |
| 92 | SYSTEM_ERROR | From START_SYSTEM_ERROR (91) when lid closed | Permanent error state → REMAIN |

### 2. LED Control State Machine

**Purpose**: Manages visual feedback through LED colors and patterns
**Implementation**: `_update_led_state()` in `cms_state.c`
**States**: 16 total states (LED_STATE_000_START through LED_STATE_900_VACUUM_STATE_CYCLE)

**Key State Flow**:
- **Initialization**: START → POWER_ON → START_HANDLE_CONNECT → AWAIT_HANDLE_POWER → AWAIT_HANDLE_CONNECT → START_HANDLE_CONFIG → AWAIT_HANDLE_CONFIG → START_MIRROR_HANDLE → MIRROR_HANDLE
- **Operational States**: MIRROR_HANDLE ↔ CLOT_START/CLOT ↔ CLOGGED ↔ CLOGGED_WITH_CLOT_AND_TIP ↔ VACUUM_STATE_CYCLE

**LED Color Mapping**:
- WHITE: Connecting, handle error, system ready
- GREEN: Saline/blood detection, fluid injection
- ORANGE: Clot detection, clogged conditions
- BLUE: Wall latch detection
- FLASHING ORANGE: System clogged states
- OFF: Error conditions

**State Transition Logic**:
- Communication timeout triggers reconnection sequence
- Handle impedance states drive color changes
- Pressure conditions determine clogged states
- Clot detection has priority with minimum display time (J=1000ms)

#### LED Control State Transition Table

| State Code | State Name | Entry Criteria + Entry-From State | Exit Criteria + Exit-To State |
|------------|------------|-----------------------------------|--------------------------------|
| 000 | START | System initialization | Automatic → POWER_ON (100) |
| 100 | POWER_ON | From START (000) | Elapsed > 100ms AND system ready → START_HANDLE_CONNECT (301)<br>Elapsed > 100ms AND system not ready → CMS_ERROR (200)<br>Else → REMAIN |
| 200 | CMS_ERROR | From POWER_ON (100) when system not ready | Permanent error state → REMAIN |
| 301 | START_HANDLE_CONNECT | From POWER_ON (100), AWAIT_HANDLE_CONFIG (305) on config failure/timeout, communication timeout from any state | Clear handle state, power off → AWAIT_HANDLE_POWER (302) |
| 302 | AWAIT_HANDLE_POWER | From START_HANDLE_CONNECT (301) | Elapsed > Trst → AWAIT_HANDLE_CONNECT (303)<br>Else → REMAIN |
| 303 | AWAIT_HANDLE_CONNECT | From AWAIT_HANDLE_POWER (302) | Handle reply received → START_HANDLE_CONFIG (304)<br>Else → REMAIN |
| 304 | START_HANDLE_CONFIG | From AWAIT_HANDLE_CONNECT (303) | Send config → AWAIT_HANDLE_CONFIG (305) |
| 305 | AWAIT_HANDLE_CONFIG | From START_HANDLE_CONFIG (304) | Config confirmed (1) → START_MIRROR_HANDLE (401)<br>Config failed (2) → START_HANDLE_CONNECT (301)<br>Communication timeout → START_HANDLE_CONNECT (301)<br>Else → REMAIN |
| 401 | START_MIRROR_HANDLE | From AWAIT_HANDLE_CONFIG (305), CLOT (502) after timer, CLOGGED (600), HANDLE_ERROR (700) | Reset clot timers → MIRROR_HANDLE (402) |
| 402 | MIRROR_HANDLE | From START_MIRROR_HANDLE (401) | Handle error OR short/open circuit → HANDLE_ERROR (700)<br>Clot detected OR new clot in 5000 → CLOT_START (501)<br>CMS pressure low AND elapsed AND not in 6000 → CLOGGED (600)<br>Communication timeout → START_HANDLE_CONNECT (301)<br>Else → REMAIN |
| 501 | CLOT_START | From MIRROR_HANDLE (402), CLOT (502) when back in clot | CMS pressure low elapsed → CLOGGED_WITH_CLOT_AND_TIP (800)<br>Else → CLOT (502) |
| 502 | CLOT | From CLOT_START (501) | Back in clot before timer → CLOT_START (501)<br>Timer elapsed AND in 6000 → START_MIRROR_HANDLE (401)<br>Timer elapsed AND pressure low → CLOGGED (600)<br>Timer elapsed → START_MIRROR_HANDLE (401)<br>Else → REMAIN |
| 600 | CLOGGED | From MIRROR_HANDLE (402), CLOT (502), VACUUM_STATE_CYCLE (900) | Pressure not low AND handle pressure high → START_MIRROR_HANDLE (401)<br>Impedance state 3 → CLOGGED_WITH_CLOT_AND_TIP (800)<br>Vacuum stack active → VACUUM_STATE_CYCLE (900)<br>Else → REMAIN |
| 700 | HANDLE_ERROR | From MIRROR_HANDLE (402), invalid state (default) | Handle state not error AND impedance not short/open → START_MIRROR_HANDLE (401)<br>Else → REMAIN |
| 800 | CLOGGED_WITH_CLOT_AND_TIP | From CLOT_START (501), CLOGGED (600) | Not impedance state 3 → CLOGGED (600)<br>CMS pressure > Ls AND handle pressure > L → CLOT_START (501)<br>Vacuum stack active → VACUUM_STATE_CYCLE (900)<br>Else → REMAIN |
| 900 | VACUUM_STATE_CYCLE | From CLOGGED (600), CLOGGED_WITH_CLOT_AND_TIP (800) | Vacuum stack timer expired OR timer = 0 → CLOGGED (600)<br>Else → REMAIN |

### 3. Audio State Machine

**Purpose**: Provides auditory feedback for clot detection and system status
**Implementation**: `_update_audio_state()` in `cms_state.c`
**States**: 7 total states (AUDIO_STATE_00000_START through AUDIO_STATE_40002_BLEED_PATH_SOUND)

**Key State Flow**:
- START → LOAD_SOUNDS → SILENCE → [CLOT_SOUND_START → CLOT_SOUND] or [BLEED_PATH_SOUND_START → BLEED_PATH_SOUND]

**Audio Triggers**:
- **Clot Sound (Audio0)**: Triggered by blood-to-clot transitions or new clot detection during aspiration
- **Bleed Path Sound (Audio1)**: Triggered when piston is in vacuum hold state (72) and syringe pressure exceeds threshold for 5000ms
- **Audio Parameters**: 11025 sps sample rate, 8-bit mono WAV files, 2000ms blanking period

#### Audio State Transition Table

| State Code | State Name | Entry Criteria + Entry-From State | Exit Criteria + Exit-To State |
|------------|------------|-----------------------------------|--------------------------------|
| 00000 | START | System initialization | Automatic → LOAD_SOUNDS (10000) |
| 10000 | LOAD_SOUNDS | From START (00000) | Load audio files → SILENCE (20000) |
| 20000 | SILENCE | From LOAD_SOUNDS (10000), CLOT_SOUND (30002) after blanking, BLEED_PATH_SOUND (40002) when not in vacuum hold | Piston in vacuum hold (72) AND pressure > Ls for Tbeep → BLEED_PATH_SOUND_START (40001)<br>Blood-to-clot OR aspiration with new clot → CLOT_SOUND_START (30001)<br>Else → REMAIN |
| 30001 | CLOT_SOUND_START | From SILENCE (20000), CLOT_SOUND (30002) on new trigger | Extend timer if active, else play clot sound → CLOT_SOUND (30002) |
| 30002 | CLOT_SOUND | From CLOT_SOUND_START (30001) | New clot trigger → CLOT_SOUND_START (30001)<br>Elapsed > TaudioBlank → SILENCE (20000)<br>Else → REMAIN |
| 40001 | BLEED_PATH_SOUND_START | From SILENCE (20000) when conditions met | Start bleed path sound → BLEED_PATH_SOUND (40002) |
| 40002 | BLEED_PATH_SOUND | From BLEED_PATH_SOUND_START (40001) | Piston not in vacuum hold (72) → SILENCE (20000)<br>Else → REMAIN |

### 4. Light Value State Machine

**Purpose**: Translates LED states into specific RGB values and flashing patterns
**Implementation**: `lights.c` in common code
**States**: 17 light values (LIGHT_OFF through LIGHT_TEST_RIG_DISCONNECTED)

**Features**:
- Configurable RGB values loaded from config file
- Flashing support with configurable half-period
- Separate CMS and Handle color configurations
- Override capabilities for lid removal and CO2 depletion

#### Light Value State Transition Table

| State Code | State Name | Entry Criteria + Entry-From State | Exit Criteria + Exit-To State |
|------------|------------|-----------------------------------|--------------------------------|
| 0 | OFF | System off or error conditions | System startup or recovery |
| 1 | CONNECTING | LED states 000, 100, 301-305 (connection sequence) | Connection established or error |
| 2 | IMP_STATE_2_SALINE_BLOOD | Handle impedance state 2 (100-1800Ω) in MIRROR_HANDLE | Impedance change or state transition |
| 3 | IMP_STATE_3_CLOT | Handle impedance state 3 (1800-12000Ω), CLOT states | Impedance change or state transition |
| 4 | IMP_STATE_4_AIR | Handle impedance state 4 (12000-100000Ω) in MIRROR_HANDLE | Impedance change or state transition |
| 5 | FLUID_INJECTION | Handle state 4000 (fluid injection) | Handle state change |
| 6 | WALL_LATCH | Handle states 6001-6002 (wall latch), minimum Tblue time | Timer expiry or state change |
| 7 | CLOGGED | LED state 600 (clogged) | Pressure recovery or clot detection |
| 8 | CMS_ERROR | LED state 200 (CMS error), piston state 92 override | System recovery (rare) |
| 9 | HANDLE_ERROR | LED state 700 (handle error) | Handle recovery |
| 10 | LID_REMOVED | Lid switch open (override condition) | Lid closed |
| 11 | OUT_OF_CO2 | Piston CO2 depletion states 81-83 (override) | CO2 replenished |
| 12 | TEST_RIG_CONNECTED | Test rig mode active | Test mode exit |
| 13 | TEST_RIG_DISCONNECTED | Test rig disconnected | Test rig reconnection |
| 14 | REMAIN | Maintain current light state | Next state update cycle |
| 15 | UNKNOWN_15 | Reserved/unused state | State assignment |
| 16 | UNKNOWN_16 | Reserved/unused state | State assignment |

## Handle State Machine

The Handle implements a single comprehensive state machine focused on impedance-based clot detection:

**Purpose**: Impedance monitoring and clot state detection
**Implementation**: `_update_state()` in `han_state.c`
**States**: 11 total states (HAN_STATE_0000_START through HAN_STATE_6002_WALL_LATCH_DELAY)

### Impedance Range Detection

The system uses five impedance ranges for material classification:
- **Range 1 (0-100Ω)**: Short circuit (error condition)
- **Range 2 (100-1800Ω)**: Saline, blood, wall touch
- **Range 3 (1800-12000Ω)**: Clot material
- **Range 4 (12000-100000Ω)**: Air
- **Range 5 (100000+Ω)**: Open circuit

### Key State Flow

**Initialization**: START → CONNECT → START_MONITOR_THRESHOLDS → MONITOR_THRESHOLDS

**Operational Cycle**:
- **MONITOR_THRESHOLDS**: Continuous impedance and pressure monitoring
- **FLUID_INJECTION**: Triggered by Range2 impedance + pressure conditions
- **START_ASPIRATION**: Triggered by pressure drop detection
- **ASPIRATION_EVAL_DATA_COLLECTION**: Collects P+B samples (165 total)
- **ASPIRATION_EVAL_ANALYSIS**: Analyzes collected data for clot and wall latch conditions
- **WALL_LATCH**: Detected when pressure remains low and impedance in specific range
- **WALL_LATCH_DELAY**: 1000ms minimum latch time before exit conditions

### Critical Algorithms

**Clot Detection**: Requires X consecutive data points (X=2) in Range3 within the P+B sample dataset

**Wall Latch Detection**: Two conditions must be met:
1. Filtered pressure < L2 (200 mmHg) at end of B samples
2. Impedance in range Q to R (1100-2500Ω) at end of data

**Pressure Drop Detection**: 100 mmHg drop over 10 samples triggers aspiration evaluation

#### Handle State Transition Table

| State Code | State Name | Entry Criteria + Entry-From State | Exit Criteria + Exit-To State |
|------------|------------|-----------------------------------|--------------------------------|
| 0000 | START | System initialization, communication timeout recovery | Set start time → CONNECT (1000) |
| 1000 | CONNECT | From START (0000) | Elapsed > 100ms AND power OK AND pressure > 0 AND sample_i > 50 AND has_config → START_MONITOR_THRESHOLDS (3001)<br>Elapsed ≤ 100ms → clear button state, REMAIN<br>Else → REMAIN |
| 2000 | ERROR | From any state on critical error (default case) | Permanent error state → REMAIN |
| 3001 | START_MONITOR_THRESHOLDS | From CONNECT (1000), FLUID_INJECTION (4000), ASPIRATION_EVAL_ANALYSIS (5003), WALL_LATCH_DELAY (6002) | Clear vacuum flag → MONITOR_THRESHOLDS (3002) |
| 3002 | MONITOR_THRESHOLDS | From START_MONITOR_THRESHOLDS (3001) | Impedance state 2 AND pressure ≥ K AND elapsed > D → FLUID_INJECTION (4000)<br>Pressure < L AND pressure drop > Pdrop → START_ASPIRATION (5001)<br>Else → REMAIN |
| 4000 | FLUID_INJECTION | From MONITOR_THRESHOLDS (3002) when saline/blood + high pressure | Pressure < K AND elapsed > A → START_MONITOR_THRESHOLDS (3001)<br>Else → REMAIN |
| 5001 | START_ASPIRATION | From MONITOR_THRESHOLDS (3002) on pressure drop | Sample_i < P → START_MONITOR_THRESHOLDS (3001)<br>Else → ASPIRATION_EVAL_DATA_COLLECTION (5002) |
| 5002 | ASPIRATION_EVAL_DATA_COLLECTION | From START_ASPIRATION (5001) when sufficient data | Sample_i > aspirate_stop_sample_i → ASPIRATION_EVAL_ANALYSIS (5003)<br>Else → REMAIN |
| 5003 | ASPIRATION_EVAL_ANALYSIS | From ASPIRATION_EVAL_DATA_COLLECTION (5002) | Pressure < L2 AND impedance in [Q,R] → WALL_LATCH (6001)<br>Else → START_MONITOR_THRESHOLDS (3001) |
| 6001 | WALL_LATCH | From ASPIRATION_EVAL_ANALYSIS (5003) when wall latch detected | Set disengage timer → WALL_LATCH_DELAY (6002) |
| 6002 | WALL_LATCH_DELAY | From WALL_LATCH (6001) | Elapsed > W AND (pressure > L + impedance state 2 OR impedance > N OR impedance < Q) → START_MONITOR_THRESHOLDS (3001)<br>Else → REMAIN |

## Common Code State Definitions

The common code provides centralized state management through several key files:

### State Definition Files (`state_defs.h/c`)

**Enumerations Defined**:
- `PistonStateVal`: 16 piston control states
- `LedStateVal`: 16 LED control states  
- `AudioStateVal`: 7 audio states
- `HanStateVal`: 11 handle states
- `HanImpStateVal`: 6 impedance classification states
- `LightVal`: 17 light value definitions

**String Tables**: Each enumeration has corresponding name and abbreviation string arrays for debugging and logging

### Communication Protocol

**Packet Types**:
- `HandleStatusPacket`: Handle → CMS status updates
- `UpdateConfigPacket`: CMS → Handle configuration
- `UpdateHandlePacket`: CMS → Handle LED commands
- `SamplesPacket`: Handle → CMS impedance data logging

**Synchronization**: Time synchronization between CMS and Handle using CMS timestamps

## Lights State Machine (Optional Analysis)

The lights system operates as a translation layer between logical states and physical LED output:

### Implementation Details

**Configuration Loading**: RGB values loaded from config file with separate CMS/Handle sections

**Flashing Logic**: 
- Flash bit encoded in LSB of RGB value
- Configurable half-period timing
- Synchronized across CMS and Handle units

**Priority System**:
- Override conditions (lid removal, CO2 depletion) take highest priority
- State-driven colors have normal priority
- Default/remain states maintain current output

**Color Mapping Examples**:
- Clot detection: Orange (0xFF8000)
- Wall latch: Blue (0x0000FF)
- System error: White (0xFFFFFF)
- Connecting: Flashing green (0x00FF01 - note LSB=1 for flash)

#### Lights Control State Transition Table

| Light Code | Light Name | Entry Criteria + Entry-From State | Exit Criteria + Exit-To State |
|------------|------------|-----------------------------------|--------------------------------|
| 0 | OFF | System shutdown, critical errors | System power-on or recovery |
| 1 | CONNECTING | LED connection states (000,100,301-305), flashing green | Connection established or timeout |
| 2 | IMP_STATE_2_SALINE_BLOOD | Handle impedance 100-1800Ω in MIRROR_HANDLE, green | Impedance range change |
| 3 | IMP_STATE_3_CLOT | Handle impedance 1800-12000Ω, CLOT states, orange | Impedance range change or clot timer |
| 4 | IMP_STATE_4_AIR | Handle impedance 12000-100000Ω in MIRROR_HANDLE, white | Impedance range change |
| 5 | FLUID_INJECTION | Handle state 4000, green | Handle state transition |
| 6 | WALL_LATCH | Handle states 6001-6002, blue, minimum Tblue display | Timer expiry or handle state change |
| 7 | CLOGGED | LED state 600, flashing orange | Pressure recovery or impedance change |
| 8 | CMS_ERROR | LED state 200, piston state 92 override, white | System recovery |
| 9 | HANDLE_ERROR | LED state 700, handle errors, white | Handle error resolution |
| 10 | LID_REMOVED | Lid switch open (highest priority override), red | Lid closed |
| 11 | OUT_OF_CO2 | Piston states 81-83 (high priority override), yellow | CO2 system recovery |
| 12 | TEST_RIG_CONNECTED | Test mode active, specific test color | Test mode exit |
| 13 | TEST_RIG_DISCONNECTED | Test rig disconnected, different test color | Test rig reconnection |
| 14 | REMAIN | Maintain current light output | Next update cycle |
| 15-16 | UNKNOWN | Reserved states for future use | Future implementation |

## State Machine Interactions and Coordination

### CMS Internal Coordination

The four CMS state machines operate in parallel with specific interaction patterns:

**Piston → LED**: Piston state 92 (system error) forces LED error states
**LED → Audio**: LED transitions to clot states trigger audio playback
**LED → Lights**: LED states directly drive light values with override logic
**Handle Communication**: All CMS state machines respond to handle communication timeouts

### CMS ↔ Handle Communication

**Handle → CMS Data Flow**:
- Current handle state enumeration
- Current impedance range classification
- Pressure readings
- Clot detection timestamps
- Button press/release synchronization

**CMS → Handle Data Flow**:
- LED color and flashing commands
- Complete configuration updates
- Time synchronization data

### Error Handling and Recovery

**Communication Loss**: Both systems detect communication timeouts (Tcom=1000ms) and enter recovery sequences

**Handle Recovery**: Returns to START state, begins reconnection sequence with flashing green LED

**CMS Recovery**: LED state machine returns to handle connection states, attempts handle power cycle

**Permanent Errors**: System error states (piston state 92, handle state 2000) require full system reset

## Timing Parameters and Configuration

The system uses extensive timing parameters for state transitions and safety:

### Critical Timing Values
- **Tcom (1000ms)**: Communication timeout
- **Trst (500ms)**: Handle reset time
- **TB1-TB4 (400-500ms)**: Piston motion timing
- **Tstack (7000ms)**: Vacuum stack cycle
- **Tlatch (1000ms)**: Wall latch minimum time
- **J (1000ms)**: Clot display minimum time
- **C (2000ms)**: Pressure drop detection time

### Pressure Thresholds
- **K (875 mmHg)**: Handle pressure threshold for fluid injection
- **L (590 mmHg)**: Handle pressure threshold for aspiration
- **L2 (200 mmHg)**: Filtered pressure threshold for wall latch
- **Ls (200 mmHg)**: Syringe pressure threshold for clog detection

## Conclusion

The Inquis Gen 3.0 state machine architecture demonstrates sophisticated coordination between multiple parallel state machines to achieve reliable clot detection and management. The system's design emphasizes safety through comprehensive error handling, communication redundancy, and fail-safe state transitions. The modular architecture with shared common code enables maintainable and testable state machine implementations while ensuring synchronized operation between the CMS and Handle units.

The impedance-based clot detection algorithm, combined with pressure monitoring and timing-based state transitions, provides a robust foundation for medical device operation. The extensive use of configurable parameters allows for field tuning while maintaining deterministic behavior across all operational scenarios.
