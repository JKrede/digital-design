# TP1 - Shift register de LEDs controlado por switches

Diseño en Verilog para la placa **Digilent Arty A7** que enciende los LEDs de a uno por vez, desplazando el bit encendido de forma circular (`0001 → 0010 → 0100 → 1000 → 0001 …`). Con los switches se habilita el movimiento, se elige la velocidad y se cambia el color de los LEDs RGB.

El sistema además incluye un **VIO** (Virtual Input/Output) para manejar las entradas sin tener acceso fisico a la placa, y un **ILA** (Integrated Logic Analyzer) para observar las salidas en tiempo real. Ambos modulos se utilizan debido a que no se tiene acceso fisico a la placa, por lo tanto de esta manera uno ejecutar la sintesis del diseño en un cluster de FPGAs y poder manipularlo desde vivado y observar su comportamiento

## Funcionamiento

### Entradas y salidas

| Señal          | Dirección | Descripción                                                         |
| -------------- | --------- | ------------------------------------------------------------------- |
| `clock`        | entrada   | Reloj de 100 MHz de la placa                                        |
| `i_reset`      | entrada   | Reset del sistema (botón `ck_rst`), **activo en bajo**              |
| `i_sw[0]`      | entrada   | Enable: `1` los LEDs se mueven, `0` se congelan en el estado actual |
| `i_sw[2:1]`    | entrada   | Selección de velocidad (límite del contador)                        |
| `i_sw[3]`      | entrada   | Color de los LEDs RGB: `0` azul, `1` verde                          |
| `o_led[3:0]`   | salida    | LEDs LD4–LD7                                                        |
| `o_led_b[3:0]` | salida    | Canal azul de los LEDs RGB LD0–LD3                                  |
| `o_led_g[3:0]` | salida    | Canal verde de los LEDs RGB LD0–LD3                                 |

### Módulos

#### `count.v` - Contador con límite seleccionable

- Mientras `i_enable = 1` el contador se incrementa en cada flanco de reloj. Con `i_enable = 0` mantiene su valor.
- Cuando el contador llega al límite elegido por `i_sel`, vuelve a cero y pone `o_valid = 1` durante ese ciclo de reloj.
- El límite se puede cambiar en cualquier momento durante la operación.
- Reset asíncrono, activo en alto.

Con `NB_COUNTER = 32` y el reloj de 100 MHz (10 ns), los límites dan los siguientes tiempos entre desplazamientos:

| `sw[2:1]` | Límite       | Ciclos por paso | Tiempo por paso |
| --------- | ------------ | --------------- | --------------- |
| `00`      | R0 = 2²² − 1 | 2²²             | ≈ 42 ms         |
| `01`      | R1 = 2²³ − 1 | 2²³             | ≈ 84 ms         |
| `10`      | R2 = 2²⁴ − 1 | 2²⁴             | ≈ 168 ms        |
| `11`      | R3 = 2²⁵ − 1 | 2²⁵             | ≈ 336 ms        |

#### `shiftreg.v` - Registro de desplazamiento

- Registro de `N_LEDS` bits que al reset se inicializa en `0...01`.
- Cada vez que `i_valid = 1` rota un lugar a la izquierda; el bit más significativo vuelve a la posición 0.
- Reset asíncrono, activo en alto.

#### `top.v` - Módulo principal

- **Mux placa / VIO:** según `selMux` (salida del VIO), los switches y el reset se toman de la placa (`selMux = 0`) o del VIO (`selMux = 1`).
- **Reset:** el reset de la placa y el del VIO son activos en bajo; en el top se invierten para obtener el `reset` interno activo en alto que usan `count` y `shiftreg`.
- **Instancias:** conecta la salida `o_valid` de `count` con la entrada `i_valid` de `shiftreg` mediante `connect_valid`.
- **Color:** `sw[3]` decide si el estado del shift register se muestra en el canal azul (`led_b`) o verde (`led_g`) de los LEDs RGB; el otro canal queda apagado. Los LEDs `o_led` siempre muestran el estado.
- **Debug:** el VIO y el ILA leen las señales internas (`connect_leds`, `led_b`, `led_g`) y no los puertos de salida.

## Debug con VIO e ILA

### VIO

| Puerto         | Ancho | Señal            | Uso                                    |
| -------------- | ----- | ---------------- | -------------------------------------- |
| `probe_in0_0`  | 4     | `connect_leds`   | Ver el estado del shift register       |
| `probe_in1_0`  | 4     | `led_b`          | Ver el canal azul                      |
| `probe_in2_0`  | 4     | `led_g`          | Ver el canal verde                     |
| `probe_out0_0` | 1     | `selMux`         | `0` placa, `1` VIO                     |
| `probe_out1_0` | 1     | `reset_from_VIO` | Reset desde el VIO, **activo en bajo** |
| `probe_out2_0` | 4     | `sw_from_VIO`    | Switches desde el VIO                  |

> Al pasar a `selMux = 1`, poner `reset_from_VIO = 1`; si queda en `0`, el sistema se mantiene en reset.

### ILA

El ILA tiene 3 probes de 4 bits (`probe0_0`, `probe1_0`, `probe2_0`) conectados a `connect_leds`, `led_b` y `led_g`. El IP tiene que estar configurado con esa misma cantidad y ancho de probes.

## Simulación

El testbench `sims/tb_shiftleds.v` instancia `top` con `NB_COUNT = 14`, para que los desplazamientos ocurran cada pocos ciclos y la simulación sea rápida. Como en simulación nadie maneja el VIO, se fuerza `selMux = 0` para usar las entradas de la placa.

Secuencia de estímulos:

1. Reset activo durante 100 ns, luego se libera.
2. Se habilita el sistema (`sw[0] = 1`) con `sw[2:1] = 00`.
3. Cada 1 ms se cambia la configuración: `sw[2:1] = 01`, luego `10`, luego `sw[3] = 1` (color verde) y por último `sw[2:1] = 11`.

Resultado esperado: el LED encendido rota `1 → 2 → 4 → 8`, el tiempo entre pasos se duplica con cada cambio de límite (160, 320, 640 y 1280 ns) y, al poner `sw[3] = 1`, el estado pasa de `o_led_b` a `o_led_g`.

## Implementación en la placa

1. Crear un proyecto en Vivado para la Arty A7 y agregar los archivos de `src/`, `sims/` y `constrains/`.
2. Agregar los IPs `vio` e `ila` con la configuración de puertos descripta arriba.
3. Marcar `top` como módulo principal.
4. Sintetizar, implementar, generar el bitstream y programar la placa.
5. Conectarse de manera remota al servidor con el cluster de FPGAs utilizando SSH.
6. Solicitar una FPGA.
7. Agregar el target en vivado seleccionado `remote server` y colocando la ip asignada.
