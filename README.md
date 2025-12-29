# Algoritmo de Desencriptación AES-128 [ACYE1-Grupo 1]

## Integrantes del Proyecto

| Nombre                          | Carnet    |
|---------------------------------|-----------|
| Yeison Omar López Dueñas        | 202102688 |
| Héctor Antonio Cardona Cos      | 202307354 |
| Ottoniel Fabicio Vásquez Pineda | 202307820 |
| Pablo Daniel Velásquez Hernández| 202302232 |
| Diego Eduardo España Vásquez    | 202307716 |

## Descripción del proyecto
Este repositorio contiene la implementación del Proyecto 2: Algoritmo de Desencriptación AES-128 para el curso de Arquitectura de Computadoras y Ensambladores 1 en la Facultad de Ingeniería de la Universidad de San Carlos de Guatemala (USAC). El proyecto consta de un algoritmo de desencriptación simétrica AES de 128 que fue desarrollado por medio de lenguaje ensamblador ARM64. 

El proyecto realiza las transformaciones inversas del cifrado AES: `InvSubBytes`, `InvShiftRows`, `InvMixColumns`, `AddRoundKey` y el `Key Expansion` necesario para las rondas, integradas en `main.s`.

## Objetivos
- Diseñar e Interpretar algoritmos inversos para la resolucióon de problemas.
- Desarrollar soluciones de cifrado en lenguaje de bajo nivel.
- Manipular segmentos de memoria a bajo nivel, buscando la eficiencia de un programa.

## Tecnologías utilizadas
- Assembly (GNU As) para la lógica de AES‑128.
- Make (`Makefile`) para compilación y ejecución.
- Herramientas de línea de comando para ensamblado y enlace.

## Uso
Desde la carpeta `src/`, con las herramientas instaladas:

```
make clean
make archivo=main.s
make run
```

## Estructura
- `src/`: archivos `.s` del algoritmo y `Makefile`.
- `documentacion/`: informes y manuales del usuario.
- `src/obj/`: archivos `.o` es el código objeto que se genera al compilar.

## Entregables
- Programa funcional de la aplicación
- Informe Técnico
- Informe de impacto
- Manual de usuario
