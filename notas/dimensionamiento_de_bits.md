# Cálculo del ancho de bits en filtros FIR e IIR

*Notas de implementación · aritmética de punto fijo*

Cómo dimensionar los registros de un filtro digital para que nunca haya overflow, sin importar la entrada — con dos ejemplos simples resueltos paso a paso antes de aplicarlo a un caso real.

---

Cuando un filtro digital se implementa en hardware con números enteros de ancho fijo (por ejemplo, 8 bits para la entrada), hay que decidir cuántos bits necesitan los registros internos y de salida. Si el ancho elegido es muy chico, el filtro puede *desbordar* (overflow) y el resultado se corrompe. Si es innecesariamente grande, se desperdicia área/recursos de hardware. Este documento explica el método para calcular el ancho **exacto y garantizado** — lo que se conoce como dimensionamiento *full-resolution*: el registro nunca desborda, para cualquier secuencia de entrada posible.

**Glosario**

- **$N_x$** — ancho en bits de la entrada (con signo, complemento a 2).
- **$X_{max}$** — magnitud máxima de la entrada, por convención $X_{max}=2^{N_x-1}$.
- **$b_k$** — coeficientes de la parte no recursiva (feedforward) del filtro.
- **$a_j$** — coeficientes de la parte recursiva / realimentada (feedback), solo existen en un IIR.
- **$N_y$** — ancho en bits que necesita la salida / los registros de estado, para que nunca haya overflow.

## 1. Dos reglas de aritmética con signo

Antes de mirar filtros completos, dos reglas de complemento a 2 alcanzan para entender casi todo lo que sigue:

### Regla A — sumar o restar

Sumar (o restar) dos números de $N$ bits puede necesitar hasta $N+1$ bits en el resultado. El peor caso ocurre cuando ambos operandos están en su valor extremo y con el signo que hace que se sumen en magnitud, en vez de cancelarse.

### Regla B — multiplicar por una constante

- Si la constante es una **potencia de 2**, $c=2^n$, la "multiplicación" es un corrimiento de bits, y el sentido depende del signo del exponente:

  | Exponente $n$ | Constante | Operación |
  |---|---|---|
  | positivo ($n\ge 1$) | 2, 4, 8, 16... | corrimiento a la **izquierda** de $n$ bits |
  | cero | 1 | sin corrimiento |
  | negativo | 0,5, 0,25, 0,125... | corrimiento a la **derecha** de $\lvert n\rvert$ bits |

  Un corrimiento a la derecha nunca necesita bits nuevos arriba (solo reduce la magnitud). Uno a la izquierda sí necesita $n$ bits extra arriba para no perder información — pero de forma determinística: no depende de los valores de la señal, solo del coeficiente.

- Si la constante es **genérica** (por ejemplo 0,6875), hace falta un multiplicador real, y el resultado crece a $N+M$ bits ($N$ del dato, $M$ del coeficiente representado en punto fijo). Veamos por qué con un ejemplo.

> **Ejemplo paso a paso — por qué N+M**
>
> Primero, la intuición con números chicos y sin signo. Multiplicando el mayor número de $N=4$ bits por el mayor número de $M=3$ bits:
>
> $$ \underbrace{15}_{4\text{ bits}} \;\times\; \underbrace{7}_{3\text{ bits}} \;=\; 105 $$
>
> $105$ en binario es `1101001`: exactamente 7 bits, es decir $N+M=4+3=7$. Tiene sentido: el mayor número de $N$ bits está cerca de $2^N$, el de $M$ bits cerca de $2^M$, y el producto queda cerca de $2^N\times 2^M=2^{N+M}$ — justo el límite que $N+M$ bits pueden representar.
>
> Ahora con un coeficiente de filtro real. Supongamos $h=0{,}6875$, representado en punto fijo con $M=5$ bits (1 bit de signo + 4 bits fraccionarios, formato $S(5,4)$):
>
> $$ h = 0{,}6875 = 0{,}1011_2 \quad\Rightarrow\quad \texttt{0\,1011} \;\;(M=5\text{ bits}) $$
>
> Con una entrada $x[n]=100$ de $N_x=8$ bits, el hardware en realidad multiplica los enteros "crudos", ignorando por un momento dónde está la coma (el $11$ sale de leer `01011` como entero):
>
> $$ 100 \times 11 = 1100 $$
>
> Ese $1100$ es el resultado real si le corremos la coma 4 lugares a la derecha (porque $h$ tenía 4 bits fraccionarios): $1100/16=68{,}75$, que es justamente $100\times0{,}6875$. Siguiendo la misma regla práctica de recién, ese producto puede necesitar hasta $N_x+M=8+5=13$ bits.
>
> Un detalle extra, propio del punto fijo: el resultado no solo crece en bits totales, sino que además queda con **4 bits fraccionarios** (los que traía $h$). Si después querés volver a un formato entero — como hicimos con los corrimientos de 0,5 y 0,25 en el filtro IIR — hay que truncar o redondear esos bits fraccionarios, con la misma pérdida de precisión que ya vimos, solo que acá son 4 bits en vez de 1.

## 2. Filtros FIR — el caso sin realimentación

Un filtro FIR (respuesta al impulso finita) tiene la forma general:

$$ y[n] = \sum_{k=0}^{M-1} b_k \, x[n-k] $$

La salida `y` nunca depende de sí misma — solo de valores pasados de la entrada. Eso hace que el peor caso posible sea fácil de imaginar: *todas las muestras de entrada en su valor máximo, alineadas en signo para sumar en vez de cancelarse.* Con eso:

$$ |y[n]| \le \left(\sum_k |b_k|\right) \cdot X_{max} $$

> **FÓRMULA — ancho de salida de un FIR**
>
> $$ N_y = N_x + \left\lceil \log_2\!\left(\sum_k |b_k|\right) \right\rceil $$

> **Ejemplo paso a paso**
>
> Tomemos un FIR chico e inventado, para ver qué dice la fórmula con números concretos:
>
> $$ y[n] = 2\,x[n] + 3\,x[n-1] - x[n-2] $$
>
> Elegimos $N_x = 4$ bits para la entrada (números chicos, fáciles de seguir a mano). Con 4 bits con signo, el rango es $[-8, 7]$, y usamos $X_{max}=2^{4-1}=8$ como magnitud de referencia.
>
> **Paso 1 — sumar los $|b_k|$:** $|2|+|3|+|-1| = 6$.
>
> **Paso 2 — aplicar la fórmula:**
>
> $$ N_y = 4 + \lceil \log_2 6 \rceil = 4 + \lceil 2{,}585 \rceil = 4 + 3 = 7 \text{ bits} $$
>
> **Paso 3 — verificarlo con un caso extremo real:** si $x[n]=-8$, $x[n-1]=-8$, $x[n-2]=7$ (el valor que, multiplicado por el coeficiente $-1$, también empuja hacia negativo):
>
> $$ y[n] = 2(-8) + 3(-8) - (7) = -16 -24 -7 = -47 $$
>
> Con 7 bits el rango representable es $[-64, 63]$, así que $-47$ entra perfectamente (y de hecho sobra margen: la cota teórica $6\times8=48$ es una cota *segura*, aunque el peor caso real, $-47$, queda un poco por debajo por la asimetría del rango con signo).

## 3. Filtros IIR — cuando aparece la realimentación

Un filtro IIR (respuesta al impulso infinita) agrega términos que dependen de salidas pasadas:

$$ y[n] = \sum_k b_k \, x[n-k] \;+\; \sum_j a_j \, y[n-j] $$

Acá el razonamiento del FIR no alcanza. El motivo: $y[n-1]$ y $y[n-2]$ no son valores "libres" como las muestras de entrada — dependen de la propia salida en instantes anteriores. Si uno intenta propagar "+1 bit por cada sumador" a través del lazo de realimentación, el ancho requerido no converge: crece indefinidamente.

La forma correcta de resolverlo es plantear una **ecuación de punto fijo**: suponer que existe una cota $M$ tal que $|y[n]| \le M$ siempre, y comprobar que sea consistente con la propia ecuación del filtro:

$$ M \;\le\; \left(\sum_k|b_k|\right)X_{max} \;+\; \left(\sum_j|a_j|\right) M $$

Despejando $M$:

$$ M = \frac{\sum_k|b_k|}{1-\sum_j|a_j|}\; X_{max} \qquad \text{(válido solo si } \textstyle\sum_j|a_j| < 1 \text{)} $$

> **FÓRMULA — ancho de salida de un IIR**
>
> $$ N_y = N_x + \left\lceil \log_2\!\left(\frac{\sum_k|b_k|}{1-\sum_j|a_j|}\right) \right\rceil $$

> **Nota:** La condición $\sum_j|a_j| < 1$ no es casualidad: es también una condición **suficiente** de estabilidad del filtro (más simple de verificar que la condición exacta sobre los polos de $H(z)$). En otras palabras: un filtro con más margen de estabilidad necesita menos bits para garantizar que nunca desborda.

> **Ejemplo paso a paso**
>
> Un IIR bien simple, con un solo término de realimentación:
>
> $$ y[n] = x[n] + x[n-1] + 0{,}5\,y[n-1] $$
>
> Otra vez, $N_x=4$ bits, $X_{max}=8$.
>
> **Paso 1 — sumar los coeficientes feedforward:** $\sum|b_k| = |1|+|1| = 2$.
>
> **Paso 2 — sumar los coeficientes de realimentación:** $\sum|a_j| = 0{,}5$.
>
> **Paso 3 — plantear la ecuación de punto fijo con números:**
>
> $$ M \le 2\cdot 8 + 0{,}5\,M = 16 + 0{,}5\,M \;\;\Rightarrow\;\; 0{,}5\,M = 16 \;\;\Rightarrow\;\; M = 32 $$
>
> **Paso 4 — convertir a bits:**
>
> $$ N_y = 4 + \lceil \log_2 4 \rceil = 4 + 2 = 6 \text{ bits} $$
>
> Con 6 bits, el rango con signo es $[-32, 31]$ — y $M=32$ entra justo en el límite negativo, sin desperdiciar ni un bit de más.

Un punto importante: $M=32$ no es un valor al que la salida "llega" después de cierta cantidad de muestras. Aplicando la entrada sostenida más agresiva posible ($x[n]=x[n-1]=8$ todo el tiempo, con $y[-1]=0$), la salida se acerca a 32 indefinidamente pero nunca lo cruza:

> **Gráfico:** $y[n]$ bajo la entrada sostenida más agresiva posible ($x[n]=x[n-1]=X_{max}=8$), partiendo de $y[-1]=0$. La curva sube rápido desde $y[0]=16$ y se acerca asintóticamente a la cota $M=32$ (línea punteada), alcanzando valores como $y[1]=24$, $y[2]\approx28$, $y[3]\approx30$... sin cruzarla nunca. Cada paso recorre la mitad de la distancia que le falta a $M=32$ — por eso lo persigue para siempre sin cruzarlo.

## 4. Aplicado al filtro real

Supongamos que deseamos calcular los bits de salida para el siguiente filtro, donde la entrada tiene 8 bits ($N_x = 8$):

$$ y[n] = x[n] - x[n-1] + x[n-2] + x[n-3] + 0{,}5\,y[n-1] + 0{,}25\,y[n-2] $$

Entonces con $N_x = 8$ bits de entrada ($X_{max}=128$), los mismos cuatro pasos dan:

| Cantidad | Valor |
|---|---|
| $\sum\lvert b_k\rvert$ (feedforward: 1, -1, 1, 1) | 4 |
| $\sum\lvert a_j\rvert$ (feedback: 0,5 y 0,25) | 0,75 |
| Ganancia peor-caso $\dfrac{\sum\lvert b_k\rvert}{1-\sum\lvert a_j\rvert}$ | $4/0{,}25 = 16$ |
| Bits extra $\lceil \log_2 16 \rceil$ | 4 |
| **$N_y = N_x + 4$** | **12 bits** |

## 5. Qué tan sensible es esto a la estabilidad

Dejando fijo $\sum\lvert b_k\rvert=4$ (como en nuestro filtro) y variando qué tan cerca de 1 está $\sum\lvert a_j\rvert$, el ancho requerido no crece de forma lineal — se dispara a medida que el filtro se acerca a la inestabilidad:

> **Gráfico:** bits extra necesarios $= \log_2\!\left(\dfrac{4}{1-\sum\lvert a_j\rvert}\right)$ en función de $\sum\lvert a_j\rvert$ (de 0 a 1). La curva es prácticamente plana hasta $\sum\lvert a_j\rvert\approx0{,}5$ (unos 2 bits extra) y luego se dispara: en $\sum\lvert a_j\rvert=0{,}75$ (marcado como "tu filtro") hacen falta 4 bits extra, y cerca de $\sum\lvert a_j\rvert=1{,}0$ la curva tiende a infinito.

Si esos mismos coeficientes hubieran sumado 0,95 en vez de 0,75, se necesitarían 6 bits extra en vez de 4. Este es el motivo por el que los filtros muy selectivos (por ejemplo, pasabanda angostos) — que necesitan polos muy cerca del círculo unitario — son más "caros" en términos de hardware: no solo por el diseño en sí, sino porque los registros necesitan mucho más margen para garantizar que nunca desborden.

## 6. Una salvedad para la vida real

> Lo que calculamos acá es el peor caso **absoluto y garantizado** — de ahí el nombre "full-resolution": nunca hay overflow, sin importar la entrada. En diseños industriales, esto muchas veces es más conservador de lo necesario (ese peor caso exacto es raro en una señal real), y se suele preferir aritmética *saturante* (clampear en vez de desbordar silenciosamente) combinada con un dimensionamiento basado en simulación con señales típicas, en vez de la cota matemática exacta. Para un ejercicio académico, la cota garantizada que vimos acá es el enfoque correcto.
