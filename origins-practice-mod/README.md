# Death Barrier Practice — BO2 Origins / Plutonium T6 PC

Mod de práctica para partida privada, ejecutado por el anfitrión. Incluye bytecode compilado y fuente GSC. No sustituye archivos originales del mapa.

Revisión visual: las dos líneas de ayuda pasan de fontscale 0,9 (observadas gigantes dentro de BO2) a 1,0. Se evita el valor inferior a 1 que produjo el fallo visual. Los cuadros de la baliza pasan de 10×10 a 2×2 y su opacidad de 0,8 a 0,45. La corrección visual aún debe confirmarse en juego; la lógica del monitor no cambia.

## Instalación

1. Extrae `Origins-DeathBarrier-Practice.zip`.
2. Copia la carpeta **t6** del ZIP dentro de `%LOCALAPPDATA%\Plutonium\storage\`, combinando carpetas. El archivo final debe quedar en:

   `%LOCALAPPDATA%\Plutonium\storage\t6\scripts\zm\zm_tomb\deathbarrier_practice.gsc`

   También puedes ejecutar `install.ps1` desde PowerShell; preserva una copia si ya existe ese archivo. La instalación manual funciona sin cambiar la política de ejecución de PowerShell. Si usas un directorio de almacenamiento personalizado, copia el archivo en su carpeta equivalente.
3. Inicia una partida privada de Origins (`zm_tomb`) como anfitrión. Si ya estabas jugando, reinicia el mapa. No basta con copiarlo durante una partida.
4. Debe aparecer `DB PRACTICE - SONDEO DE AREA` al entrar al juego. Si no aparece, revisa la consola: un error `unknown function replacefunc`, de precache o de HUD requiere adaptar la versión/loader; no uses un cronómetro independiente como sustituto de sincronización.

## Uso

- El reloj muestra **segundos:centésimas**, desde `0:00` hasta el límite `3:00`, y se reinicia al comenzar la siguiente espera real del monitor. No son minutos. El HUD se actualiza cada 0,05 s; por resolución de frames puede pasar de `2:95` a `0:00` sin dibujar exactamente `3:00`.
- **Verde:** tiempo entre consultas del monitor. **Morado:** destello de 0,15 s después de una consulta real, para hacerla visible. El destello no convierte toda esa duración en una ventana activa de daño.
- **Morado + INFRACCION DETECTADA:** se tomó la rama de sanción, que espera 0,5 s y luego solicita daño. El reloj queda en `3:00` durante esa espera. Volver a zona permitida no cancela esa rama.
- **Gris:** inicialización, espectador o la condición de migración que omite comprobaciones.
- `POSICION` muestra la evaluación geométrica actual: life brush, kill brush, fuera de volumen habilitado o dentro. Es independiente del color de fase y no invoca repetidamente callbacks de mapa.
- Para poner una referencia visual, **apunta al suelo y pulsa USAR mientras mantienes apuntado**. Aparecen nueve cuadrados anclados en ese punto que cambian verde/morado con tu monitor. Repite para moverlos. Los botones conservan sus acciones normales: evita hacerlo mirando un interactuable que no quieras usar.

La baliza es una marca visual de práctica, con cuadrados de HUD en el mundo; no es un decal que repinte el suelo ni el contorno exacto de una barrera. No tiene colisión y sólo la ve su jugador. Sin las entidades/colisiones del mapa no se inventan los límites de la barrera junto a la pieza del cetro eléctrico. Colócala donde quieras practicar.

**Verde no significa inmunidad.** Estar fuera de zona al llegar una consulta sigue siendo sancionable. Los `trigger_hurt` nativos, pisotones, tanque y otras fuentes de daño no siguen necesariamente este reloj.

## Cómo se sincroniza

`init()` usa `replacefunc` de Plutonium para sustituir `maps\mp\zombies\_zm::player_out_of_playable_area_monitor` por una copia instrumentada de la lógica de producción del checkout analizado. El timestamp se escribe inmediatamente antes de cada `wait 3`, en el propio monitor. No se intenta adivinar su fase a partir de cuándo apareció el HUD. El desfase inicial de `0.15 * characterindex` se conserva.

Se conservan las consultas, callback opcional de mapa, omisiones de espectador/migración, estadísticas, risa, espera de 0,5 s, daño, pérdida de vidas, bleedout y fin de partida. No se añade espera al monitor para mostrar los colores. Tras una infracción, el siguiente intervalo empieza después de la espera de sanción: no se fuerza un módulo artificial de 3 s desde el inicio del mapa. Se omiten los bloques dev del dump.

El hook afecta las llamadas nuevas desde la carga/reinicio de mapa; no promete enganchar un hilo ya activo al inyectarlo a mitad de partida. No lo combines con otro mod que reemplace la misma función. Una actualización del cliente puede tener una implementación distinta: ésta está basada en el GSC decompilado del repositorio analizado.

## Desinstalar

Elimina únicamente `deathbarrier_practice.gsc` de la ruta indicada y reinicia el mapa, o usa `uninstall.ps1`. No se alteran scripts base ni se persisten flags de acceso por este mod. Las copias `.backup-*`, si existen, se conservan para restauración manual.

## Validación y límites

Comprobado aquí: compilación T6 PC, cabecera de bytecode, descompilación, recompilación y comparación del flujo de producción con el monitor original eliminando sólo instrumentación y namespaces equivalentes. No se ha ejecutado Plutonium ni BO2 en esta máquina; instalación PowerShell, carga de `replacefunc`, aspecto de las balizas, centésimas y sincronización observada requieren prueba en juego. Una compilación correcta no valida APIs adicionales de Plutonium en runtime.

Primera prueba: estando en zona permitida, el reloj debe reiniciarse aproximadamente cada 3 s con destello morado. Luego, en tu punto de práctica, compara el aviso `POSICION` y la risa/sanción con la fase morada. Una infracción detectada debe mantener el aviso durante la espera de 0,5 s. Si el HUD desaparece inesperadamente o la consola muestra errores, retira el mod y reinicia el mapa.

Para reconstruir en este workspace:

```sh
python3 /workspace/origins-practice-mod/verify_monitor.py
python3 /workspace/origins-practice-mod/build.py
```

Puedes indicar `build.py --compiler /ruta/a/gsc-tool` para otra instalación. Los binarios T6 de salida usan `scripts/zm/zm_tomb/deathbarrier_practice.gsc` como nombre interno.
