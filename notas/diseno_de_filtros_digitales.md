# Diseño de filtros digitales: la receta general

Hasta ahora viste **cómo implementar** un filtro cuyos coeficientes ya tenés. Esto es lo que falta: **cómo obtener esos coeficientes** a partir de lo que querés que haga el filtro. El proceso tiene siempre la misma secuencia de pasos.

---

## 1. Flujo general

1. **Especificar** qué debe hacer el filtro.
2. **Elegir FIR o IIR.**
3. **Elegir un método** de diseño y estimar el orden.
4. **Calcular los coeficientes.**
5. **Verificar** que cumple las especificaciones.
6. **Elegir la estructura** de implementación.
7. **Cuantizar** los coeficientes y verificar de nuevo.

Si el paso 5 o el 7 falla, se vuelve atrás: se sube el orden, se cambia el método o se cambia la estructura.

---

## 2. Paso 1: especificaciones

Para un pasabajos (los demás tipos se definen de forma análoga) se especifica:

| Parámetro | Significado |
|---|---|
| $\omega_p$ | Frecuencia de borde de la banda de paso |
| $\omega_s$ | Frecuencia de borde de la banda de rechazo |
| $\delta_p$ (o $A_p$ en dB) | Rizado máximo permitido en la banda de paso |
| $\delta_s$ (o $A_s$ en dB) | Atenuación mínima en la banda de rechazo |

La zona entre $\omega_p$ y $\omega_s$ es la **banda de transición**. Cuanto más angosta y más exigente sea la atenuación, mayor es el orden necesario.

Las frecuencias en Hz se pasan a rad/muestra con $\omega = 2\pi f / f_s$.

---

## 3. Paso 2: FIR o IIR

| | FIR | IIR |
|---|---|---|
| Fase lineal | Sí, con coeficientes simétricos | No (solo aproximada) |
| Estabilidad | Siempre estable | Hay que garantizarla (polos dentro de la circunferencia unidad) |
| Orden para las mismas especificaciones | Alto | Mucho menor |
| Costo de cómputo | Mayor | Menor |
| Sensibilidad a la cuantización | Baja | Alta si el orden es alto |

Regla práctica: **si importa la fase lineal, FIR; si importa la eficiencia, IIR.**

---

## 4. Diseño de FIR

### 4.1 Método de ventanas

**Idea:** se parte del filtro ideal, que tiene respuesta al impulso infinita, y se lo trunca con una ventana.

**Pasos:**

1. Elegir la frecuencia de corte, a mitad de la banda de transición: $\omega_c = \dfrac{\omega_p + \omega_s}{2}$.
2. Elegir la ventana y el largo $M$ según la atenuación $A_s$ pedida (tabla de abajo).
3. Calcular la respuesta al impulso ideal, **desplazada** $\alpha = \frac{M-1}{2}$ para hacerla causal:

$$
h_d[n] = \frac{\sin\left(\omega_c\,(n-\alpha)\right)}{\pi\,(n-\alpha)}, \qquad h_d[\alpha] = \frac{\omega_c}{\pi}
$$

4. Multiplicar por la ventana: $h[n] = h_d[n]\cdot w[n]$, para $0 \le n \le M-1$.
5. Normalizar para ganancia unitaria en continua: dividir por $\sum h[n]$.

El desplazamiento $\alpha$ es lo que da la **simetría** $h[n] = h[M-1-n]$ y por lo tanto la fase lineal con retardo $\frac{M-1}{2}$.

**Elección de ventana:**

| Ventana | Atenuación mínima en la banda de rechazo |
|---|---|
| Rectangular | ≈ 21 dB |
| Hann | ≈ 44 dB |
| Hamming | ≈ 53 dB |
| Blackman | ≈ 74 dB |

Cuanto más atenúa la ventana, más ancha resulta la banda de transición para el mismo $M$.

**Ventana de Kaiser.** Tiene un parámetro $\beta$ que se ajusta para lograr justo la atenuación pedida, y una fórmula para estimar el orden:

$$
\text{orden} \approx \frac{A_s - 8}{2{,}285\,\Delta\omega}, \qquad \Delta\omega = \omega_s - \omega_p
$$

**Ejemplo.** Pasabajos con $\omega_c = \pi/4$, $M = 7$, ventana de Hamming.

- $\alpha = 3$.
- Respuesta ideal desplazada: $h_d = \{0{,}0750;\ 0{,}1592;\ 0{,}2251;\ 0{,}2500;\ 0{,}2251;\ 0{,}1592;\ 0{,}0750\}$.
- Ventana de Hamming, $w[n] = 0{,}54 - 0{,}46\cos\frac{2\pi n}{M-1}$: $\ \{0{,}08;\ 0{,}31;\ 0{,}77;\ 1;\ 0{,}77;\ 0{,}31;\ 0{,}08\}$.
- Producto: $\{0{,}0060;\ 0{,}0494;\ 0{,}1733;\ 0{,}2500;\ 0{,}1733;\ 0{,}0494;\ 0{,}0060\}$.
- Suma $= 0{,}7074$. Dividiendo por la suma queda $h = \{0{,}0085;\ 0{,}0698;\ 0{,}2450;\ 0{,}3534;\ 0{,}2450;\ 0{,}0698;\ 0{,}0085\}$, que suma 1.

El resultado es simétrico, así que tiene fase lineal con retardo de 3 muestras, y se puede implementar con la forma directa de fase lineal.

### 4.2 Muestreo en frecuencia

Se fija la respuesta deseada en $M$ puntos equiespaciados de la frecuencia y se obtienen los $h[n]$ con la transformada inversa (DFT inversa). Es simple, pero se controla poco el rizado fuera de los puntos muestreados. Se mejora dejando valores de transición en el borde de la banda.

### 4.3 Parks-McClellan (equiripple, óptimo)

Se plantea la aproximación como un problema de optimización: minimizar el **error máximo ponderado** entre la respuesta deseada y la obtenida. El algoritmo de Remez lo resuelve de forma iterativa.

Para un orden dado, es el diseño con la menor desviación máxima posible, y el error se reparte con rizado uniforme en las bandas. Es el método estándar cuando se quiere el orden mínimo para una especificación. Se parametriza con las bandas, la respuesta deseada y un peso por banda.

---

## 5. Diseño de IIR

### 5.1 Método más usado: prototipo analógico + transformación bilineal

**Idea:** hay una teoría clásica muy desarrollada de filtros analógicos (Butterworth, Chebyshev, elíptico). Se diseña el analógico y se lo convierte en digital.

**Pasos:**

1. **Predistorsión de frecuencias.** La transformación bilineal comprime el eje de frecuencias, así que las frecuencias digitales se deben pasar a analógicas con:

$$
\Omega = \frac{2}{T}\tan\left(\frac{\omega}{2}\right)
$$

   Se aplica a $\omega_p$ y $\omega_s$ (y se toma $T=2$ si no importa la escala de tiempo).

2. **Elegir la aproximación** y calcular el orden $N$ con las frecuencias predistorsionadas.

| Aproximación | Banda de paso | Banda de rechazo | Orden para la misma especificación |
|---|---|---|---|
| Butterworth | Plana | Monótona | Mayor |
| Chebyshev I | Con rizado | Monótona | Intermedio |
| Chebyshev II | Plana | Con rizado | Intermedio |
| Elíptico | Con rizado | Con rizado | El menor |

3. **Obtener $H_a(s)$**, el filtro analógico (polos y, si corresponde, ceros).
4. **Aplicar la transformación bilineal**, reemplazando:

$$
s = \frac{2}{T}\,\frac{1 - z^{-1}}{1 + z^{-1}}
$$

   y se obtiene $H(z)$.
5. **Factorizar en biquads** para implementarlo en cascada.

**Ejemplo.** Pasabajos Butterworth de primer orden con $\omega_c = \pi/4$.

- Predistorsión (con $T=2$): $\Omega_c = \tan(\pi/8) \approx 0{,}4142$.
- Prototipo analógico: $H_a(s) = \dfrac{\Omega_c}{s + \Omega_c}$.
- Bilineal con $s = \dfrac{1 - z^{-1}}{1 + z^{-1}}$:

$$
H(z) = \frac{\Omega_c (1 + z^{-1})}{(1 + \Omega_c) + (\Omega_c - 1)\, z^{-1}} = \frac{0{,}2929\,(1 + z^{-1})}{1 - 0{,}4142\, z^{-1}}
$$

- Verificación: en continua $H(1) = \dfrac{0{,}2929 \cdot 2}{1 - 0{,}4142} = 1$ ✓.

### 5.2 Otros métodos

- **Invarianza al impulso:** se toma $h[n] = h_a(nT)$. Mantiene la forma de la respuesta al impulso pero produce aliasing, así que no sirve para pasaaltos.
- **Ubicación directa de polos y ceros:** se colocan a mano en el plano $z$ según la respuesta que se quiere. Es el caso del notch de la sección anterior.
- **Transformaciones de frecuencia:** a partir de un pasabajos se obtienen pasaaltos, pasabanda y rechazabanda con cambios de variable en $s$ o en $z$.

---

## 6. Pasos 5, 6 y 7: verificar, estructurar y cuantizar

### Verificar

Calcular la respuesta en frecuencia $H(e^{j\omega})$ y comprobar que cumple las cuatro especificaciones ($\omega_p$, $\omega_s$, rizado, atenuación). Si no cumple, se sube el orden o se cambia de método.

### Elegir la estructura

| Tipo de filtro | Estructura habitual |
|---|---|
| FIR de fase lineal | Forma directa de fase lineal (la mitad de multiplicaciones) |
| FIR general | Directa, o transpuesta si importa la velocidad de reloj |
| IIR de orden alto | **Cascada de biquads** (forma directa II o transpuesta) |
| IIR con polos independientes | Paralelo |
| Cuando interesan los coeficientes de reflexión | Celosía |

Para IIR, la forma directa de orden alto se evita porque los polos se vuelven muy sensibles a pequeños cambios en los coeficientes.

### Cuantizar y volver a verificar

Los coeficientes ideales tienen precisión infinita, pero en el hardware se redondean a un número finito de bits. Eso mueve los ceros y los polos, y puede:

- empeorar la atenuación en la banda de rechazo,
- en un IIR, mover un polo fuera de la circunferencia unidad (inestable),
- en un FIR de fase lineal, romper la simetría (salvo que la estructura la preserve, como en las secciones de cuarto orden simétricas).

Por eso la verificación se repite con los **coeficientes cuantizados**.

---

## 7. Herramientas

No se calculan a mano en la práctica:

| Tarea | MATLAB | Python (`scipy.signal`) |
|---|---|---|
| FIR por ventanas | `fir1` | `firwin` |
| Orden de Kaiser | `kaiserord` | `kaiserord` |
| FIR equiripple | `firpm` | `remez` |
| Orden IIR | `buttord`, `cheb1ord`, `ellipord` | `buttord`, `cheb1ord`, `ellipord` |
| IIR clásico | `butter`, `cheby1`, `ellip` | `butter`, `cheby1`, `ellip` |
| A biquads | `tf2sos`, `zp2sos` | `tf2sos`, `zpk2sos` |
| Respuesta en frecuencia | `freqz` | `freqz` |

Conviene pedir el IIR directamente en formato de secciones de segundo orden (SOS) para evitar los problemas numéricos de la forma directa.

---

## Resumen

1. Especificar: $\omega_p$, $\omega_s$, rizado y atenuación.
2. Elegir FIR (fase lineal, siempre estable) o IIR (menor orden).
3. FIR: ventanas, muestreo en frecuencia o Parks-McClellan. IIR: prototipo analógico + bilineal.
4. Estimar el orden y calcular los coeficientes.
5. Verificar la respuesta en frecuencia.
6. Elegir la estructura (cascada de biquads para IIR, directa de fase lineal para FIR simétrico).
7. Cuantizar y verificar de nuevo.
