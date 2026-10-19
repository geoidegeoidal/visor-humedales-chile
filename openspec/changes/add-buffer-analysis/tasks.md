## 1. Worker de análisis

- [x] 1.1 Crear `buffer-worker.js` con el protocolo `buffer/progress/done/error`, carga diferida de Turf y polygon-clipping mediante `importScripts`, y validación de dependencias; verificar sintaxis con `node --check buffer-worker.js` y que el archivo no se cargue hasta el primer análisis
- [x] 1.2 Implementar el buffer individual con `turf.buffer(..., { units: 'meters', steps: 8 })`, conservando propiedades de origen y agregando `buffer_m`; verificar con un arnés que evalúe el worker con 340 puntos y devuelva 340 Features con la distancia correcta
- [x] 1.3 Implementar la disolución con `polygon-clipping.union` por lotes de 1.000, progreso entre lotes y salida normalizada a un Feature MultiPolygon con `{ capa, dist_m, n_origen }`; verificar con los 9.105 puntos que completa sin error, reporta progreso y devuelve 2.616 partes
- [x] 1.4 Manejar fallos de CDN, datos inválidos y excepciones del worker con mensajes en español; verificar con un stub de `importScripts` que falle y comprobar que se emite `error` sin cerrar la aplicación

## 2. Panel y estado del análisis

- [x] 2.1 Agregar la sección "06. Análisis de proximidad" con selector de capa, alcance (todas/filtradas), distancia en metros, disolución, generar, limpiar, estado y resumen; verificar los IDs en el HTML y la legibilidad a 1280 px y 375 px
- [x] 2.2 Agregar el toggle "Áreas de influencia" en la sección 04, deshabilitado sin resultado; verificar que se habilita, marca y desmarca con un resultado existente
- [x] 2.3 Implementar validación de distancia (1–50.000, decimales permitidos), bloqueo de "filtradas" con cero entidades y snapshots de `state.allFeatures`/`state.filteredFeatures`/`state.sinader.features`; verificar los cuatro casos límite sin invocar al worker
- [x] 2.4 Implementar el ciclo de vida del worker: creación diferida, `requestId`, descarte de respuestas obsoletas, bloqueo del formulario durante el cálculo, reutilización tras éxito y recreación tras error; verificar con un doble clic y con una respuesta simulada fuera de orden

## 3. Visualización y gestión del resultado

- [x] 3.1 Crear `buffer-source` y las capas `buffer-fill`/`buffer-outline` por encima de las capas base, con ajuste de vista y reemplazo mediante `setData`; verificar que dos ejecuciones consecutivas dejan una sola capa de resultado
- [x] 3.2 Implementar `state.buffer` con features, metadatos, bounds y visibilidad, y las acciones de ocultar, mostrar y limpiar; verificar que limpiar elimina source/layers, vacía el estado y deshabilita exportación sin alterar humedales ni SINADER
- [x] 3.3 Mostrar en el panel capa, distancia, modo y cantidad de entidades, y confirmar que los filtros y la visibilidad de las capas de origen no cambian al generar, ocultar o limpiar el resultado

## 4. Exportación del resultado

- [x] 4.1 Generalizar el exportador con la capa virtual `buffer`, nombres dinámicos `buffer_<capa>_<distancia>m_<modo>_<fecha>` y alias DBF por modo/capa de origen; verificar que GeoJSON y Shapefile descargan solo el resultado
- [x] 4.2 Agregar botones y estado de exportación del resultado, integrados en `updateAllExportControls` y en el bloqueo global `isExporting`; verificar que están deshabilitados sin resultado y que exportar dos capas no se solapa

## 5. Verificación integral

- [x] 5.1 Extender el arnés de estado con casos de buffer (validación, alcance, reemplazo, limpieza, exportación) y verificar que la suite completa sigue en verde
- [x] 5.2 Probar en Chrome headless: SINADER filtrado 500 m individual, SINADER completo 500 m disuelto, humedales 100 m y error de CDN; verificar descargas, conteos, tiempos y que la interfaz responde durante el cálculo
- [x] 5.3 Validar las salidas con Mapshaper: CRS WGS84, conteo de registros, alias DBF, propiedades de origen y conservación de partes disjuntas en modo disuelto
- [x] 5.4 Ejecutar la regresión de filtros, tema, capas y exportación existente, más `npx openspec validate "add-buffer-analysis" --strict` y `npx openspec validate --all`
