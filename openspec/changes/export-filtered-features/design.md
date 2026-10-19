## Context

Ver `proposal.md` para la motivación. Restricciones relevantes del estado actual:

- `index.html` es una aplicación de un solo archivo, sin build ni `package.json`; todas las dependencias se cargan por CDN (MapLibre GL 4.7.1, Tailwind).
- `state.filteredFeatures` (humedales) y `state.sinader.filteredFeatures` (SINADER 2024) ya contienen el subconjunto filtrado, y `filteredCount` ya se actualiza al aplicar filtros; no hace falta recalcular la selección para exportar.
- Cada capa es geométricamente homogénea: humedales son `MultiPolygon` (107) y SINADER son `Point` (9.105).
- Los filtros se aplican en cliente y los botones de reset ya existen; la UI sigue el estilo Swiss del dashboard.

## Goals / Non-Goals

**Goals:**

- Exportar exactamente el subconjunto filtrado de cada capa, en GeoJSON y Shapefile ZIP, sin backend.
- Mantener el costo en cero cuando no se exporta: la dependencia de Shapefile se carga solo bajo demanda.
- Reflejar el estado de exportación en la UI (deshabilitado sin resultados, progreso, éxito/error) sin alterar el layout existente.

**Non-Goals:**

- Exportar capas combinadas en un solo archivo, el dataset completo por encima del filtro, o formatos adicionales (CSV, KML, GeoPackage).
- Reproyectar, simplificar geometrías o preservar simbología/estilos.
- Exportación server-side o generación previa de archivos en `data/`.
- Cambiar la lógica de filtrado, los popups o el comportamiento de las capas.

## Decisions

### 1. Dependencia única: `@mapbox/shp-write` cargada bajo demanda

Se usa `@mapbox/shp-write@0.4.3` (UMD `shpwrite.js` desde unpkg, ~235 kB, licencia BSD-2-Clause) únicamente para el formato Shapefile. Su API `zip(geojson, { outputType: 'blob', compression: 'DEFLATE', folder, filename, types })` genera el ZIP con `.shp`, `.shx`, `.dbf` y `.prj` a partir de un `FeatureCollection`, que es exactamente el contrato que necesitamos.

Alternativas evaluadas:

| Opción | Veredicto |
| --- | --- |
| `@mapbox/shp-write@0.4.3` | **Elegida**: escritor completo + ZIP en un solo artefacto, mantenido bajo la organización Mapbox, soporta `MultiPolygon` y `Point`, salida `blob`. |
| `shp-write@0.3.2` (paquete antiguo) | Descartada: deprecado hace ~10 años, ZIP con compresión defectuosa (usa STORE). |
| `shapefile@0.6.6` (mbostock) | Descartada: es un **parser** de lectura, no un escritor. |
| `jszip` + escritor propio | Descartada: JSZip solo comprime; habría que implementar `.shp`/`.shx`/`.dbf`/`.prj` a mano, con alto riesgo y más código que mantener. |
| Generación en servidor / archivos pre-generados | Descartada: contradice el requisito client-side y multiplicaría archivos por cada combinación de filtros. |

Carga diferida: una función `loadShpWrite()` inyecta el `<script>` una sola vez y memoiza la promesa; si el CDN falla, rechaza y la UI muestra el error. Así el visor no paga los ~235 kB si el usuario solo usa GeoJSON.

Se fija la versión (`0.4.3`) en lugar de `@latest` para evitar cambios silenciosos; no hay CSP en el proyecto que bloquee unpkg.

### 2. GeoJSON con APIs nativas, sin dependencias

`JSON.stringify` sobre un `FeatureCollection` + `Blob` + `URL.createObjectURL` + `<a download>`. Se revoca la URL en un `setTimeout` posterior al clic para no cancelar la descarga. Esto ya estaba prototipado y funciona; se conserva como camino independiente del CDN.

### 3. Un único pipeline de exportación por capa

`exportLayer(layerId, format)` resuelve la capa desde `CONFIG.LAYERS`/estado, toma una instantánea del arreglo filtrado, valida que haya entidades y despacha al generador. Antes de empezar fija `isExporting = true` y deshabilita **todos** los controles de exportación; al terminar (éxito o error) los restaura según `filteredCount`. Esto cubre el requisito de no duplicar descargas sin necesidad de debounce por tiempo.

La selección se lee de `state` en el momento del clic, de modo que exportar siempre refleja lo que el usuario ve, incluso si los filtros ya se aplicaron.

### 4. Nombres de archivo y de campo

- Archivo: `<capa>_filtrado_<YYYY-MM-DD>.geojson` o `<capa>_filtrado_<YYYY-MM-DD>_shp.zip`, donde `<capa>` es `humedales` o `sinader_2024`.
- Shapefile/DBF limita los nombres de campo a 10 caracteres. `shp-write` trunca automáticamente, pero para evitar colisiones y nombres ilegibles se define un mapa explícito de alias:

| Capa | Original | Alias DBF |
| --- | --- | --- |
| humedales | `objectid` | `objectid` |
| humedales | `region` | `region` |
| humedales | `comuna` | `comuna` |
| humedales | `cod_humedal` | `cod_humed` |
| humedales | `nombre_humedal` | `nom_humed` |
| humedales | `ha` | `ha` |
| humedales | `proceso_humedal_urbano` | `proceso` |
| humedales | `resolucion` | `resolucion` |
| humedales | `url_res_bcn` | `url_bcn` |
| humedales | `url_simbio` | `url_simbio` |
| humedales | `srid` | `srid` |
| sinader | `razon_social` | `razon_soci` |
| sinader | `nombre_establecimiento` | `nom_establ` |
| sinader | `codigo_unico_territorial` | `cod_ut` |
| sinader | `tipo_recepcion` | `tipo_recep` |
| sinader | `n_declaraciones` | `n_declarac` |
| sinader | `toneladas_totales` | `ton_total` |

El GeoJSON conserva los nombres originales; solo el Shapefile usa alias.

### 5. Ubicación y estado de los controles

Los controles viven en la sección de filtros de cada capa (junto a "Restablecer"), para que la exportación se perciba como parte del flujo de filtrado. Cada capa tiene dos botones (GeoJSON / Shapefile) y un texto de estado con `aria-live="polite"`. `updateExportControls(layerId)` centraliza el `disabled` y se invoca al cargar la capa, al aplicar/restablecer filtros y al terminar una exportación.

### 6. Validación de geometría antes de exportar

El Shapefile admite un solo tipo de geometría por archivo. Como las capas son homogéneas, se valida que todos los `geometry.type` del subconjunto sean compatibles con el tipo declarado de la capa; si hubiera mezcla, se aborta con un mensaje claro en lugar de generar un archivo inválido. El GeoJSON no necesita esta validación.

## Risks / Trade-offs

- [CDN de unpkg no disponible u offline] → el error se muestra en la UI y los datos del visor quedan intactos; GeoJSON sigue funcionando sin red. Se documenta que Shapefile requiere Internet, igual que MapLibre/Tailwind.
- [Latencia de ~235 kB en la primera exportación Shapefile] → carga diferida + estado "Generando…" y botones bloqueados.
- [Codificación de caracteres acentuados en DBF] → verificar con un caso real (`Maipú`, `Región`) al abrir el `.zip` en QGIS/`ogrinfo`; si hay mojibake, evaluar normalización o documentar la limitación antes de archivar el cambio.
- [Colisión o pérdida de nombres de campo] → mapa de alias explícito (decisión 4) y prueba de los 11/10 campos.
- [`.prj` ausente o incorrecto] → verificar el contenido del ZIP; si falta, agregar el `.prj` WGS84 con JSZip (ya es dependencia transitiva) antes de descargar.
- [Presión de memoria en el peor caso (9.105 puntos)] → volumen bajo; la instantánea es por referencia y la generación es breve.
- [Doble clic o exportaciones simultáneas] → bandera `isExporting` que deshabilita todos los controles hasta finalizar.

## Migration Plan

- Cambio aditivo: no migra datos ni rompe URLs. Despliegue = publicar el `index.html` actualizado.
- Rollback = revertir `index.html`; no hay estado persistido ni backend que limpiar.

## Open Questions

- Ninguna que afecte specs, enfoque o desglose de tareas; la verificación de codificación DBF y `.prj` se resuelve durante la implementación y solo ajusta detalles del generador.
