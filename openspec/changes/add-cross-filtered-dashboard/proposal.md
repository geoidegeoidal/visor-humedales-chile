## Why

El visor permite explorar, filtrar y exportar humedales y SINADER, pero solo ofrece lectura entidad por entidad (mapa, popups, contadores). No responde preguntas analíticas agregadas: cuántos humedales hay por región y proceso de declaratoria, qué rubros concentran la carga de residuos declarados, o en qué territorios coexisten ambas presiones. Incorporar un dashboard de gráficos derivado del mismo estado de filtros convierte el visor en una herramienta de análisis territorial, sin backend y sin duplicar la lógica de filtrado existente.

## What Changes

- Nuevo **dashboard analítico** con tres visualizaciones:
  1. Humedales por región y proceso de declaratoria (barras apiladas).
  2. Rubros SINADER por carga declarada en toneladas (ranking, métrica conmutable a conteo de establecimientos).
  3. Coincidencia territorial por región: número de humedales vs toneladas SINADER (barras + línea con doble eje).
- **Estado de filtros unificado**: mapa, filtros, contadores, exportación y gráficos derivan de una única fuente de verdad por capa; se elimina la duplicación actual entre la expresión de MapLibre y el filtrado en JavaScript.
- **Filtros del visor → gráficos**: al cambiar cualquier filtro (región, comuna, proceso, rubro) los gráficos se recalculan sobre el subconjunto filtrado.
- **Gráficos → mapa (cross-filter)**: las interacciones definidas en los gráficos (clic en barra/segmento/región) actualizan el mismo estado de filtros y, por tanto, el mapa, el conteo y los controles de exportación.
- **Normalización canónica de región** para alinear los dos datasets y habilitar la visualización y el filtrado entre capas.
- **Chart.js vía CDN**, cargado de forma diferida al primer render del dashboard; el visor sigue siendo 100% client-side.
- El **mapa permanece como elemento visual principal**; el dashboard se integra al panel lateral sin desplazarlo ni romper el layout Swiss existente.
- **No BREAKING**: filtros, popups, exportación, tema, visibilidad de capas y encuadre de cámara conservan su comportamiento.

## Capabilities

### New Capabilities

<!-- Ninguna: el dashboard es comportamiento de la capacidad existente del visor. -->

### Modified Capabilities

- `geospatial-viewer`: se añaden requisitos de un estado de filtros unificado, un pipeline de filtrado sin duplicación, un dashboard analítico con Chart.js alimentado por ese estado, sincronización bidireccional entre filtros/gráficos/mapa y normalización de región entre capas.

## Impact

- **Código:** `index.html` — nuevo contenedor de dashboard, módulo de estado de filtros (`FilterStore`), selectores puros (`selectFiltered`, `aggregate`), refactor de `applyFilters`/`applySinaderFilters` a un pipeline único, y render/destrucción de gráficos Chart.js.
- **Dependencia externa nueva:** `https://unpkg.com/chart.js@4.4.x/dist/chart.umd.js` (UMD, ~200 kB), cargada bajo demanda; requiere conexión a Internet solo para el dashboard, igual que MapLibre/Tailwind.
- **Datos:** sin cambios en `data/*.geojson` ni en `scripts/`; la normalización de región se resuelve en código.
- **Estado:** `window.visorState` se mantiene para inspección, pero pasa a derivarse del estado de filtros unificado.
- **Sin backend ni claves de API.**
