## 1. UI de exportación

- [x] 1.1 Agregar en la sección de filtros de humedales dos botones ("GeoJSON" y "Shapefile"), un texto de estado con `aria-live="polite"` y `ids` estables; verificar en `http://127.0.0.1:8137/` que se renderizan sin romper el layout.
- [x] 1.2 Replicar los controles en la sección de filtros de SINADER 2024; verificar que cada capa tiene sus propios botones e `ids` sin colisiones.
- [x] 1.3 Aplicar estilos de deshabilitado y de "Generando…" coherentes con el diseño Swiss existente; verificar visualmente los estados normal, deshabilitado y en progreso.

## 2. Núcleo de exportación

- [x] 2.1 Implementar `updateExportControls(layerId)` que derive el `disabled` de `loaded`, `filteredCount` e `isExporting`; verificar en consola que una capa con 0 resultados queda deshabilitada y con ≥1 se habilita.
- [x] 2.2 Implementar la exportación GeoJSON con `Blob`, nombre `<capa>_filtrado_<YYYY-MM-DD>.geojson` y revocación de URL posterior al clic; verificar que el archivo descargado contiene exactamente `filteredFeatures` y todos sus campos originales.
- [x] 2.3 Definir el mapa de alias DBF de 10 caracteres y una función que transforme propiedades solo para Shapefile; verificar el mapeo de los 11 campos de humedales y los 10 de SINADER sin colisiones.
- [x] 2.4 Implementar `loadShpWrite()` con inyección única del script de unpkg, memoización de la promesa y rechazo controlado; verificar el camino exitoso y un fallo simulado de red.
- [x] 2.5 Implementar `exportLayer(layerId, format)` con instantánea del subconjunto, bandera `isExporting`, validación de homogeneidad geométrica y restauración de controles en `finally`; verificar que un segundo clic durante la generación no inicia otra exportación.
- [x] 2.6 Generar el Shapefile con `zip(geojson, { outputType: 'blob', compression: 'DEFLATE', ... })` y descargarlo con nombre `<capa>_filtrado_<YYYY-MM-DD>_shp.zip`; verificar que el ZIP contiene `.shp`, `.shx`, `.dbf` y `.prj`.

## 3. Integración con filtros y retroalimentación

- [x] 3.1 Invocar `updateExportControls` al cargar cada capa y en `applySinaderFilters`/reset y en el filtrado de humedales; verificar el ciclo 0 resultados → deshabilitado, resultados → habilitado.
- [x] 3.2 Mostrar mensajes de éxito y de error comprensibles, restaurando el estado de los botones; verificar bloqueando unpkg en DevTools que aparece el error y no se descarga un archivo corrupto.

## 4. Verificación end-to-end

- [x] 4.1 Ampliar el harness de Node/vm con casos de exportación filtrada exacta (GeoJSON y Shapefile), estados deshabilitados y protección contra doble exportación; verificar que todos los casos pasan junto con los 24 existentes.
- [x] 4.2 Ejecutar `node --check` sobre el script extraído de `index.html`; verificar sintaxis válida.
- [x] 4.3 Verificar en Chrome headless: aplicar filtros, exportar GeoJSON y comparar el `FeatureCollection` con `window.visorState` (conteo y `id`), exportar Shapefile y comprobar el ZIP real.
- [x] 4.4 Abrir el `.zip` en QGIS u `ogrinfo`; verificar CRS EPSG:4326, atributos, acentos (`Maipú`, `Región`) y límite de nombres de campo.
- [x] 4.5 Verificar ausencia de regresiones en filtros, popups, toggles de visibilidad y reencuadre de cámara; confirmar harness 24/24.

## 5. Cierre

- [x] 5.1 Ejecutar `npx openspec validate "export-filtered-features" --strict` y corregir cualquier observación; confirmar validación exitosa.
- [x] 5.2 Revisar el diff de `index.html` y confirmar que no se modificaron datos, scripts de conversión ni comportamiento no relacionado.
