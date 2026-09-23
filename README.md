# Advanced Discovery Maps: Topological, Telemetry & Tactical Overhaul

**Advanced Discovery Maps** es una evolución de grado profesional del mod original `discovery_maps` para Luanti. Reescribimos por completo el motor de renderizado y la lógica de físicas para introducir herramientas cartográficas avanzadas, un espectrómetro 2D interactivo y un arsenal de control topográfico.

Este proyecto fue construido bajo los principios del **Algoritmo Tuxmatic**: optimización extrema y austeridad de I/O. El mod entrega mapeo 3D complejo, excavación masiva asíncrona y telemetría en tiempo real manteniendo una huella de memoria minúscula, evitando interbloqueos (stuttering) y protegiendo los discos duros mecánicos (HDD) en servidores y equipos de entrada.

---

## 🛠 Características Principales

* **Motor de Renderizado Triple Búfer (VoxelManip):** Genera mapas de satélite, relieves topográficos simulados con multiplicadores de sombra direccionales, y mapas batimétricos/subterráneos en una sola lectura de RAM.
* **Espectrómetro Mineral 2D y Macroscopía GPU:** Genera perfiles de elevación transversales (Eje X o Z). Incorpora un radar de coste computacional cero que resalta minerales subterráneos en colores neón de alto contraste. La navegación panorámica y el zoom se aceleran por hardware (GPU) utilizando contenedores anidados, sin generar latencia en el servidor.
* **Cian Fluorescente:** Metales y gemas preciosas (Oro, Diamante, Cobre, etc.).
* **Magenta Fluorescente:** Fósiles y combustibles (Carbón).
* **Verde Radiactivo:** Materiales industriales personalizables (ej. Uranio), ajustables desde el código base.


* **Excavación Asíncrona Estratificada (Varita Tuxmatic):** Permite la pulverización masiva del terreno (hasta un radio de 100 bloques) en tiempo real. Corta la esfera matemáticamente en capas horizontales y utiliza pausas dinámicas (`minetest.after`) para evitar interbloqueos de CPU.
* **Visión Nocturna Táctica (Coste Cero):** Un emisor lumínico adaptativo que persigue al jugador. Desactiva la física de fluidos (`liquid_range = 0`) para iluminar océanos y cavernas profundas sin desencadenar simulaciones de corrientes que asfixien el procesador.
* **Control Atlético Integral:** Calibración en tiempo real de velocidad de vuelo (`flyspeed`), velocidad en tierra (`runspeed`) y salto (`jumpheight`). La lógica se inyecta directamente en el rastreador pasivo del motor para evitar la saturación del recolector de basura de Lua.
* **Mapeo Telemétrico en Equipo (Map Party):** Los rastreadores de jugadores utilizan una escala de logaritmo atenuado (polígonos Chevron) para mantener la legibilidad. La compartición de mapas usa una búsqueda matricial lógica en RAM, requiriendo una sola lectura/escritura en el disco por escaneo de área.
* **Internacionalización (i18n):** Interfaz desacoplada y traducida nativamente a Español, Inglés, Portugués, Francés, Italiano, Alemán, Ruso, Japonés, Coreano y Chino Simplificado.

---

## 💻 Directorio de Comandos Tácticos

Todos los comandos están blindados por **Escudos Termodinámicos** (temporizadores de enfriamiento) para evitar el spam de peticiones al servidor. Usa `/map_ayuda` dentro de Luanti para consultar este índice.

* `/map` - Abre la interfaz principal del radar topográfico.
* `/actualizar_mapa <radio>` - Fuerza el recálculo geológico manual de los cuadrantes alrededor del jugador (Límite R=3 para protección de memoria).
* `/nv` - Activa o desactiva la Visión Nocturna Táctica.
* `/flyspeed <número>` - Ajusta el multiplicador de velocidad exclusivo para el vuelo (Ej. `/flyspeed 3`).
* `/runspeed <número>` - Calibra la velocidad de desplazamiento a pie.
* `/jumpheight <número>` - Modifica la potencia del salto.
* `/varita` - Inyecta la Varita de Excavación (Tuxmatic) en el inventario (Requiere privilegio `give`).
* `/mapparty <acción>` - Sistema de cuadrillas para exploración compartida. Comandos: `create`, `add`, `remove`, `leave`, `list`, `info`.
* `/markers` - Abre el panel de control de rastreadores y puntos de interés (waypoints).

---

## 🔧 Guía de Modificación para Desarrolladores

La arquitectura de este mod es modular y transparente. Cualquier desarrollador puede adaptar la física, los colores o los límites matemáticos modificando parámetros específicos. Aquí tienes las directrices para alterarlo con seguridad:

**1. Personalizar el Espectrómetro Mineral (`init.lua`)**
Para hacer que el radar 2D detecte minerales adicionales (ej. mods industriales como Uranio o Titanio), busca la función `persistent_map.generate_profile`. Dentro de ella, localiza la condicional de cadenas `string.find(node_name, "ore")`.

* Añade tu propia regla lógica: `elseif string.find(node_name, "uranium") then r, g, b = 57, 255, 20` (Verde radiactivo).
* *Nota de rendimiento:* Usa exclusivamente `string.find`. No instancies entidades para evitar saturar el *Garbage Collector*.

**2. Alterar los Límites de Destrucción Masiva (`init.lua`)**
La Varita Tuxmatic está limitada a 100 bloques de radio para proteger hardware de 2 núcleos o discos duros mecánicos (HDD). Si alojas tu servidor en una máquina con almacenamiento NVMe y procesadores de alto nivel de hilos:

* Localiza la función `tuxmatic_boom`.
* Cambia el límite termodinámico: `local r = math.min(math.max(radius, 1), 100)` por el valor que soporte tu RAM (ej. `250`).
* Ajusta la pausa en `tuxmatic_async_layer`: El temporizador base es `0.15` segundos por capa. Bájalo a `0.05` para demoliciones más agresivas.

**3. Ampliar la Paleta Topográfica (`nodecolors.lua`)**
Para que el mapa renderice correctamente biomas personalizados, abre el archivo de colores.

* Puedes inyectar colores prioritarios precisos en la tabla `manual_overrides` (útil para estructuras de mods específicos).
* Puedes aprovechar el motor heurístico en la tabla `keyword_colors`. Añadiendo `{pattern = "alien_grass", color = {150, 0, 255}}`, cualquier bloque que contenga esa palabra se pintará de púrpura, sin importar de qué mod provenga.

**4. Ajustar los Escudos de Enfriamiento (`init.lua`)**
Para evitar abusos en servidores multijugador, la regeneración topográfica bloquea peticiones sucesivas.

* Busca `TIEMPO_ENFRIAMIENTO_MAPA = 15`. Si tu servidor es privado o local, puedes reducirlo a `2` segundos para actualizaciones inmediatas.

---

### Créditos y Licencias

Este proyecto nace como una bifurcación altamente reescrita y expandida del mod `discovery_maps` creado por TomCon.

También otros mods que sirvieron de inspiración para mejorar este mod son los siguientes:

* `Flight Speed ( flyspeed )` : optimizado por Deedee Daydream 2025
* `boomstick` : luxionary
* `Night Vision` : Juha (CraftPlay777)
* **Autor del Overhaul:** Koatl (Tuxmatic).
* **Licencia del Código:** MIT / AGPLv3.
* **Desarrollado para:** Motor Luanti 5.16.x y superiores. Totalmente compatible con Minetest Game, MineClone2, Voxelibre y NodeCore.
* **Desarrollado con ayuda de las siguientes Inteligencias Artificiales: Gemini Pro, ChatGPT, DeepSeek, Qwen, Mistral.ai, meta, dola.**

El código base es libre. Desensámblalo, analízalo bajo el método científico y adáptalo para tus propios ecosistemas de desarrollo.

