## 1. Estado de filtros unificado y pipeline sin duplicación

- [x] 1.1 Crear `FILTER_STORE` con `values` por capa, `get/set/reset/subscribe` y descarte de valores idénticos; exponerlo para inspección en consola; verificar con un listener que un `set` efectivo notifica una vez y un `set` con el mismo valor no notifica
- [x] 1.2 Definir `FILTER_FIELDS` por capa (humedales: `region`/`comuna`/`proceso`→`proceso_humedal_urbano`; SINADER: `region`/`rubro`) y derivar de él `toMapLibreFilter(layerId)` y `matchesFilters(layerId, properties)`; verificar que un mismo criterio produce la misma selección por expresión y por predicado
- [x] 1.3 Reemplazar `applyFilters` (`index.html:793`) y `applySinaderFilters` (`index.html:895`) por un pipeline único `applyLayer(layerId)` que selecciona una vez y actualiza `setFilter`, estado, contador, badge, exportación y `fitBounds`; verificar que humedales y SINADER mantienen exactamente su comportamiento previo
- [x] 1.4 Redirigir todos los escritores de filtros (selectores `filter-region`/`filter-comuna`/`filter-proceso`/`filter-sinader-region`/`filter-sinader-rubro` y ambos "Restablecer") a `FILTER_STORE` + `applyLayer`; verificar que ningún manejador muta el estado directamente
- [x] 1.5 Derivar `window.visorState` desde `FILTER_STORE` conservando `allFeatures`, `features`, `filteredFeatures` y conteos por capa; verificar en consola la paridad con la estructura anterior

## 2. Dependencia Chart.js y layout del dashboard

- [x] 2.1 Implementar `loadChartJs()` con inyección única del script de unpkg (versión fija 4.4.x), memoización de la promesa y rechazo controlado; verificar el camino exitoso y un fallo simulado de red
- [x] 2.2 Agregar la sección de dashboard en el panel lateral con tres `canvas` de altura acotada, `maintainAspectRatio:false` y scroll del panel; verificar a 1280 px y 375 px que el mapa conserva su tamaño y protagonismo
- [x] 2.3 Inicializar el dashboard tras `map.on('load')` y la carga de datos, mostrando el error existente si Chart.js falla; verificar que el mapa y los filtros siguen operativos sin Chart.js

## 3. Agregaciones y visualizaciones

- [x] 3.1 Implementar selectores de agregación puros sobre `state.filteredFeatures`/`state.sinader.filteredFeatures` (conteo por región×proceso, suma de toneladas por rubro, y métricas por región); verificar los totales contra el dataset completo (107 humedales; Σ 11.539.000 t aprox. de entidades mostradas)
- [x] 3.2 Crear el gráfico de humedales por `region` × `proceso_humedal_urbano` (barra horizontal apilada) y verificar que la suma de segmentos coincide con el conteo de la capa
- [x] 3.3 Crear el gráfico de rubros SINADER por carga declarada con conmutador de métrica (toneladas ↔ nº establecimientos) y top N + "Otras"; verificar ambas métricas y el orden descendente
- [x] 3.4 Implementar el mapa canónico de región y crear el gráfico de coincidencia territorial (barras + línea con doble eje); verificar la alineación de `O'Higgins` y `Aysén` sin duplicar ni perder categorías

## 4. Cross-filter y sincronización bidireccional

- [x] 4.1 Suscribir las tres visualizaciones a `FILTER_STORE` y actualizar con `chart.data`/`chart.update()` (sin recrear) al cambiar el estado; verificar el ciclo filtro del visor → gráfico
- [x] 4.2 Implementar el clic en barras/segmentos para escribir en `FILTER_STORE` y llamar a `applyLayer`; verificar humedales por región+proceso y SINADER por rubro (mapa, selector y contador coherentes)
- [x] 4.3 Implementar el clic por región del gráfico territorial escribiendo el valor nativo de cada capa en ambas; verificar el cross-filter entre capas y el re-encuadre
- [x] 4.4 Resaltar la selección activa comparando con `FILTER_STORE.get(layerId)` y limpiarla al restablecer filtros; verificar que el resaltado no reemite `set` ni provoca bucles

## 5. No regresión y verificación integral

- [x] 5.1 Verificar que filtros, popups, exportación filtrada, visibilidad de capas, tema y encuadre conservan su comportamiento con el dashboard activo
- [x] 5.2 Ampliar el harness de Node/vm con casos de store (notificación, descarte de valores idénticos), predicado vs expresión y agregaciones; verificar que la suite completa sigue en verde
- [x] 5.3 Probar en Chrome headless: filtro desde selectores actualiza gráficos, clic en gráfico actualiza mapa/selector, cross-filter entre capas y error de CDN de Chart.js; verificar que no hay bucles de sincronización
- [x] 5.4 Validar la Change con `npx openspec validate "add-cross-filtered-dashboard" --strict` y `npx openspec validate --all`
