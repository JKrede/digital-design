# Guía de Métricas de Timing en Vivado (Análisis Estático de Tiempos)

Esta guía explica las métricas que aparecen en el **Design Timing Summary** de Vivado, qué representan físicamente, un ejemplo sencillo en palabras para cada una, y cómo solucionar violaciones cuando el diseño no cumple con el timing definido.

## 1. Conceptos previos

Antes de entrar en las métricas, hay tres ideas que hay que tener claras:

- **Camino (path):** el recorrido que hace una señal desde un punto de partida (un flip-flop o un puerto de entrada) hasta un punto de llegada (otro flip-flop o un puerto de salida), pasando por lógica combinacional en el medio.
- **Slack:** es el "margen" de tiempo que sobra (o falta) para que una señal llegue a tiempo. Se calcula como:

  ```
  slack = tiempo_requerido - tiempo_real_del_camino
  ```

  - **Slack positivo** → la señal llegó con margen, todo bien.
  - **Slack negativo** → la señal llegó tarde (o demasiado rápido, según el caso), hay una violación.

- **Endpoint:** el destino final de un camino de timing (normalmente la entrada `D` de un flip-flop, o un puerto de salida).

Vivado agrupa el análisis en tres grandes categorías: **Setup**, **Hold** y **Pulse Width**.

## Setup (tiempo de configuración)

### ¿Qué mide?

Verifica que el dato **llegue con suficiente anticipación** antes del próximo flanco de reloj que lo va a capturar. Si el dato llega demasiado tarde, el flip-flop puede capturar un valor incorrecto o inestable.

### Ejemplo en palabras

Imaginá que tenés que entregar un examen antes de que suene el timbre. El **setup time** es como decir "necesito tener el examen sobre el escritorio del profesor al menos 2 minutos antes de que suene el timbre". Si llegás con el examen 30 segundos antes del timbre, no cumpliste el setup: **violación de setup**. Si llegás con 5 minutos de sobra, hay slack positivo.

### Métricas asociadas

| Métrica                         | Significado                                                                                                                                        |
| ------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------- |
| **WNS** (Worst Negative Slack)  | El peor (más negativo) slack de _setup_ entre todos los caminos del diseño. Si es positivo o `inf`, no hay violaciones.                            |
| **TNS** (Total Negative Slack)  | La suma de **todos** los slacks negativos de setup. Indica qué tan "grave" es el problema en conjunto (muchas violaciones chicas o pocas grandes). |
| **Number of Failing Endpoints** | Cuántos destinos (flip-flops/puertos) no cumplen el setup.                                                                                         |
| **Total Number of Endpoints**   | Cuántos caminos de setup fueron analizados en total.                                                                                               |

## Hold (tiempo de mantenimiento)

### ¿Qué mide?

Verifica que el dato se **mantenga estable un tiempo mínimo después** del flanco de reloj que lo capturó, para que el flip-flop no capture por error el _próximo_ dato que ya viene en camino (demasiado rápido).

### Ejemplo en palabras

Siguiendo la analogía del examen: el **hold time** es como decir "una vez que sonó el timbre, no podés tocar el examen durante 1 segundo más, para que el profesor termine de agarrarlo bien". Si movés el examen antes de ese segundo, el profesor podría llevarse una hoja equivocada o una mezcla de dos exámenes: **violación de hold**.

Una diferencia clave con setup: **el hold no depende de la frecuencia del reloj**. Podés bajar la frecuencia todo lo que quieras y una violación de hold sigue estando ahí, porque es un problema de que el dato "nuevo" llega demasiado rápido después del flanco, no de cuánto dura el período.

### Métricas asociadas

| Métrica                         | Significado                                      |
| ------------------------------- | ------------------------------------------------ |
| **WHS** (Worst Hold Slack)      | El peor slack de _hold_ entre todos los caminos. |
| **THS** (Total Hold Slack)      | Suma de todos los slacks negativos de hold.      |
| **Number of Failing Endpoints** | Cuántos endpoints violan el hold.                |
| **Total Number of Endpoints**   | Cuántos caminos de hold fueron analizados.       |

---

## Pulse Width (ancho de pulso)

### ¿Qué mide?

Verifica que las señales de reloj (y algunas señales de control como reset/enable internos) se mantengan en **alto o en bajo el tiempo mínimo necesario** para que la lógica interna del flip-flop funcione correctamente. Esto depende de las características físicas del silicio, no de tu lógica.

### Ejemplo en palabras

Es como un interruptor de luz que necesita quedarse presionado al menos medio segundo para que el circuito "note" que lo apretaste. Si lo tocás y soltás en una fracción de segundo demasiado corta, el circuito puede no "engancharlo" bien: **violación de pulse width**.

### Métricas asociadas

| Métrica                                     | Significado                                                                                         |
| ------------------------------------------- | --------------------------------------------------------------------------------------------------- |
| **WPWS** (Worst Pulse Width Slack)          | El peor slack entre todos los anchos de pulso analizados (clocks, resets síncronos internos, etc.). |
| **TPWS** (Total Pulse Width Negative Slack) | Suma de los slacks negativos de pulse width.                                                        |
| **Number of Failing Endpoints**             | Endpoints que violan el ancho mínimo de pulso.                                                      |
| **Total Number of Endpoints**               | Total de endpoints analizados para pulse width.                                                     |

Este chequeo depende directamente de tu `create_clock` (define el período y por lo tanto la duración de cada semiciclo), por eso es el único que dio un valor numérico (4.500 ns) en tu diseño aunque no tuvieras `set_input_delay`/`set_output_delay`.

## ¿Por qué a veces las métricas dan "inf"?

Como vimos en tu caso puntual: Setup y Hold necesitan que existan **caminos con un límite de tiempo definido** para poder comparar contra algo. Esto pasa quando hay:

- Caminos **registro → registro** (dentro del mismo reloj), que Vivado siempre puede analizar automáticamente, **o**
- Caminos **puerto de entrada → registro** / **registro → puerto de salida**, pero **solo si definiste** `set_input_delay` / `set_output_delay` en el XDC.

Si tu diseño no tiene caminos reg-a-reg (por ejemplo, porque la lógica entre registros es puramente combinacional y va directo a un puerto de salida, como tu ALU), y tampoco definiste delays de entrada/salida, Vivado no tiene contra qué comparar el timing real → resultado: **slack "infinito"**, que no es un error, sino la ausencia de una restricción que comparar.

## Cómo solucionar violaciones de timing

### 6.1 Violaciones de Setup (WNS negativo)

El dato llega tarde. Las estrategias típicas, de más simple a más compleja:

1. **Bajar la frecuencia del reloj** (aumentar el período en `create_clock`). Es la solución más rápida si tu aplicación lo permite.
2. **Simplificar la lógica combinacional** entre registros: menos niveles de compuertas = menos retardo.
   - Ejemplo: si tenés una suma de 32 bits seguida de una comparación y un multiplexor, todo en el mismo ciclo, separalo (pipeline) en dos ciclos de reloj.
3. **Agregar pipelining**: insertar registros intermedios para partir un camino largo en varios más cortos.
4. **Revisar el "fan-out"** (cuántas cargas maneja una misma señal): demasiadas cargas ralentizan la señal. Se puede duplicar la lógica que la genera (replicación) para repartir la carga.
5. **Ajustar las restricciones de floorplanning** (ubicación física) si el problema es que la señal viaja muy lejos dentro del chip — se puede usar `PBLOCK` para acercar la lógica relacionada.
6. **Revisar si el timing pedido es realista**: a veces el problema es que se pidió una frecuencia que la lógica simplemente no puede alcanzar con los recursos actuales del diseño.

### 6.2 Violaciones de Hold (WHS negativo)

El dato "nuevo" llega demasiado rápido. Importante: **nunca se soluciona bajando la frecuencia del reloj** (el hold no depende del período). Se soluciona:

1. **Agregando retardo intencional** en el camino que viola el hold (Vivado suele insertar buffers automáticamente durante la implementación para esto).
2. **Dejando que Vivado re-optimice el routing**: muchas veces alcanza con volver a correr Implementation, ya que el motor de optimización intenta resolver hold automáticamente después de resolver setup.
3. **Revisar sesgo de reloj (clock skew)** entre el flip-flop de origen y el de destino: si están muy separados físicamente, el reloj puede llegar a distintos tiempos a cada uno y provocar hold. Ayuda usar buffers de reloj balanceados (BUFG) y evitar rutas de reloj no estándar.
4. Si el problema persiste, a veces se debe **repensar la arquitectura** del camino específico (por ejemplo, evitar caminos combinacionales de 0 niveles de lógica entre dos registros con reloj derivado).

### 6.3 Violaciones de Pulse Width (WPWS negativo)

1. **Revisar el `create_clock`**: un `-waveform` mal definido (por ejemplo, un duty cycle muy desparejo) puede generar semiciclos más cortos que el mínimo que soporta la FPGA.
2. **Evitar generar relojes o resets con lógica combinacional** ("glitches" pueden generar pulsos angostos no intencionales). Usar siempre **buffers de reloj dedicados** (`BUFG`, `MMCM`, `PLL`) en vez de señales de reloj "hechas a mano" con compuertas.
3. Si el pulso corto es de una señal de reset/enable interna, **agregar un pequeño registro sincronizador** que asegure una duración mínima antes de propagarla.

### 6.4 Cuando el problema es la falta de restricciones (como en tu caso)

Si lo que ves es "inf" porque faltan `set_input_delay` / `set_output_delay`, y necesitás un análisis más realista:

```tcl
# Ejemplo: los switches/botones tardan un tiempo típico en estabilizarse
# después del flanco de reloj anterior
set_input_delay -clock sys_clk_pin 2.0 [get_ports {i_datos[*] i_abc[*] i_reset}]

# Ejemplo: los LEDs no tienen un requisito estricto, pero se puede modelar
# un tiempo de propagación razonable hacia el "mundo exterior"
set_output_delay -clock sys_clk_pin 2.0 [get_ports {o_led[*] o_zero o_overflow}]
```

Esto le da a Vivado un punto de referencia real contra el cual medir el slack, en vez de dejar esos caminos sin restricción.

## Tabla resumen rápida

| Métrica                   | Depende de la frecuencia | Qué revisar si falla                                      |
| ------------------------- | ------------------------ | --------------------------------------------------------- |
| WNS / TNS (Setup)         | Sí                       | Simplificar lógica, pipeline, bajar frecuencia            |
| WHS / THS (Hold)          | No                       | Buffers de retardo, revisar skew de reloj, re-implementar |
| WPWS / TPWS (Pulse Width) | Sí (del período)         | Revisar `create_clock`, usar buffers de reloj dedicados   |

---

## Regla general para interpretar el reporte

1. **Primero mirá los "Failing Endpoints".** Si es 0 en las tres categorías, tu diseño cumple el timing definido — aunque WNS/WHS muestren `inf` por falta de restricciones de I/O, eso no es una falla, es simplemente "no analizado en ese aspecto".
2. **Si hay fallos, mirá el WNS/WHS primero** (el peor caso) para saber cuán grave es, y el **TNS/THS** para saber si es un problema aislado o generalizado.
3. **Setup se arregla dándole más tiempo al dato** (menos lógica, más ciclos, menor frecuencia). **Hold se arregla dándole más retardo al dato** (nunca bajando la frecuencia).
