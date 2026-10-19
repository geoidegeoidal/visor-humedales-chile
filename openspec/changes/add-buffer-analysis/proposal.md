## Why

El visor permite filtrar y exportar humedales y establecimientos SINADER, pero no responde preguntas de proximidad como "qué establecimientos están a menos de 500 m de un humedal". Calcular áreas de influencia (buffer) en el cliente, sobre el dataset completo o el filtrado, evita depender de un SIG externo o de un backend y mantiene la aplicación estática.

## What Changes

- Nuevo panel de análisis para generar áreas de influencia a partir de la capa seleccionada (humedales o SINADER).
- Distancia configurable por el usuario en metros, con validación de rango y unidad visible.
- Selector de alcance: todas las entidades cargadas o solo las filtradas.
- Opción de disolver buffers solapados en una geometría única, o conservar un buffer por entidad.
- Visualización del resultado como capa temporal, con ajuste de vista, visibilidad y limpieza.
- Exportación del resultado a GeoJSON y Shapefile ZIP reutilizando el pipeline de exportación existente.
- Cálculo en un Web Worker con Turf.js y polygon-clipping cargados desde CDN, para no bloquear la interfaz durante operaciones de varios segundos.
- Estados de progreso, error y prevención de ejecuciones duplicadas.

## Capabilities

### New Capabilities

Ninguna.

### Modified Capabilities

- `geospatial-viewer`: se agregan requisitos de generación de buffers en metros, disolución opcional, visualización y gestión del resultado, exportación y retroalimentación de ejecución.

## Impact

- `index.html`: nuevo panel de análisis, estado del resultado, capa MapLibre y controles de exportación.
- `buffer-worker.js`: nuevo worker clásico que carga Turf.js y polygon-clipping desde CDN y ejecuta buffer/unión.
- Dependencias de runtime: `@turf/turf@7.2.0` (~563 KB) y `polygon-clipping@0.15.7` (~90 KB), cargadas bajo demanda solo en el worker.
- Pipeline de exportación: se generaliza para admitir la capa virtual de resultado y nombres de archivo dinámicos.
- Sin cambios en datasets, filtros existentes ni backend.
