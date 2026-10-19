## Context

Ver `proposal.md` para la motivación. Puntos del estado actual que condicionan el diseño:

- `index.html` es una aplicación de un solo archivo sin build; dependencias por CDN (MapLibre GL, Tailwind).
- El estado vive en un objeto global `state` (`index.html:442`), expuesto como `window.visorState` (`index.html:464`). Hoy los filtros están **duplicados por capa**: `state.filters` (`region`, `comuna`, `proceso`) para humedales y `state.sinader.filters` (`region`, `rubro`) para SINADER.
- La lógica de filtrado está **duplicada en dos lugares por capa**: la expresión `map.setFilter` y el filtrado en JavaScript del mismo criterio (humedales en `index.html:793` `applyFilters`, SINADER en `index.html:895` `applySinaderFilters`). Cada capa reimplementa predicado, expresión, conteo, `fitBounds`, badge y controles de exportación.
- `state.filteredFeatures` y `state.sinader.filteredFeatures` ya contienen el subconjunto filtrado y son el insumo natural de la agregación de los gráficos; no hace falta recalcular la selección para graficar.
- Las capas son geométricamente homogéneas: humedales `MultiPolygon` (107), SINADER `Point` (9.105).
- Atributos disponibles: humedales `region`, `comuna`, `proceso_humedal_urbano`, `ha`, `nombre_humedal`; SINADER `region`, `comuna`, `rubro` (19 categorías), `n_declaraciones`, `toneladas_totales`. `tipo_recepcion` es constante (no analizable).
- **Inconsistencia conocida de claves:** los nombres de `region` difieren entre datasets (p. ej. `"Libertador General Bernardo O'Higgins"` vs `"Libertador Gral. Bernardo O'Higgins"`, `"Aysén del General Carlos Ibáñez del Campo"` vs `"Aysén del Gral. Carlos Ibañez del Campo"`), lo que impide cruzar capas por igualdad directa.

## Goals / Non-Goals

**Goals:**

- Una **única fuente de verdad** de filtros por capa, consumida por mapa, contadores, exportación y gráficos.
- Un **solo pipeline de filtrado y un solo predicado** por capa (sin duplicar la lógica MapLibre vs JS).
- Dashboard de tres visualizaciones que se recalcula al cambiar filtros y que puede **actualizar el mapa** al interactuarse.
- 100% client-side; Chart.js cargado de forma diferida.
- Mantener el mapa como elemento visual principal y sin regresión en capacidades existentes.

**Non-Goals:**

- Backend, persistencia de filtros entre recargas, o exportación de los gráficos.
- Gráficos configurables por el usuario (elegir dimensiones/medidas), o dashboard de más de tres visualizaciones.
- Sincronización de selección por entidad (resaltar una entidad individual) o brushing por rectángulo sobre el mapa.
- Cambiar la simbología, los popups, la exportación o los datasets.

## Decisions

### 1. Estado de filtros unificado: `FilterStore` como única fuente de verdad

Se introduce un `FilterStore` (objeto JavaScript simple, sin framework) que centraliza los filtros de todas las capas:

```
FILTER_STORE = {
  values:  { humedales: { region:'', comuna:'', proceso:'' },
             sinader:    { region:'', rubro:'' } },
  get(layerId), set(layerId, key, value), reset(layerId), subscribe(listener)
}
```

`state.filters` y `state.sinader.filters` dejan de ser la verdad y pasan a ser vistas derivadas (o se eliminan a favor del store). **Todos** los escritores de filtros —selects del visor, botones "Restablecer" y clics en gráficos— llaman a `FILTER_STORE.set(...)`; nadie muta el filtro directamente. `subscribe` notifica a los consumidores (mapa, contadores, exportación, gráficos) tras cada cambio.

Esto evita la inconsistencia de que un gráfico lea un subconjunto distinto del que pinta el mapa: la agregación de los gráficos se calcula **sobre el mismo arreglo filtrado** que alimenta al mapa, no sobre una segunda interpretación de los criterios.

### 2. Un solo predicado y una sola expresión por capa

Se define una **declaración de campos de filtro** por capa, de la que se derivan tanto el predicado JS como la expresión de MapLibre:

```
FILTER_FIELDS = {
  humedales: [ { key:'region', prop:'region' },
               { key:'comuna', prop:'comuna' },
               { key:'proceso', prop:'proceso_humedal_urbano' } ],
  sinader:   [ { key:'region', prop:'region' },
               { key:'rubro', prop:'rubro' } ]
}
```

- `toMapLibreFilter(layerId, values)` genera el `['all', ...]` a partir de `FILTER_FIELDS` (una sola definición).
- `matchesFilters(layerId, properties, values)` evalúa el mismo criterio en JS.

`applyFilters`/`applySinaderFilters` se reemplazan por un **pipeline único** `applyLayer(layerId)` que: (1) calcula la selección **una vez** con `selectFiltered(layerId)`; (2) aplica `map.setFilter` con `toMapLibreFilter`; (3) actualiza `state`, el contador y el badge; (4) actualiza los controles de exportación; (5) reencuadra la cámara; y (6) emite el evento a los suscriptores. Extender el visor a una nueva dimensión es agregar una entrada en `FILTER_FIELDS` y su `<select>`, no reimplementar el flujo.

### 3. Gráficos como consumidores puros del store

Los gráficos no filtran ni consultan el DOM: reciben `state` derivado. Un módulo de agregación pura:

```
aggregate(chartId, { humedales: state.filteredFeatures, sinader: state.sinader.filteredFeatures })
```

devuelve las series listas para Chart.js. Los gráficos se suscriben al `FilterStore` y se **re-renderizan** (o se actualizan con `chart.data` + `chart.update()`) cuando cambia el estado. Así, "filtros del visor actualizan los gráficos" es una consecuencia del diseño, no una ruta de código aparte.

### 4. Cross-filter gráfico → mapa por el mismo estado

La interacción de un elemento de gráfico **no** filtra por su cuenta: traduce el clic a `FILTER_STORE.set(layerId, key, value)` y luego llama al **mismo** `applyLayer`. Beneficio directo: los controles del visor reflejan el filtro originado en el gráfico y el mapa, el conteo y la exportación quedan coherentes sin código adicional. Reglas de interacción:

- **Viz 1** (humedales por región × proceso): clic en barra → `region`; clic en segmento → `region` + `proceso`.
- **Viz 2** (rubros SINADER): clic en barra → `rubro`.
- **Viz 3** (región, entre capas): clic en región → `region` en **ambas** capas (valores nativos por capa, ver decisión 5).

La selección activa del gráfico se resalta comparando con `FILTER_STORE.get(layerId)`. Reiniciar filtros limpia también el resaltado.

### 5. Normalización canónica de región

Para la Viz 3 y el cross-filter entre capas se define un `REGION_CANONICAL[rawValue]` que mapea cada nombre crudo de ambos datasets a un identificador canónico común y a una etiqueta legible. Con ello: (a) la agregación por región alinea las dos capas; (b) al hacer clic en una región del gráfico, se escribe en cada capa el valor **nativo** que le corresponde (humedales y SINADER reciben strings distintos para la misma región).

Alternativa descartada: normalizar los GeoJSON en origen; cambia datos ya consolidados y complica la conversión, además de acoplar la vista a una limpieza que puede pertenecer a la capa de presentación.

### 6. Chart.js cargado bajo demanda

Se usa Chart.js 4.x (UMD, `chart.umd.js`) desde unpkg con versión fija, cargado por una función `loadChartJs()` análoga a `loadShpWrite()` (inyección única del `<script>`, memoización de la promesa, rechazo controlado). El dashboard vive en el panel lateral, se crea tras `map.on('load')` y tras cargar los datos; el canvas es responsivo (contenedor con altura fija y `maintainAspectRatio:false`) para no alterar la disposición del mapa. Si Chart.js no carga, se muestra el error existente y el mapa sigue operativo.

Se fija la versión en lugar de `@latest` para evitar cambios silenciosos, consistente con `@mapbox/shp-write@0.4.3`.

### 7. Layout: el mapa es el elemento principal

El dashboard se ubica como sección del panel lateral existente (bajo filtros/leyenda). Los canvas tienen altura acotada y scroll en el panel; el contenedor `#map` mantiene su tamaño. No se superponen controles sobre el mapa salvo los ya existentes.

## Risks / Trade-offs

- [Refactor de filtrado con regresión] → se conserva el comportamiento exacto de `applyFilters`/`applySinaderFilters` (misma semántica de predicado, `fitBounds` y contadores) y se valida contra el juego de filtros actual antes de retirar las funciones antiguas.
- [Nombres de región divergentes] → decisión 5 (mapa canónico) y prueba explícita del par `O'Higgins`/`Aysén`; sin esto, la Viz 3 subcontaría.
- [CDN de Chart.js no disponible] → error visible, mapa y filtros intactos; el dashboard no se dibuja.
- [Costo de re-render en cada cambio de filtro] → las agregaciones operan sobre ≤9.105 features; se actualiza `chart.data`/`chart.update()` en vez de recrear gráficos, y no se recalcula nada si el estado no cambió.
- [Rendimiento de redibujo del mapa] → el cross-filter reutiliza `applyLayer` con `setFilter` (no `setData`), sin recargar fuentes.
- [Recursión al sincronizar] → el resaltado del gráfico es solo lectura y no reemite `set`; los valores idénticos se descartan en el store para evitar bucles.
- [Layout en pantallas pequeñas] → verificar 1280 px y 375 px, con el mapa aún dominante.

## Migration Plan

- Cambio aditivo sobre `index.html`: nuevo contenedor de dashboard, `FilterStore`, selectores, módulo de agregación y render Chart.js; refactor de los dos `apply*Filters` a `applyLayer` conservando la firma observable (contadores, badges, exportación, `fitBounds`).
- Sin migración de datos ni de URLs; sin backend.
- Despliegue = publicar el `index.html` actualizado. Rollback = revertir `index.html` (los datos y `scripts/` no se tocan).
- Orden recomendado: primero el store + pipeline único con verificación de no-regresión, luego Chart.js y las tres visualizaciones, finalmente el cross-filter.

## Open Questions

- Top N de rubros en la Viz 2: se propone mostrar los 12 principales por métrica activa (agrupando el resto como "Otras"), ajustable durante la implementación; no afecta specs ni enfoque.
- Eje de la Viz 3: se propone barras (toneladas, eje izquierdo) + línea (número de humedales, eje derecho); la forma exacta del combo se afina sin cambiar la decisión de doble eje.
