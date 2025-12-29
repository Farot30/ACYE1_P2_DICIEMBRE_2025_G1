# Informe Técnico
## Algoritmo de Desencriptación AES-128 [ACYE1-Grupo 1]

---

## 1. Alcance
Documento tecnico sobre la implementacion del descifrado AES-128 en ARMv8/aarch64, destacando problemas encontrados y soluciones aplicadas o recomendadas.

---

## 2. Arquitectura general
- Flujo: Key Expansion -> Ronda inicial (AddRoundKey) -> 9 rondas inversas (InvShiftRows, InvSubBytes, AddRoundKey, InvMixColumns) -> Ronda final (InvShiftRows, InvSubBytes, AddRoundKey).
- Modulos clave: `key_expansion.s`, `inv_sub_bytes.s`, `inv_shift_rows.s`, `inv_mix_columns.s`, `add_round_key.s`, utilidades de impresion en `itoa.s` y tablas en `constantes.s`.

---

## 3. Proceso de Desarrollo

### 3.1 Fase de Planificación
- Análisis del estándar AES-128 para comprensión del algoritmo de descifrado.
- Diseño de la arquitectura general del flujo de ejecución.
- División del trabajo por módulos y asignación de responsabilidades a cada integrante.

### 3.2 Fase de Implementación de Módulos
1. **Key Expansion** (`key_expansion.s`): Generación de subclaves para las 11 rondas (ronda inicial + 9 rondas + ronda final).
2. **InvShiftRows** (`inv_shift_rows.s`): Desplazamiento inverso de filas en la matriz de estado.
3. **InvSubBytes** (`inv_sub_bytes.s`): Sustitución de bytes usando la tabla S-box inversa.
4. **InvMixColumns** (`inv_mix_columns.s`): Transformación lineal inversa sobre columnas usando multiplicación en GF(2^8).
5. **AddRoundKey** (`add_round_key.s`): XOR del estado con la subclave de ronda.
6. **Utilidades** (`constantes.s`): Tablas de datos.

### 3.3 Fase de Integración
- Integración de todos los módulos en `main.s` siguiendo el orden correcto del algoritmo.
- Configuración del `Makefile` para compilación, ensamblado y ejecución.
- Pruebas iniciales con casos de entrada conocidos.

### 3.4 Fase de Pruebas y Debugging
- Ejecución de pruebas unitarias por cada módulo.
- Validación con vectores de prueba NIST.
- Debugging iterativo de componentes problemáticas (InvMixColumns, tabla S-box).
- Revisión de gestión de registros y memoria.

### 3.5 Fase de Documentación
- Redacción del informe técnico con problemas y soluciones.
- Elaboración del manual de usuario con instrucciones de compilación y uso.
- Documentación del informe de impacto del proyecto.

---

## 4. Problemas principales y soluciones

### 4.1 invMixColumns en ARM64
**Problema:**
- Implementacion inicial con uso ineficiente de registros y accesos a memoria, provocando estados incorrectos y penalizacion de rendimiento.

**Soluciones aplicadas/recomendadas:**
- Reescribir la rutina en forma column-major clara: cargar 4 bytes de la columna, operar en registros, y almacenar de regreso sin aliasing.
- Alinear datos en memoria y usar registros X/W separados para evitar sign-extension accidental.
- Validar con vectores conocidos: aplicar InvMixColumns sobre la matriz identidad (debe devolver la matriz M^-1), y sobre bloques de prueba NIST.

### 4.2 Tabla inverse S-Box incorrecta
**Problema:**
- Tabla inversa en `constantes.s` contenia valores desordenados, lo que generaba sustituciones erradas en `inv_sub_bytes.s` y descifrado incorrecto.

**Soluciones aplicadas/recomendadas:**
- Verificar integridad con hash o comparacion automatica contra un archivo de referencia en pruebas.
- Incluir prueba unitaria: para cada byte b, verificar que `S^-1[S[b]] == b` usando ambas tablas (directa e inversa) cuando sea pertinente.

### 4.3 Mal funcionamiento de funciones auxiliares
**Problema:**
- Rutinas de depuracion/impresion podian alterar registros sin restaurarlos, afectando el estado de AES en medio de las rondas.

**Soluciones aplicadas/recomendadas:**
- Reducir el uso de funciones de impresion dentro del nucleo critico: capturar estados en buffers y mostrar solo en puntos de control.

### 4.4 Gestion de estado y endianess
**Problema:**
- Confusion entre orden column-major de AES y layout lineal en memoria; riesgo de leer/escribir filas vs columnas de forma incorrecta.

**Soluciones aplicadas/recomendadas:**
- Documentar en comentarios el mapping: columna C = bytes[C*4 + fila].
- Centralizar macros de acceso a estado (load_col, store_col) para evitar errores repetidos.
- Mantener consistencia little-endian del host: trabajar siempre en bytes y ensamblar columnas explicitamente.

---

## 5. Estrategia de validacion
- **Pruebas NIST**: usar bloques de prueba conocidos (cipher, key, plain) y verificar salida.
- **Pruebas columnares**: aplicar InvMixColumns sobre columnas conocidas y comparar con resultados de referencia.
- **Prueba de tabla inversa**: recorrer 0..255 y validar sustitucion inversa.
- **Pruebas de regresion**: scripts que ensamblen, ejecuten bajo qemu-aarch64 y comparen salida con esperado.

---

## 6. Rendimiento y buenas practicas
- Minimizar accesos a memoria dentro de rondas; mantener estado en registros cuando sea posible.
- Evitar derrames (spills) reorganizando registros de trabajo.
- Usar instrucciones ldp/stp para cargas/alojamientos alineados de 16 bytes cuando se trabaje con subclaves.
- Asegurar que las rutinas de impresion esten fuera del camino caliente en modo produccion.

