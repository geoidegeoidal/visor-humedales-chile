## Why

El visor hoy muestra una sola capa (Humedales Urbanos). El proyecto cuenta con un segundo dataset espacial, el registro SINADER 2024 de declaraciones de residuos (`gi-sinader-2024-ckan (3).xlsx`), que aporta una dimensión territorial complementaria (puntos georreferenciados de establecimientos generadores de residuos). Incorporarlo amplía el valor del visor, pero no debe degradar ni romper las capacidades ya existentes (humedales, filtros, popups, mapa base oscuro, tema).

## What Changes

- Añadir una **capa secundaria de puntos** (SINADER 2024) renderizada por MapLibre **además** de la capa de humedales, cargada únicamente cuando el mapa esté listo (`map.on('load')` y estilo cargado).
- Generar de forma offline el archivo estático `data/sinader_2024.geojson` (FeatureCollection de `Point`) a partir del `.xlsx`, descartando las filas con coordenadas inválidas/nulas (36 de 241.687) y normalizando tipos. El visor sigue siendo 100% client-side sirviendo este archivo desde rutas relativas.
- **Separar datos de simbología**: introducir configuración por capa donde la fuente de datos (URL, id de source) y la simbología (campo, categorías, colores, tipo de geometría) viven en objetos independientes y reutilizables.
- Añadir controles de **visibilidad por capa** (mostrar/ocultar humedales y SINADER de forma independiente) y **filtros propios de la capa secundaria** (p. ej. `region` y `rubro`) construidos con el mismo mecanismo genérico, sin alterar el comportamiento de los filtros de humedales.
- Dejar la arquitectura preparada para **gráficos futuros**: al separar datos de simbología y exponer el subconjunto filtrado por capa, los gráficos podrán consumirlo más adelante (no se implementan en esta Change).
- **No BREAKING**: los `id`, flujos y comportamiento de humedales (carga, filtros, leyenda, popups, conteo, botón de encuadre, tema) permanecen intactos.

## Capabilities

### New Capabilities

<!-- Ninguna: la capa secundaria es comportamiento de la capacidad existente del visor. -->

### Modified Capabilities

- `geospatial-viewer`: se añaden requisitos para una capa espacial secundaria cargada tras inicializar MapLibre, con datos y simbología separados, visibilidad y filtrado independientes, manteniendo las capacidades existentes sin regresión.

## Impact

- **Código:** `index.html` (carga de capas, config de simbología por capa, controles de visibilidad, filtros, leyenda/conteo por capa).
- **Datos:** nuevo `data/sinader_2024.geojson` generado desde `gi-sinader-2024-ckan (3).xlsx` (241.687 filas, 40 columnas, punto lat/lon EPSG:4326). Se conserva `data/humedales_urbanos.geojson`.
- **Herramienta offline:** script de conversión xlsx → GeoJSON (no se ejecuta en el navegador).
- **Dependencias:** sin nuevas dependencias en runtime cliente (MapLibre + Tailwind por CDN ya presentes); el conversor puede usar una librería de Excel solo en la fase de preparación.
- **No afecta:** backend inexistente, API keys inexistentes, ejecución client-side del visor.
