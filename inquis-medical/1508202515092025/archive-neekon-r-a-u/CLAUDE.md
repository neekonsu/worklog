# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is an embedded systems project for a medical device (Inquis Gen 3.0) that consists of two separate STM32L471RET microcontrollers:

- **CMS (Clot Management System)**: The base device and logic master, handles SD card logging, power management, and user-visible state
- **Handle**: Connected to CMS via bidirectional data/power connection, measures impedance via AD5940 sensor, manages clot state detection

Both MCUs share common code in the `common/` directory and use STM32 HAL drivers.

## Build Commands

### Environment Setup
Before building, source the environment file:
```bash
source env_lab.sh
```

### Building
```bash
# Build both CMS and handle (default tip_size=24, emc=0)
./build.sh

# Build specific target with options
./build.sh cms tip_size=16 emc=1
./build.sh handle tip_size=24 emc=0
./build.sh both tip_size=16 emc=1

# Clean builds
./build.sh clean
```

### Code Formatting
```bash
# Format all source code using clang-format
./format.sh
```

### Packaging (Release Build)
```bash
# Create release package with version tagging
./package.sh emc=0
```

### Individual MCU Builds (from CLI)
```bash
# CMS build
cd ./cms/Debug
make gen_3_0_cms.hex

# Handle build  
cd ./handle/Debug
make gen_3_0_handle.hex
```

### Flashing/Programming
```bash
# Flash handle firmware
./update_handle.sh

# List available SWD programming devices
STM32_Programmer_CLI.exe --list

# Flash specific device by serial number
STM32_Programmer_CLI -c port=SWD "sn=003400343233510739363634" -w gen_3_0_handle.hex -rst
```

## Architecture Overview

### Directory Structure
- `cms/` - CMS microcontroller code (STM32CubeIDE project)
- `handle/` - Handle microcontroller code (STM32CubeIDE project)  
- `common/` - Shared code between both MCUs
- `Inquis_3_0_GUI/` - C# .NET GUI application
- `bin_decoder/` - Binary log file decoder utility
- `html/` - Doxygen-generated documentation

### Key Configuration Files
- `common/version.h` - Version string (modified by build scripts)
- `common/defines.h` - Build-time configuration (EMC, TIP_SIZE)
- `common/default_config.txt` - Default device configuration

### Communication Architecture
- CMS acts as master, Handle as slave
- Bidirectional data communication between MCUs using UART/DMA
- CMS manages power to Handle and boot-up sequence
- Handle reports clot state, impedance data, and button events to CMS
- CMS sends LED UI state and configuration to Handle
- Communication timeout detection (Tcom=1000ms) with recovery sequences

### State Machine Architecture

The system implements **4 interconnected state machines** on CMS and **1 comprehensive state machine** on Handle:

#### CMS State Machines (4 parallel machines):
1. **Piston Control** (16 states) - Controls syringe mechanism for aspiration/injection
2. **LED Control** (16 states) - Manages visual feedback through LED colors/patterns  
3. **Audio Control** (7 states) - Provides auditory feedback for clot detection
4. **Light Value Translation** (17 states) - Converts LED states to RGB values

#### Handle State Machine (1 machine):
- **Impedance & Sampling** (11 states) - Impedance monitoring and clot detection

### Critical Algorithms & Parameters

#### Impedance Range Classification (Handle):
- **Range 1 (0-100Ω)**: Short circuit (error)
- **Range 2 (100-1800Ω)**: Saline, blood, wall touch  
- **Range 3 (1800-12000Ω)**: Clot material
- **Range 4 (12000-100000Ω)**: Air
- **Range 5 (100000+Ω)**: Open circuit

#### Clot Detection Logic:
- Requires X consecutive data points (X=2) in Range 3 within P+B sample dataset
- Pressure drop detection: 100 mmHg drop over 10 samples triggers aspiration evaluation
- Wall latch detection: Filtered pressure < L2 (200 mmHg) + impedance in range Q-R (1100-2500Ω)

#### Critical Timing Parameters:
- **Tcom (1000ms)**: Communication timeout
- **Trst (500ms)**: Handle reset time  
- **TB1-TB4 (400-500ms)**: Piston motion timing
- **Tstack (7000ms)**: Vacuum stack cycle
- **J (1000ms)**: Clot display minimum time

#### Pressure Thresholds:
- **K (875 mmHg)**: Handle pressure threshold for fluid injection
- **L (590 mmHg)**: Handle pressure threshold for aspiration  
- **L2 (200 mmHg)**: Filtered pressure for wall latch detection
- **Ls (200 mmHg)**: Syringe pressure for clog detection

### Key Modules (Common)
- `comm.c/h` - Inter-MCU communication protocol with UART/DMA
- `packet.c/h` - Packet-based data exchange with CRC validation
- `fifo.c/h` - FIFO buffers for data streams between MCUs
- `log.c/h` - Binary logging system with SD card storage
- `config.c/h` - Configuration management from default_config.txt
- `devices.c/h` - Hardware device abstraction layer
- `led_driver.c/h` - LED control via I2C
- `lights.c/h` - Light pattern management and RGB translation
- `state_defs.c/h` - Centralized state enumerations and string tables

### Development Tools
- STM32CubeIDE for firmware development
- Doxygen for documentation generation  
- clang-format for code formatting
- Custom bash scripts for build automation
- Python plotting software in `__Gen 3 Reference Plotting Software/`

## State Machine Details

### CMS Piston States (Critical Flow):
```
START(00) → POST(10) → AWAITING_STOP_AT_FRONT(30) → AWAITING_ASPIRATION(40)
    ↓
START_MOTION_BACKWARD(51) → ACTIVE_MOTION_BACKWARD(52) → CONFIRMING_STOP(60)
    ↓  
VACUUM_AT_BACK_STOP(71) → VACUUM_HOLDING_AT_BACK(72) → START_MOTION_FORWARDS(21) → ACTIVE_MOTION_FORWARDS(22)
```

**Safety States**: OUT_OF_CO2(81-83), SYSTEM_ERROR(91-92)

### CMS LED States (Visual Feedback):
```
START(000) → POWER_ON(100) → Handle Connection Sequence(301-305) → MIRROR_HANDLE(402)
    ↓
CLOT_START(501) ↔ CLOT(502) ↔ CLOGGED(600) ↔ CLOGGED_WITH_CLOT_AND_TIP(800)
```

### Handle States (Impedance Detection):
```
START(0000) → CONNECT(1000) → START_MONITOR_THRESHOLDS(3001) → MONITOR_THRESHOLDS(3002)
    ↓
FLUID_INJECTION(4000) OR START_ASPIRATION(5001) → ASPIRATION_EVAL_DATA_COLLECTION(5002)
    ↓
ASPIRATION_EVAL_ANALYSIS(5003) → [WALL_LATCH(6001) → WALL_LATCH_DELAY(6002)] OR back to monitoring
```

## Testing

Unit tests are located in:
- `common/unit_tests/` - Core functionality tests
- `cms/inquis/integration_tests/` - CMS integration tests  
- `handle/inquis/unit_tests/` - Handle unit tests
- State diagram PDFs in `state_diagrams/` for validation

## Import into STM32CubeIDE

1. File → Import → General → Existing Projects into Workspace
2. Select root directory of cms/ or handle/
3. Configure common/ folder symlink:
   - Right-click common/ → Properties → Resource → Location → Edit
   - Point to project's common/ folder
4. Build both projects once from IDE before using CLI tools
5. Generate audio header: `xxd -i ./media/audio0.wav > ./cms/inquis/_audio0.h`

## Memory Safety & Code Quality Notes

### Critical Memory Safety Issues (from Devin AI analysis):
- **FIFO Buffer Overflow**: Writing beyond PACKET_SIZE boundary in `common/fifo.c:68-75` 
- **Array Bounds in State Machines**: Out-of-bounds access to state name arrays in `cms_state.c:1217-1252`
- **Impedance Buffer Overflow**: memmove operations without bounds validation in `han_state.c:653-661`
- **Communication Race Conditions**: Shared globals updated from interrupt context in `han_state.c:89-99`
- **Audio Buffer Stack Overflow**: Large static arrays (6000 bytes) in `cms_devices.c:63-64`

### Outstanding Technical Debt (from REMARKS.md):

#### Critical Issues:
- UART error handling incomplete - overrun errors not fully understood (`comm.c:HAL_UART_ErrorCallback`)
- SD card operations slow (2+ minutes for free space check) - suspect card format issues
- POST doesn't validate all sensors, only function returns
- Static variable abstraction violations in `lights.c` - global state manipulation

#### High Priority:
- Error propagation needs improvement - many HAL calls lack error checking
- Memory management inconsistent - malloc() calls without graceful failure handling  
- Config structure assumes all-int fields - type safety needed
- Communication protocol needs proper error handling and timeouts
- State machine array bounds checking missing throughout

#### Nice to Have:
- Remove redundant TODO comments and clean up code structure
- Implement compiler flags instead of #ifdef for subsystem selection
- Add integration tests for error logging and recovery scenarios
- Consolidate test notebooks from SharePoint to git repository

### Testing & Validation Needs:
- **Stress Testing**: 24+ hour continuous operation testing
- **Memory Corruption**: Injection testing during state transitions  
- **Communication Failure**: Simulation during critical states
- **Boundary Conditions**: Testing for all array operations
- **System Pounding**: "Use the shit out of it" - intensive usage testing to find edge cases
- **Flow Diagram Validation**: Use state diagrams to systematically find break scenarios

## Version Control Notes

- Package script requires clean git state (no uncommitted changes)
- Packaging automatically creates git tags (v{VERSION})
- Build artifacts (.hex files) should not be committed
- `defines.h` and `version.h` are modified by build scripts but restored automatically
- Log version compatibility: V4/V5/Vxx logs have different state names - need version-aware decoder