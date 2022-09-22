include generated_sources.mk

PROG = firmware

MONGOOSE_FLAGS = -DMG_ARCH=MG_ARCH_FREERTOS_LWIP
MCU_FLAGS = -mcpu=cortex-m7 --specs=nano.specs -mfpu=fpv5-sp-d16 -mfloat-abi=hard -mthumb -DSTM32F746xx -DUSE_STM32F7XX_NUCLEO_144 -DUSE_HAL_DRIVER -fstack-usage -ffunction-sections -fdata-sections

PROJECT_ROOT_PATH = $(realpath $(CURDIR)/../..)
DOCKER ?= docker run --rm -v $(PROJECT_ROOT_PATH):$(PROJECT_ROOT_PATH) -w $(CURDIR) mdashnet/armgcc

INCLUDES =	-I./Core/Inc -I./Core/Src 
INCLUDES += $(BSP_INCLUDES) $(DRIVERS_INCLUDES) $(FREERTOS_INCLUDES) $(LWIP_INCLUDES) 

SOURCES = 	$(wildcard Core/Src/*.c)
SOURCES += 	$(BSP_SOURCES) $(HAL_SOURCES) $(FREERTOS_SOURCES) $(LWIP_SOURCES)

OBJECTS = $(SOURCES:%.c=obj/%.o) obj/startup_stm32f746zgtx.o 

CFLAGS = -std=gnu11 -Os -W -Wall $(MCU_FLAGS) $(MONGOOSE_FLAGS) $(INCLUDES)

# STMCube generated code produces a lot of "unused parameter" warnings
CFLAGS += -Wno-unused-parameter

LINKFLAGS =	-mcpu=cortex-m7 -T"STM32F746ZGTX_FLASH.ld" --specs=nosys.specs \
		-Wl,--gc-sections -static --specs=nano.specs -mfpu=fpv5-sp-d16 -mfloat-abi=hard -mthumb -Wl,--start-group -lc -lm -Wl,--end-group
						
build: $(PROG).bin

$(PROG).bin: $(PROG).elf
	$(DOCKER) arm-none-eabi-objcopy -O binary $< $@

$(PROG).elf: $(OBJECTS)
	$(DOCKER) arm-none-eabi-gcc $(OBJECTS) $(LINKFLAGS) -o $@
	$(DOCKER) arm-none-eabi-size $@

obj/%.o: %.c
	@mkdir -p $(dir $@)
	$(DOCKER) arm-none-eabi-gcc $(CFLAGS) -c $< -o $@

obj/startup_stm32f746zgtx.o: Core/Startup/startup_stm32f746zgtx.s
	@mkdir -p $(dir $@)
	$(DOCKER) arm-none-eabi-gcc $(CFLAGS) -x assembler-with-cpp -c $< -o $@

flash: $(PROG).bin
	st-flash --reset write $< 0x8000000
	
clean:
	@rm -rf $(PROG).* obj
