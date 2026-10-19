## Context

Véase `proposal.md` para la motivación. Estado actual relevante (inspección de `index.html` y del dataset):

- El visor es un único `index.html` (MapLibre GL JS 4.7.1 + Tailwind por CDN, patrón *Zero-Server*). Todo el código de aplicación vive en un `<script>` embebido (~500 líneas).
- La carga de datos ocurre en `map.on('load', () => { applyTheme(); loadGeoJsonLayer(); })`. `loadGeoJsonLayer()` **codifica directamente** los identificadores de humedales: `humedales-source`, `humedales-fill`, `humedales-outline`, y usa `CONFIG.DATA_URL` + `CONFIG.SYMBOLOGY` (campo `proceso_humedal_urbano`).
- Filtros y conteo (`populateFilters`, `applyFilters`, `updateCountBadge`, `fitToFiltered`) están cableados a los atributos de humedales; leyenda (`renderLegend`) y popups (`setupFeaturePopups`) también.
- Dataset secundario inspeccionado (`gi-sinader-2024-ckan (3).xlsx`): hoja "Datos" con **241.687 filas** y **40 columnas**; geometría implícita de **punto** en `latitud`/`longitud` (EPSG:4326, mismo CRS que humedales); hoja "Resumen". Hallazgos de calidad:
  - **36 filas** con coordenadas fuera de rango (valores corruptos enormes) → descartar.
  - `latitud`/`longitud`: 0 celdas nulas, pero 36 filas inválidas.
  - Cardinalidades útiles: **9.109** establecimientos (`id_vu`) distintos; **20** categorías de `rubro`; **317** códigos territoriales; `tipo_recepcion` binario.
  - Tamaño del archivo: 43,5 MB (inviable de parsear en el navegador en runtime).

## Goals / Non-Goals

**Goals:**

- Incorporar la capa secundaria de puntos SINADER **además** de humedales, cargada solo tras `map.on('load')` y estilo cargado.
- Separar, a nivel de configuración y de código, los **datos** (origen/geometría) de la **simbología** (campo, categorías, colores) de cada capa.
- Visibilidad y filtros independientes por capa, sin alterar el comportamiento de humedales.
- Mantener ejecución 100% client-side (sin backend, sin claves).
- Dejar la estructura lista para **gráficos futuros** (subconjunto filtrado y conteos por capa ya expuestos).

**Non-Goals:**

- Implementar gráficos/estadísticas (se harán más adelante).
- Editar o parsear el `.xlsx` en el navegador.
- Edición/consulta avanzada (mapa de calor, teselado, agregación dinámica server-side).
- Cambiar el esquema visual Swiss existente ni el HUD más allá de lo mínimo para los controles nuevos.

## Decisions

### 1. Conversión offline `.xlsx` → `data/sinader_2024.geojson`

- **Decisión:** generar un `FeatureCollection` de `Point` estático en `data/sinader_2024.geojson` mediante un script de preparación (fuera del navegador). El visor lo sirve como recurso relativo, igual que humedales.
- **Razón:** el `.xlsx` pesa 43,5 MB; parsearlo en el cliente exige una librería de Excel y mucho tiempo/memoria del hilo principal. Un GeoJSON estático mantiene el patrón *Zero-Server* y la carga asíncrona ya existente.
- **Alternativas consideradas:** cargar el `.xlsx` en runtime con SheetJS → descartado por peso y bloqueo del hilo; servir CSV y convertir en cliente → descartado por volumen equivalente.

### 2. Agregación a nivel de establecimiento (~9.109 puntos)

- **Decisión:** el GeoJSON de salida contiene **un punto por establecimiento** (`id_vu` + coordenada única), no una entidad por declaración. Se conservan atributos categóricos para filtros/simbología (`region`, `comuna`, `rubro`, `tipo_recepcion`, `codigo_unico_territorial`) y se derivan métricas agregadas (p. ej. `n_declaraciones`, `toneladas_totales`).
- **Razón:** 9.109 puntos son triviales de renderizar y mantienen la app fluida sin clustering; 241.687 duplicarían coordenadas de un mismo establecimiento y no aportan a la lectura territorial. Las métricas agregadas quedan listas para gráficos futuros.
- **Alternativas consideradas:** conservar las 241.687 filas y usar clustering de MapLibre → descartado por complejidad de filtrado sobre clusters y por no aportar valor; usar simplificación/teselado → descartado por sobre-ingeniería para este volumen.

### 3. Registro de capas con datos y simbología separados

- **Decisión:** introducir una configuración por capa, del estilo `CONFIG.LAYERS = [{ id, dataUrl, geometryType, sourceId, layerIds, symbology, filters }]`, donde `symbology` es un objeto propio (campo de clasificación opcional, categorías/colores, o estilo único para puntos) y `filters` describe los controles de esa capa. Extraer una función genérica de carga/render que hoy está cableada a humedales.
- **Razón:** cumple el requisito de separar datos de simbología y habilita futuros gráficos (que consumen el mismo subconjunto filtrado por capa) sin duplicar lógica.
- **Alternativas consideradas:** mantener dos bloques de código ad-hoc → descartado por deuda y riesgo de regresión; un framework de capas externo → descartado por romper la simplicidad *Zero-Server* (un solo archivo).

### 4. Simbología y filtros de la capa secundaria

- **Decisión:** puntos como capa `circle` con estilo definido en su propio objeto de simbología (color único por defecto derivado de los tokens Swiss, extensible a clasificación por `rubro`). Filtros propios: `region` (reutiliza el mismo concepto territorial) y `rubro`. Controles y conteo de la capa secundaria son independientes de los de humedales; la visibilidad se conmuta por capa. Al aplicar o modificar un filtro con resultados, la cámara se re-encuadra a la extensión de los puntos filtrados; al restablecer, vuelve a la extensión total de la capa secundaria; sin resultados no se mueve. La **carga** de la capa secundaria sigue sin mover la cámara (el encuadre inicial es el de humedales).
- **Razón:** `rubro` (20 categorías) y `region` son estables y significativos; una simbología monocroma evita comprometerse con semánticas no documentadas (p. ej. códigos de `tipo_recepcion`).
- **Alternativas consideradas:** colorear por región o por rubro desde el inicio → descartado por sobrecarga visual y por falta de paleta acordada; reutilizar los mismos `<select>` de humedales → descartado porque `proceso_humedal_urbano` no existe en la capa secundaria.

### 5. Manejo de la geometría y de las filas inválidas

- **Decisión:** el conversor descarta las 36 filas con coordenadas fuera de `[-90,90]`/`[-180,180]` o nulas y registra el descarte; emite solo `Point` válidos en EPSG:4326.
- **Razón:** evita errores de render y `fitBounds` con valores absurdos, y deja el dataset limpio y verificable.
- **Alternativas consideradas:** incluir todo y filtrar en el cliente → descartado (el conteo y la leyenda quedarían inconsistentes y el archivo sería mayor).

### 6. Compatibilidad con gráficos futuros

- **Decisión:** exponer el subconjunto filtrado y el conteo visible **por capa** (estructura de estado por capa) sin implementar gráficos ahora; los gráficos se conectarán a esa fuente luego.
- **Razón:** satisface "compatibilidad con gráficos" sin ampliar el alcance actual.
- **Alternativas consideradas:** incluir gráficos en esta Change → fuera de alcance por decisión del usuario.

## Risks / Trade-offs

- **[La refactorización de la carga a un registro genérico puede romper humedales]** → Mantener intactos `id` de DOM y de capas, congelar el comportamiento previo como caso de prueba de no-regresión y validar con `node --check` y `openspec validate`.
- **[El GeoJSON secundario puede crecer si no se controla la agregación]** → Agregar por establecimiento (~9.109 puntos) y documentar el criterio; el archivo resultante es pequeño frente a los 43,5 MB originales.
- **[Pérdida de granularidad por agregar a nivel de establecimiento]** → Se conservan métricas (`n_declaraciones`, `toneladas_totales`) y atributos categóricos; si se requiere granularidad de declaraciones, se puede regenerar el GeoJSON sin tocar el visor.
- **[Simbología monocroma puede no satisfacer una lectura temática futura]** → El objeto de simbología es extensible a clasificación por categoría sin cambiar la separación datos/simbología.
- **[Doble `fitBounds` al cargar dos capas]** → Conservar el encuadre de humedales como principal; la carga de la capa secundaria no mueve la cámara.

## Migration Plan

1. Generar `data/sinader_2024.geojson` con el script de preparación y verificar conteo/atributos.
2. Refactorizar `index.html` a configuración por capa (comportamiento de humedales idéntico).
3. Añadir la capa secundaria, controles de visibilidad y filtros propios.
4. Verificar no-regresión de humedales, tema, popups, leyenda y conteo.
5. **Rollback:** eliminar la entrada de la capa secundaria del registro de capas y su archivo de datos; el resto del visor queda como estaba.

## Open Questions

- ¿La paleta de clasificación por `rubro` se definirá al implementar los gráficos? (deferible; por defecto simbología monocroma).
