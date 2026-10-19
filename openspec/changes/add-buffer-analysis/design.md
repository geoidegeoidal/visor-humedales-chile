## Context

Ver `proposal.md` para la motivación. El visor es un `index.html` sin build, con MapLibre GL desde CDN, estado global en `window.visorState` y capas registradas en `CONFIG.LAYERS` (`index.html:365`). Humedales y SINADER ya tienen filtros, conteos y un pipeline de exportación GeoJSON/Shapefile (`layerExportInfo` en `index.html:1033`, `exportLayer` en `index.html:1135`) que este cambio debe reutilizar.

Datos reales que acotan el diseño:

| Caso | Entidades | Tiempo Node | Salida | Vértices |
| --- | ---: | ---: | ---: | ---: |
| Buffer puntos, 500 m, steps 8 | 9.105 | 0,8–1,2 s | 14,8 MB | 300.465 |
| Buffer puntos, 500 m, steps 16 | 9.105 | 0,9–1,1 s | 26 MB | 591.825 |
| Buffer polígonos, 100 m | 107 | 2,3 s | 2,6 MB | 67.954 |
| Buffer polígonos, 500 m | 107 | 6,7–7,1 s | 1,1 MB | 27.042 |
| Buffer polígonos, 1.000 m | 107 | 7,6–7,9 s | 0,8 MB | 19.045 |
| `turf.dissolve`, 500 m | 4.252 | 27,3 s | 1,4 MB | — |
| `polygon-clipping.union`, 500 m | 4.252 | 4,2 s | 1,4 MB | 37.197 |
| `polygon-clipping.union`, 500 m | 9.105 | 6,2 s | 4,7 MB | 123.357 |
| Unión por lotes de 1.000 | 9.105 | 6,7 s | 4,7 MB | 123.357 |

La precisión geodésica de Turf es adecuada: un buffer de 1.000 m mide 1.000,0 m en el ecuador y en latitudes -33,5 y -41,3. `polygon-clipping` falla en el caso completo con `steps: 16` (`Infinite loop when putting segment endpoints in a priority queue`), mientras que con `steps: 8` completa en 6,2 s y 474 MB de heap pico al unir por lotes de 1.000.

Dependencias: `@turf/turf@7.2.0` (563.527 bytes, UMD, global `turf`) y `polygon-clipping@0.15.7` (89.619 bytes, UMD, global `polygonClipping`), ambas desde unpkg con `Access-Control-Allow-Origin: *`.

## Goals / Non-Goals

**Goals:**

- Calcular buffers en metros sobre la capa y el alcance elegidos sin bloquear la interfaz.
- Soportar modo individual y disuelto con una salida GeoJSON consistente.
- Integrar el resultado con el mapa, los controles de capas y el exportador existente.
- Mantener la aplicación estática, sin build ni backend.

**Non-Goals:**

- Reproyectar datos o introducir una proyección local; Turf ya resuelve metros con precisión suficiente.
- Editar buffers, bufferizar selecciones dibujadas, o recalcular automáticamente al cambiar filtros.
- Exponer `steps`, unidades distintas de metros, o buffers múltiples simultáneos.
- Persistir el resultado entre recargas o exportar capas base junto con el resultado.
- Añadir un índice espacial, GPU, transferables o procesamiento incremental en el hilo principal.

## Decisions

### 1. Turf.js para el buffer y polygon-clipping para la disolución

Turf genera el buffer geodésico en metros y soporta Polygon/MultiPolygon. La disolución se hace con `polygon-clipping.union`, no con `turf.dissolve`: `turf.dissolve` es O(n²) (27 s para 4.252 puntos y ~2 min estimados para 9.105) y rechaza buffers MultiPolygon con `Invalid input to dissolve: must be a Polygon, given MultiPolygon`.

`steps` queda fijo en 8 (33 vértices por círculo). Con 16 el caso completo de 9.105 puntos falla en polygon-clipping y además duplica el tamaño de salida; 8 es el mejor equilibrio entre fidelidad visual y costo. Alternativas descartadas: `steps` configurable (más superficie de error y salidas de hasta 48 MB), disolver con Turf (inviable), buffer en servidor (rompe la arquitectura estática).

### 2. Web Worker dedicado

El cálculo corre en `buffer-worker.js`, un worker clásico creado bajo demanda con `new Worker('./buffer-worker.js')`. El worker carga Turf y polygon-clipping con `importScripts` en el primer mensaje y los reutiliza. Esto es necesario, no cosmético: el peor caso medido en Node es 6,2 s de unión más 0,8 s de buffer, y los polígonos tardan hasta 7,9 s; en el hilo principal la interfaz quedaría congelada y el estado "Calculando…" no se pintaría. Un worker además aísla el pico de memoria del hilo de la interfaz.

No se añaden transferables ni streaming: el dataset mayor son 3,8 MB y la salida individual mayor ronda 15 MB; el clon estructurado tarda decenas de milisegundos. Un Blob worker mantendría el HTML único, pero un archivo separado es más legible y depurable, y GitHub Pages ya sirve archivos estáticos. `file://` no es un escenario válido porque MapLibre ya requiere un servidor estático para cargar los GeoJSON.

### 3. Protocolo del worker y unión por lotes

Mensajes de entrada: `{ type: 'buffer', requestId, features, distance, dissolve, sourceLayer }`. Salidas: `progress` con `{ phase: 'buffer' | 'union', done, total }`, `done` con `{ features, meta }`, y `error` con `{ message }`.

El worker valida las dependencias, ejecuta `turf.buffer(collection, distance, { units: 'meters', steps: 8 })`, y si hay disolución une las geometrías con `polygon-clipping.union` en lotes de 1.000, publicando progreso entre lotes. La unión por lotes conserva el tiempo (6,7 s) y baja el pico de heap a 474 MB; también produce progreso observable. El resultado disuelto se normaliza siempre a un Feature con geometría `MultiPolygon`, aunque tenga una sola parte.

### 4. Alcance, validación y ciclo de vida

El panel toma una instantánea de las features al generar (`state.filteredFeatures` o el conjunto completo de la capa) y la envía al worker. La distancia se valida en el cliente: número finito entre 1 y 50.000 metros, con decimales permitidos. El alcance "filtradas" se bloquea si el conteo filtrado es cero; el alcance "todas" usa `state.allFeatures` para humedales y `state.sinader.features` para SINADER.

Un contador `requestId` monotónico descarta respuestas obsoletas. Mientras hay un cálculo, el botón de generar y los campos del panel se deshabilitan; no se termina el worker al terminar, para reutilizar las dependencias. Si el worker falla o no puede cargar un CDN, se muestra el error, se conserva el resultado anterior y se recrea el worker en el siguiente intento. Cambiar filtros no recalcula el buffer: el resultado es una instantánea explícita hasta que el usuario vuelva a generar o limpie.

### 5. Representación del resultado

En modo individual se devuelve un Feature por entidad, con las propiedades de origen más `buffer_m` (distancia). En modo disuelto se devuelve un único Feature con propiedades `{ capa, dist_m, n_origen }`. La capa se guarda en `state.buffer` con `{ features, meta, sourceLayer, bounds, visible }`; no se registra en `CONFIG.LAYERS` porque no es una capa de datos con URL.

La visualización usa un source `buffer-source` y dos layers `buffer-fill`/`buffer-outline`, añadidos por encima de las capas existentes. Color cian (`#22d3ee` relleno al 16 %, `#0891b2` borde) para distinguirse del azul de humedales y del rojo de SINADER. Al terminar se ajusta la vista con los bounds del resultado. Una nueva ejecución reemplaza los datos con `setData`; limpiar elimina layers/source y vacía `state.buffer`. El toggle "Áreas de influencia" de la sección 04 se habilita cuando existe resultado.

### 6. Exportación reutilizando el pipeline

Se extiende el exportador con la capa virtual `buffer`: `layerExportInfo('buffer')` devuelve las features del resultado y una definición de geometría `polygon`; `updateAllExportControls` incluye sus botones. Los nombres se calculan dinámicamente como `buffer_<capa>_<distancia>m_<individual|disuelto>_<fecha>` para GeoJSON y `..._shp.zip` para Shapefile, en lugar de depender del mapa estático `EXPORT_BASE_NAMES`.

Para el DBF, el modo individual reutiliza los alias de la capa de origen y agrega `buffer_m`; el modo disuelto usa alias cortos `capa`, `dist_m`, `n_origen`. El resto del pipeline (`isExporting`, `loadShpWrite`, `downloadBlob`, validación de geometrías y estados) se mantiene sin cambios.

### 7. Errores y estados

El panel muestra fases ("Generando buffers…", "Disolviendo…") y el conteo de origen. Los errores del worker se traducen a mensajes en español y no borran el resultado previo. La UI mantiene el tema, el mapa y los controles generales operativos; solo se bloquea el formulario de análisis. Si el usuario limpia el resultado durante un cálculo, la respuesta se descarta.

## Risks / Trade-offs

- **Memoria**: el pico medido es 474 MB con lotes de 1.000 y puede superar 1 GB sin lotes; en móviles de gama baja puede fallar. Mitigación: worker aislado, unión por lotes, mensaje de error claro y resultado anterior intacto.
- **Dependencia de CDN**: sin Turf o polygon-clipping no hay análisis. Mitigación: versiones exactas, carga diferida, error explícito y reintento al volver a generar.
- **Salida individual grande**: 9.105 buffers de puntos generan ~15 MB y 9.105 polígonos en MapLibre. Mitigación: `steps: 8`, una sola fuente y capas de relleno/borde; se valida el render en navegador.
- **Precisión visual de círculos**: con `steps: 8` un buffer de 50 km se ve poligonal. Aceptado para mantener tamaño y viabilidad de la unión; no se expone `steps`.
- **Geometrías inválidas o artefactos**: los buffers de polígonos pasan por JSTS y la unión por polygon-clipping. Mitigación: verificación con datos reales y Mapshaper antes de cerrar la change.
- **Resultado desactualizado respecto a filtros**: es una instantánea deliberada. Mitigación: el resumen indica capa, distancia y cantidad; el usuario regenera cuando cambie filtros.
- **Ruta del worker**: debe resolverse relativa al HTML para GitHub Pages y servidores estáticos. Mitigación: `./buffer-worker.js` y prueba en el servidor local.

## Migration Plan

Cambio aditivo: se agrega una sección al panel, un archivo `buffer-worker.js` y ramas nuevas en el exportador. No hay migración de datos ni cambios en los GeoJSON. Se implementa sobre el pipeline de exportación de `export-filtered-features` (completado, aún no archivado). Rollback: eliminar la sección, el worker y las ramas de exportación; las capas y filtros existentes no se tocan.

## Open Questions

Ninguna.
