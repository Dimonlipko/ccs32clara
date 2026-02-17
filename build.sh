#!/bin/bash
# Build script for ccs32clara - workaround for mingw32-make shell issues on Windows

set -e

PREFIX=arm-none-eabi
CC=${PREFIX}-gcc
CPP=${PREFIX}-g++
LD=${PREFIX}-gcc
OBJCOPY=${PREFIX}-objcopy
SIZE=${PREFIX}-size
BINARY=stm32_ccs
OUT_DIR=obj

CFLAGS="-Os -Iinclude/ -Ilibopeninv/include -Ilibopencm3/include -Iexi -Iccs \
  -fno-common -fno-builtin -DSTM32F1 \
  -mcpu=cortex-m3 -mthumb -std=gnu99 -ffunction-sections -fdata-sections"

CPPFLAGS="-Og -ggdb -Wall -Wextra -Iinclude/ -Ilibopeninv/include -Ilibopencm3/include -Iexi -Iccs \
  -fno-common -std=c++11 -pedantic -DSTM32F1 -DUSART_BAUDRATE=921600 \
  -ffunction-sections -fdata-sections -fno-builtin -fno-rtti -fno-exceptions -fno-unwind-tables \
  -mcpu=cortex-m3 -mthumb -DGITHUB_RUN_NUMBER=0"

LDFLAGS="-Llibopencm3/lib -Tlinker.ld -march=armv7 -nostartfiles -Wl,--gc-sections,-Map,linker.map"

mkdir -p $OUT_DIR

# C++ files from src/
CPP_SRC_FILES="src/main.cpp src/hwinit.cpp src/terminal_prj.cpp"

# C++ files from libopeninv/src/
CPP_LIBOPENINV_FILES="
libopeninv/src/stm32scheduler.cpp
libopeninv/src/params.cpp
libopeninv/src/terminal.cpp
libopeninv/src/digio.cpp
libopeninv/src/printf.cpp
libopeninv/src/anain.cpp
libopeninv/src/param_save.cpp
libopeninv/src/errormessage.cpp
libopeninv/src/stm32_can.cpp
libopeninv/src/canhardware.cpp
libopeninv/src/canmap.cpp
libopeninv/src/cansdo.cpp
libopeninv/src/picontroller.cpp
libopeninv/src/terminalcommands.cpp
"

# C++ files from ccs/
CPP_CCS_FILES="
ccs/ipv6.cpp
ccs/tcp.cpp
ccs/connMgr.cpp
ccs/modemFinder.cpp
ccs/pevStateMachine.cpp
ccs/temperatures.cpp
ccs/acOBC.cpp
ccs/wakecontrol.cpp
ccs/hardwareInterface.cpp
ccs/hardwareVariants.cpp
ccs/pushbutton.cpp
ccs/udpChecksum.cpp
ccs/homeplug.cpp
ccs/myHelpers.cpp
ccs/qca7000.cpp
"

# C files from libopeninv/src/
C_LIBOPENINV_FILES="
libopeninv/src/my_string.c
libopeninv/src/my_fp.c
"

# C files from exi/
C_EXI_FILES="
exi/appHandEXIDatatypesDecoder.c
exi/ByteStream.c
exi/EncoderChannel.c
exi/appHandEXIDatatypesEncoder.c
exi/DecoderChannel.c
exi/EXIHeaderDecoder.c
exi/appHandEXIDatatypes.c
exi/dinEXIDatatypesDecoder.c
exi/EXIHeaderEncoder.c
exi/BitInputStream.c
exi/dinEXIDatatypesEncoder.c
exi/MethodsBag.c
exi/BitOutputStream.c
exi/dinEXIDatatypes.c
exi/projectExiConnector.c
"

ERRORS=0

# Compile C++ files
for f in $CPP_SRC_FILES $CPP_LIBOPENINV_FILES $CPP_CCS_FILES; do
  name=$(basename "$f" .cpp)
  echo "  CPP     $f"
  if ! $CPP $CPPFLAGS -MMD -MP -o "$OUT_DIR/${name}.o" -c "$f" 2>&1; then
    ERRORS=$((ERRORS + 1))
  fi
done

# Compile C files
for f in $C_LIBOPENINV_FILES $C_EXI_FILES; do
  name=$(basename "$f" .c)
  echo "  CC      $f"
  if ! $CC $CFLAGS -MMD -MP -o "$OUT_DIR/${name}.o" -c "$f" 2>&1; then
    ERRORS=$((ERRORS + 1))
  fi
done

if [ $ERRORS -gt 0 ]; then
  echo ""
  echo "=== BUILD FAILED: $ERRORS file(s) had errors ==="
  exit 1
fi

echo ""
echo "=== All files compiled successfully ==="

# Link
echo "  LD      $BINARY"
$LD $LDFLAGS -o $BINARY $OUT_DIR/*.o -lopencm3_stm32f1 -lm 2>&1

echo "  OBJCOPY ${BINARY}.bin"
$OBJCOPY -Obinary $BINARY ${BINARY}.bin

echo "  OBJCOPY ${BINARY}.hex"
$OBJCOPY -Oihex $BINARY ${BINARY}.hex

$SIZE $BINARY

echo ""
echo "=== BUILD SUCCESSFUL ==="
echo "Output: ${BINARY}.bin, ${BINARY}.hex"
