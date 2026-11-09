# Fase 1: sensor de biomas, sin modificar el mapa original

Este módulo es una primera integración experimental y reversible para `advanced_discovery_maps`.

## Instalación en VS Code

1. Copia `biome_sensor.lua` a la raíz de `advanced_discovery_maps`, junto a `init.lua`.
2. En `init.lua`, justo después de `dofile(modpath .. "/map-party-gui.lua")`, agrega:

   ```lua
   dofile(modpath .. "/biome_sensor.lua")
   ```

3. No modifiques `mod.conf` ni sobrescribas los mundos existentes.
4. Verifica el árbol de Git, prueba en una copia del mundo y luego registra un commit si todo funciona.

## Comandos

- `/bioma`: nombre del bioma, valores de calor/humedad y generador; no interpreta esos valores como grados Celsius o porcentajes.
- `/bioma hud`: alterna un HUD discreto, apagado de forma predeterminada. Actualiza como máximo cada 1,5 s y solo si cambió la posición de bloque; actualiza el texto únicamente cuando cambia.

## Compatibilidad

Diseñado para las API de Luanti 5.10.0 y 5.18.0 (prueba funcional pendiente en tu instalación). En mapgen v6 usa una recreación de la clasificación por ruidos de temperatura y humedad basada en la documentación histórica de biomeinfo de Wuzzy; como aquél, **no reproduce exactamente `biomeblend`**. En otros mapgens utiliza `get_biome_data` del motor. Para mapgens personalizados o biomas no disponibles informa "Unknown" en lugar de inventar un resultado.

## Rendimiento y seguridad

No recorre vóxeles, no utiliza `VoxelManip`, no crea mapas, no genera terreno, no escribe en archivos y no manipula nodos. Su única persistencia es un indicador optativo por jugador en metadatos de usuario.

## Atribución

Inspiración y clasificación v6 a partir de la API `biomeinfo` de Wuzzy, licencia MIT. Repositorio oficial: https://codeberg.org/Wuzzy/minetest_biomeinfo.git. Adaptación independiente para Advanced Discovery Maps, sin empaquetar archivos originales. Antes de incorporar literalmente código adicional del original, revisar su versión actual y conservar avisos MIT.
