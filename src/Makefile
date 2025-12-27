# Compiladores
AS = aarch64-linux-gnu-as
LD = aarch64-linux-gnu-ld

# Flags para debugeado
ASFLAGS = -g
LDFLAGS = -g

# Directorios para salidas
SRC_DIR = .
BIN_AS = bin_as
OBJ_DIR = obj

# Crear directorios si no existen
$(shell mkdir -p $(BIN_AS) $(OBJ_DIR))

# Archivos adicionales
ADDITIONAL_SOURCES = constantes.s key_expansion.s inv_shift_rows.s inv_sub_bytes.s add_round_key.s inv_mix_columns.s
ADDITIONAL_OBJECTS = $(patsubst %.s, $(OBJ_DIR)/%.o, $(ADDITIONAL_SOURCES))

# Generación de comandos de compilación
ifdef archivo
    ifeq ($(suffix $(archivo)),.s)
        TARGET = $(BIN_AS)/$(basename $(archivo))_asm
        OBJECT = $(OBJ_DIR)/$(basename $(archivo)).o
        SOURCE = $(archivo)

        COMPILE_CMD = \
            $(foreach src, $(ADDITIONAL_SOURCES), $(AS) $(ASFLAGS) $(SRC_DIR)/$(src) -o $(OBJ_DIR)/$(basename $(src)).o;) \
            $(AS) $(ASFLAGS) $(SRC_DIR)/$(SOURCE) -o $(OBJECT); \
            $(LD) $(LDFLAGS) -e _start $(OBJECT) $(ADDITIONAL_OBJECTS) -o $(TARGET) -lc --dynamic-linker /usr/aarch64-linux-gnu/lib/ld-linux-aarch64.so.1
    else
        $(error El archivo debe tener extensión .s)
    endif
endif

# Regla principal
all:
ifndef archivo
    @echo "Error: Debes especificar un archivo con 'make archivo=archivo.s'"
else
	@echo "Compilando $(SOURCE)..."
	$(COMPILE_CMD)
	@echo "Compilación completa. Binario: $(TARGET)"
endif

# Limpieza
clean:
	@rm -rf $(BIN_AS) $(OBJ_DIR)

# Debug
debug: all
	@if [ -f "$(TARGET)" ]; then \
		echo "Ejecutando GDB para depuración..."; \
		gdb -q $(TARGET); \
	else \
		echo "Error: El target no existe. Usa 'make archivo=archivo.s' primero."; \
	fi

.PHONY: all clean debug

run:
	LD_LIBRARY_PATH=/usr/aarch64-linux-gnu/lib qemu-aarch64 ./$(BIN_AS)/main_asm