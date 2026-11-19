# Advanced Discovery Maps 2.1.0 RC1

**Cartografía, exploración y herramientas de terreno para Luanti**  
**Estado:** versión candidata experimental · **Motor probado:** Luanti 5.18.0 · **Juego utilizado en las pruebas:** Minetest Game

> **Este proyecto es una bifurcación (fork) de [Discovery Maps, de TomCon](https://content.luanti.org/packages/TomCon/discovery_maps/).** Conserva el objetivo de explorar un mundo y construir un mapa persistente, y amplía el sistema con nuevas capas cartográficas, herramientas de medición y utilidades para el jugador. No es una actualización oficial del mod original.

**[Código fuente y seguimiento de errores](https://github.com/TuxMatic99/advanced_discovery_maps)** · [Proyecto original](https://codeberg.org/TomCon/discovery_maps) · [Luanti](https://www.luanti.org/)

## ¿Qué distingue a esta versión del mod original?

El proyecto original **Discovery Maps** ya incluía mapas explorables con zonas no descubiertas, zoom, marcadores, puntos de referencia y exploración compartida mediante *Map Party*. Esas ideas y funcionalidades se reconocen aquí como parte de su base.

**Advanced Discovery Maps 2.1.0 RC1** incorpora o reelabora las siguientes áreas:

| Área | Discovery Maps original | Advanced Discovery Maps 2.1.0 RC1 |
| --- | --- | --- |
| Exploración persistente | Mapa que se descubre mientras juegas | Se conserva y se acompaña de un motor cartográfico progresivo opcional |
| Representación del terreno | Mapa coloreado de superficie | Capas **Natural**, **Relieve**, **Cavernas** y **Topografía mejorada** opcional |
| Rendimiento de generación | Cuadrantes generados durante la exploración | Lectura vertical configurable, cálculo por franjas y cachés de clasificación de nodos |
| Imágenes del mapa | Cuadrantes almacenados como imágenes | Solicitud y transferencia bajo demanda para los clientes, con confirmación y reintentos |
| Navegación | Zoom, desplazamiento y marcadores | Atlas rediseñado, centrado por clic, salto a coordenadas y marcador seleccionado |
| Medición | Referencias y navegación mediante marcadores | **Regla entre dos puntos**, rumbo, diferencias X/Z y siete unidades de distancia |
| Información ambiental | Exploración geográfica | Sensor de biomas, calor y humedad, HUD de información y reloj del mundo |
| Exploración móvil | Mapa principal | Minimapa HUD con brújula orientada y actualización controlada |
| Herramientas del mundo | Funciones cartográficas | Visión nocturna para cuevas y agua; varita Tuxmatic de excavación esférica por franjas |
| Idiomas | Idiomas del proyecto original | Catálogos `.tr` para nueve idiomas, con revisión de cobertura todavía en curso |

### Cuatro vistas cartográficas

- **Natural:** colores de materiales y superficies para reconocer el entorno.
- **Relieve:** interpretación de elevaciones y accidentes del terreno.
- **Cavernas:** representación de cavidades detectadas en el intervalo vertical de escaneo.
- **Topografía mejorada:** colores hipsométricos, sombreado y curvas de nivel; incluye diferenciación visual del agua y de la lava. Esta cuarta vista se genera **bajo demanda** cuando está habilitada.

**Nota sobre batimetría:** la representación de zonas sumergidas forma parte de las vistas de relieve/topografía. Una capa batimétrica completamente independiente sigue siendo una mejora prevista y **no se anuncia como implementada en RC1**.

## Inicio rápido

1. Instala Luanti **5.18.0** y un juego compatible. Las pruebas de esta candidata se han realizado con **Minetest Game**.
2. Instala este mod desde ContentDB cuando esté disponible, o coloca la carpeta del repositorio como `advanced_discovery_maps` dentro del directorio de mods de Luanti.
3. Activa **Advanced Discovery Maps** en la configuración de tu mundo y entra al juego.
4. Recibirás un **libro de mapa**; úsalo para abrir el Atlas. También puedes escribir `/map`.
5. Explora nuevos cuadrantes. Las imágenes tardarán en generarse la primera vez y se conservarán en el mundo para visitas posteriores.

**No es necesario crear otro mundo:** el mod mantiene sus datos de exploración en el almacenamiento del mundo y las imágenes cartográficas en `worlds/<mundo>/persistent_maps/`. **Haz un respaldo completo del mundo antes de actualizar una instalación anterior**, especialmente si ya tienes muchos cuadrantes explorados o utilizas la varita de excavación.

## Cómo utilizar el Atlas

En el Atlas puedes cambiar de capa, usar el zoom, centrarte en tu posición, explorar los cuadrantes descubiertos y administrar marcadores. Haz clic sobre un cuadrante visible para centrar la vista allí.

La herramienta de **navegación y regla** (también disponible mediante `/regla`) permite:

- Saltar a coordenadas **X/Z** sin teletransportar al personaje.
- Centrar el mapa en un marcador seleccionado.
- Elegir puntos **A** y **B** a partir de tu posición, marcadores, cuadrantes o coordenadas exactas.
- Calcular **distancia horizontal**, diferencias de X/Z y **rumbo**.
- Mostrar la distancia en metros, centímetros, kilómetros, pulgadas, pies, yardas o millas.

Se utiliza la convención **un bloque = un metro**. La distancia calculada es en línea recta sobre el plano X/Z: no considera desniveles ni obstáculos. Al elegir un cuadrante, se utiliza su **centro**; para medir con mayor precisión introduce coordenadas de bloques o utiliza marcadores.

Los sistemas de marcadores y **Map Party** permiten conservar destinos y compartir exploración según la configuración y los permisos del servidor.

## HUD y herramientas de exploración

**Biomas y reloj.** `/bioma` consulta el bioma actual; `/bioma hud` activa o desactiva su información en pantalla. `/reloj` muestra u oculta el reloj del juego. La frecuencia de actualización está controlada para evitar recalcular datos que no hayan cambiado.

**Minimapa.** `/map_movil on` muestra un pequeño mapa HUD mientras te desplazas; `/map_movil off` lo retira. Su brújula refleja la orientación del jugador.

**Visión nocturna.** `/nv` activa o desactiva iluminación temporal que permite orientarse en cuevas oscuras y bajo el agua. Utiliza emisores temporales con mecanismos de restauración. Su comportamiento frente a otros mods que alteran la iluminación debe seguir probándose.

**Varita Tuxmatic.** `/varita` entrega la herramienta a usuarios con el privilegio `give`. Para utilizar la excavación se necesita además `adm_excavate`. La varita excava regiones esféricas con radio configurable de **1 a 100 bloques**, repartiendo el trabajo entre pasos del servidor. Admite materiales comunes, incluida vegetación, y realiza comprobaciones de protección. Los bloques con inventarios o datos especiales pueden conservarse. La excavación mediante `VoxelManip` **no debe considerarse reversible automáticamente**.

Utiliza `/adm_wand_status` para consultar el estado de la excavación y `/adm_wand_cancel` para detenerla. Prueba primero radios pequeños y realiza copias de seguridad antes de trabajar en grandes regiones.

### Comandos principales

| Comando | Función |
| --- | --- |
| `/map` | Abrir el Atlas |
| `/regla` | Abrir navegación y medición |
| `/map_movil [on\|off]` | Mostrar u ocultar el minimapa |
| `/bioma` / `/bioma hud` | Consultar el bioma / alternar HUD |
| `/reloj [on\|off]` | Controlar el reloj del mundo |
| `/nv` | Alternar visión nocturna |
| `/markers` | Administrar marcadores |
| `/mapparty` | Consultar y gestionar exploración en equipo |
| `/actualizar_mapa <radio>` | Solicitar actualización de cuadrantes (sujeta a límites y enfriamiento) |
| `/varita` | Recibir la varita (privilegio `give`) |
| `/adm_wand_status` / `/adm_wand_cancel` | Consultar o cancelar excavación |
| `/flyspeed <n>` / `/runspeed <n>` / `/jumpheight <n>` | Ajustar movimientos según los permisos aplicables |
| `/map_ayuda` | Ver la ayuda de comandos del mod |

Las descripciones y permisos efectivos de cada comando se pueden consultar también con `/help <comando>`.

## Configuración recomendada

El modo de funcionamiento depende de las opciones de `minetest.conf`. **La siguiente configuración habilita explícitamente las funciones modernas**, algunas de las cuales no están activadas por defecto en esta revisión:

```ini
# Atlas y generación de mapas
adm_ui_modern = true
adm_progressive_tiles = true
adm_lazy_media = true
adm_scan_mode = balanced
adm_stripe_rows = 16

# Cuarta capa cartográfica (se genera cuando se solicita)
adm_topo_enabled = true
adm_topo_contour_interval = 25

# Información y minimapa
adm_walkmap_enabled = true
adm_walkmap_hz = 10
adm_info_hud_corner = top-left
adm_info_hud_font_scale = 1.25

# Diagnóstico: activarlo solo para medir tiempos
adm_profile_tiles = false

# Varita de excavación: trabajo distribuido
adm_wand_rows_per_step = 8
adm_wand_step_delay = 0.005
adm_wand_particles = true
```

**Perfiles de escaneo:** `light` limita más la búsqueda vertical y favorece el rendimiento, `balanced` ofrece un equilibrio y `full` intenta cubrir el intervalo vertical configurado. Los modos acotados pueden omitir cavernas muy profundas o elevaciones extremas. Reducir las filas por paso de la varita también puede suavizar pausas, a costa de aumentar la duración total de la operación.

La configuración indicada sirve como punto de partida, **no como garantía de ausencia de retrasos** en todos los equipos y mundos.

## Rendimiento: qué se midió y qué queda pendiente

En un benchmark sintético A/B de siete repeticiones por motor, P7-A redujo el tiempo de cálculo de píxeles un **18,0 %** en el escenario `balanced` de 33 × 33 y un **6,3 %** en el escenario `full` de 24 × 24. En las regresiones, las tres capas originales produjeron imágenes idénticas y se redujeron las consultas repetidas de clasificación.

Estas cifras **no representan necesariamente la ganancia en una partida real**. En el mundo limpio de prueba con Luanti 5.18 se observaron picos de retraso del servidor superiores a **3 segundos** durante la exploración y generación de cuadrantes. Reducir esos picos es una tarea pendiente prioritaria, especialmente para computadoras de gama baja.

La carga diferida evita transferir indiscriminadamente todas las imágenes ya descubiertas en el arranque, pero un mundo muy explorado puede seguir ocupando espacio significativo en disco.

## Compatibilidad y estado de desarrollo

| Entorno | Estado de esta candidata |
| --- | --- |
| **Luanti 5.18.0 + Minetest Game** | Probado en partidas y mundo limpio; versión objetivo de RC1 |
| Luanti 5.10–5.17 | Pendiente de pruebas y adaptaciones; **no certificado** |
| Minetest/Luanti 5.0–5.9 | Pendiente de adaptadores para API, formularios e imágenes |
| Minetest 0.4.x | No compatible de forma demostrada; no forma parte de RC1 |
| Otros juegos de Luanti | Compatibilidad no certificada; la representación depende de los nodos registrados |

Esta es una **versión experimental**. Aunque se han ejecutado comprobaciones de sintaxis Lua 5.1, regresiones automatizadas y pruebas de juego, eso no certifica todos los botones, condiciones multijugador, permisos o combinaciones de mods.

### Problemas y límites conocidos

- La generación de nuevos cuadrantes puede provocar **pausas perceptibles** en servidores y ordenadores modestos.
- Las capacidades modernas del Atlas y de las imágenes dinámicas todavía necesitan adaptación para versiones antiguas del motor.
- La actualización automática de **todos** los cuadrantes afectados tras una excavación masiva todavía requiere una verificación integral.
- La restauración de iluminación y los conflictos con otros mods necesitan más pruebas multijugador y tras cierres inesperados.
- Algunos textos de la interfaz y los catálogos de idiomas todavía requieren una revisión lingüística completa.
- Antes de desplegar en un servidor público, comprueba privilegios, zonas protegidas y límites de excavación.

Si encuentras errores, adjunta la **versión del motor**, el **juego utilizado**, los **ajustes ADM relevantes**, los **pasos para reproducir el problema** y los mensajes `ERROR` / `WARNING` de `debug.txt` en [GitHub Issues](https://github.com/TuxMatic99/advanced_discovery_maps/issues).

## Idiomas

El repositorio contiene catálogos `.tr` para **español, alemán, francés, italiano, portugués, ruso, japonés, coreano y chino simplificado**. El inglés se utiliza como idioma base de numerosas cadenas del mod. La cobertura de las traducciones no es todavía idéntica en todos los módulos.

## Créditos, procedencia y licencia

- **Proyecto original:** [Discovery Maps](https://codeberg.org/TomCon/discovery_maps), de **TomCon**. Se reconoce su trabajo en la exploración persistente, marcadores y sistema de equipos.
- **Bifurcación y desarrollo:** **Koatl / TuxMatic**, con contribuciones y asistencia de herramientas de IA documentadas en el repositorio.
- **Código fuente de este proyecto:** [TuxMatic99/advanced_discovery_maps](https://github.com/TuxMatic99/advanced_discovery_maps).
- **Licencia declarada en el archivo `LICENSE` del repositorio:** **MIT**, que conserva la atribución a TomCon. El README anterior mencionaba también AGPLv3; **la correspondencia de licencias del código incorporado y de los recursos gráficos debe verificarse antes de publicar**. No se debe deducir que toda imagen, textura o fragmento de terceros tenga licencia MIT solo por estar dentro del repositorio.

Para publicar en ContentDB se deberán confirmar las licencias de todos los recursos distribuidos y conservar las atribuciones correspondientes.

---

## English summary

**Advanced Discovery Maps 2.1.0 RC1** is an experimental Luanti fork of **Discovery Maps by TomCon**. The original project already provides persistent exploration, markers, zoom and Map Parties. This fork expands it with multiple terrain layers (natural, relief, caves and optional enhanced topography), progressive terrain scanning, on-demand map image delivery, map navigation and distance measurement, biome and clock HUDs, a walking minimap, cave/underwater night vision and a permission-gated excavation wand.

**Tested target:** Luanti **5.18.0**, **Minetest Game**. Older engines and other games are **not yet certified**. The improved topography and progressive rendering require explicit configuration (see above). Generation can cause noticeable server lag; this RC is not a guarantee of low-latency operation. Please back up your world before upgrading, and report issues with logs and reproduction steps on [GitHub](https://github.com/TuxMatic99/advanced_discovery_maps/issues).

**Original author:** TomCon · **Fork:** Koatl / TuxMatic · **License status:** see `LICENSE` and verify third-party asset licensing before distribution.
