# Manual de Usuario
## Algoritmo de Desencriptación AES-128 [ACYE1-Grupo 1]

---

## 1. Proposito del programa
Aplicacion en ensamblador ARM64 que realiza la desencriptacion de un bloque AES-128 (16 bytes) en modo de depuracion, mostrando cada paso (subclaves, rondas y estados intermedios).

---

## 2. Requisitos previos
- Sistema Linux o WSL en Windows.
- Toolchain cruzado ARM64: `aarch64-linux-gnu-as`, `aarch64-linux-gnu-ld`.
- (Opcional en x86_64) Emulador `qemu-aarch64` para ejecutar binarios ARM.
- Make 4.x.

Instalacion rapida en Ubuntu/WSL:
```bash
sudo apt update
sudo apt install gcc-aarch64-linux-gnu qemu-user make
```

---

## 3. Estructura del proyecto
- `src/` codigo fuente en ensamblador:
  - `main.s` orquesta el flujo de desencriptacion.
  - `key_expansion.s`, `add_round_key.s`, `inv_shift_rows.s`, `inv_sub_bytes.s`, `inv_mix_columns.s` implementan pasos AES.
  - `constantes.s` tablas AES (S-Box inversa, Rcon).
- `src/Makefile` automatiza compilacion y enlace.
- `bin_as/` binarios generados.
- `obj/` objetos intermedios.

---

## 4. Preparacion del entorno
1) Clonar o copiar el proyecto en una carpeta accesible desde Linux/WSL.
2) Verificar herramientas:
```bash
aarch64-linux-gnu-as --version
aarch64-linux-gnu-ld --version
qemu-aarch64 --version   # solo si estas en x86_64
```

---

## 5. Compilacion y ejecucion
Desde la carpeta `src/`:
```bash
make clean
make archivo=main.s
make run
```
Esto genera `bin_as/main_asm` y lo ejecuta con los datos de prueba incluidos.

Ejecutar manualmente (si no usas `make run`):
```bash
./bin_as/main_asm        # en ARM64 nativo
qemu-aarch64 ./bin_as/main_asm   # en x86_64 con emulacion
```

---

## 6. Parametros y datos de prueba
- Texto cifrado de prueba: `29 C3 50 5F 57 14 20 F6 40 22 99 B3 1A 02 D7 3A`.
- Clave de prueba (ASCII "Thats my Kung Fu"): `54 68 61 74 73 20 6D 79 20 4B 75 6E 67 20 46 75`.
- Estos valores estan definidos en `main.s` en las etiquetas `test_cipher` y `test_key`.
- Para probar con otros datos, edita esas secciones y recompila.

---

## 7. Flujo de ejecucion mostrado en pantalla
1) Encabezado y separadores.
2) Impresion del texto cifrado y la clave original en hex.
3) Generacion e impresion de las 11 subclaves (key expansion).
4) Ronda inicial (ronda 10): AddRoundKey con la subclave 10.
5) Rondas intermedias 9 a 1: InvShiftRows -> InvSubBytes -> AddRoundKey -> InvMixColumns (con estados intermedios).
6) Ronda final (ronda 0): InvShiftRows -> InvSubBytes -> AddRoundKey.
7) Resultado final en hex y en ASCII.

---

## 8. Demostración de uso
1) **Pantalla de requisitos mínimos para ejecutar el programa**
   ![Requisitos](/documentacion/imgs/Requisitos.png)

2) **Resultado de `make archivo=main.s` con mensaje de binario generado**

![Resultado](/documentacion/imgs/Resultado.png)

3) **Inicio del programa: entrada de texto cifrado y clave**

![Inicio](/documentacion/imgs/Entrada.png)

4) **Ronda incial**

![Incial](/documentacion/imgs/Inicial.png)

5) **Seccion de subclaves expandidas (11 subclaves)**

![Subclaves](/documentacion/imgs/Subclaves.png)

6) **Ronda intermedia**

![Ronda Intermedia](/documentacion/imgs/Intermedia.png)

7) **Ronda final**

![Ronda Final](/documentacion/imgs/Final.png)

8) **Resultado final**

![Resultado Final](/documentacion/imgs/ResultadoF.png)


---

## 9. Errores comunes y soluciones
- **"aarch64-linux-gnu-as: command not found"**: instala el toolchain cruzado (`gcc-aarch64-linux-gnu`).
- **"No se encuentra obj/..."**: ejecuta los comandos desde `src/` o crea `obj/` y `bin_as/` (Makefile los crea automaticamente).
- **"Permission denied" al ejecutar**: `chmod +x bin_as/main_asm` o ejecuta con `qemu-aarch64 ./bin_as/main_asm`.
- **Salida vacia o incorrecta tras editar datos**: confirma que los bloques son de 16 bytes y recompila.

---

## 10. Personalizacion rapida
- Cambiar texto cifrado o clave: editar `test_cipher` y `test_key` en `main.s` (16 bytes cada uno).
- Desactivar mensajes de depuracion: remover o comentar las llamadas `print_*` correspondientes y recompilar.
- Integrar en otro entorno: enlazar `main.o` con las rutinas AES y adaptar la seccion `.data` para leer desde memoria o argumentos.

---

## 11. Referencia rapida de comandos
```bash
# Compilar y ejecutar
cd src
make archivo=main.s
make run

# Ejecutar manualmente
./bin_as/main_asm               # en ARM64
qemu-aarch64 ./bin_as/main_asm  # en x86_64
```
