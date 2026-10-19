## Why

Hoy el visor permite explorar y filtrar las capas, pero no extraer los resultados: quien necesita compartir o analizar externamente el subconjunto filtrado debe reconstruirlo manualmente. Se requiere exportar exactamente lo que está en pantalla, sin backend y sin exponer el dataset completo.

## What Changes

- Nuevo control de exportación por capa (humedales y SINADER 2024), ubicado junto a sus filtros.
- Exportación **solo de las entidades que cumplen los filtros activos** de esa capa, en dos formatos:
  - GeoJSON (`.geojson`), generado con `Blob` sin dependencias.
  - Shapefile comprimido (`.zip` con `.shp`, `.shx`, `.dbf`, `.prj`).
- Los controles se deshabilitan cuando la capa no tiene entidades filtradas o aún no cargó.
- Retroalimentación durante la generación: estado "Generando…", botones bloqueados y aviso de éxito/error.
- Generación 100% client-side; se agrega una única dependencia de navegador, `@mapbox/shp-write`, cargada de forma diferida solo al exportar Shapefile.
- Sin cambios en los datos ni en la lógica de filtrado existente.

## Capabilities

### New Capabilities

<!-- ninguna -->

### Modified Capabilities
- `geospatial-viewer`: se agrega la exportación client-side del subconjunto filtrado por capa en GeoJSON y Shapefile ZIP, con controles deshabilitados sin resultados y retroalimentación de progreso.

## Impact

- `index.html`: controles de exportación en las secciones de filtros de cada capa, un módulo de exportación y estado de UI asociado.
- Dependencia externa nueva: `https://unpkg.com/@mapbox/shp-write@latest/shpwrite.js` (UMD, ~235 kB), cargada bajo demanda; requiere conexión a Internet solo al exportar Shapefile (igual que MapLibre/Tailwind vía CDN).
- Sin cambios en `data/*.geojson`, `scripts/`, ni en el esquema de `state` más allá de exponer el conteo filtrado ya existente.
