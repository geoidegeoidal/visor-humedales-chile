## Context

Véase `proposal.md` para la motivación. El visor es un único `index.html` (MapLibre GL JS + Tailwind por CDN) que hoy carga `data/capa.geojson` (capa de demostración) y ya resuelve mapa base oscuro, conmutación de tema, `fitBounds` y popups. El dataset de humedales es `MultiPolygon` en EPSG:4326 con 11 atributos planos y sin valores nulos. Se confirmó que el archivo es UTF-8 válido con acentos correctos.

## Goals / Non-Goals

**Goals:**
- Cargar el dataset real de humedales como capa activa y renderizar sus polígonos con simbología por `proceso_humedal_urbano`.
- Proveer filtrado combinado por `region`, `comuna` y `proceso_humedal_urbano` sin backend.
- Exponer un popup de atributos oficiales con enlaces a fuentes.
- Mantener la simplicidad de archivo único (KISS) y los componentes existentes.

**Non-Goals:**
- No añadir backend, servidor de teselas vectoriales ni dependencias nuevas.
- No implementar edición/dibujo de geometrías ni análisis espacial (áreas, intersecciones).
- No introducir búsqueda de texto libre ni clustering.

## Decisions

### 1. Sustituir la capa de demostración por la de humedales
- **Decisión:** Configurar `CONFIG.DATA_URL = './data/humedales_urbanos.geojson'` y adaptar el render a polígonos; retirar las capas de líneas/puntos de demostración.
- **Alternativas consideradas:** Mantener ambas capas (demo + humedales).
- **Razón:** El visor sirve a un único dataset temático; simplifica filtros, leyenda y conteo. Se conserva la lógica de carga/errores existente.

### 2. Simbología con expresión data-driven en una sola capa
- **Decisión:** Una capa `fill` y su `line` con `fill-color`/`line-color` como expresión `['match', ['get','proceso_humedal_urbano'], 'Municipal', <color1>, 'de Oficio', <color2>, <colorFallback>]`.
- **Alternativas consideradas:** Múltiples capas con `filter` por categoría.
- **Razón:** Una sola capa mantiene la leyenda, los filtros y los popups alineados y evita duplicar listeners; el color por defecto cubre valores desconocidos.

### 3. Filtrado con `map.setFilter` combinado
- **Decisión:** Representar la selección como condiciones `['all', ...]` (una por criterio activo) y aplicarlas con `map.setFilter('humedales-fill', expr)` (y su capa de línea). Los `select` se pueblan desde valores únicos de los datos; `comuna` se limita a las comunas de la región elegida.
- **Alternativas consideradas:** Filtrar el `FeatureCollection` y usar `setData`.
- **Razón:** `setFilter` es más simple, inmediato y mantiene los datos intactos; el volumen (107 features) es trivial.

### 4. Normalización y metadatos en la carga
- **Decisión:** Aplicar `trim` a los campos de texto al cargar y calcular en memoria: lista de regiones (ordenada), mapa región→comunas, categorías de proceso y conteos.
- **Alternativas consideradas:** Servir datos ya limpios.
- **Razón:** El dataset tiene espacios residuales en `url_res_bcn`, `resolucion` y `nombre_humedal`; normalizar en cliente evita tocar el archivo fuente.

### 5. Panel de filtros y leyenda como componentes nuevos
- **Decisión:** Añadir una tarjeta flotante (bajo el HUD) con los `select` de filtros, botón de restablecer, leyenda de categorías y el conteo dinámico, reutilizando el estilo Tailwind existente.
- **Alternativas consideradas:** Colocar filtros dentro del HUD existente.
- **Razón:** Mantiene intacta la cabecera actual y da espacio a los controles sin romper el layout móvil.

### 6. Re-encuadre de la cámara al filtrar
- **Decisión:** Tras aplicar los filtros, recalcular la extensión (`calculateBounds`) sobre el subconjunto filtrado y ejecutar `map.fitBounds` con padding y `maxZoom` acotado; con filtros activos pero sin resultados, no mover la cámara; al restablecer, encuadrar a la extensión total.
- **Alternativas consideradas:** No mover la cámara (deja al usuario buscar el resultado) o filtrar el `FeatureCollection` y usar `setData` para que MapLibre recalcule.
- **Razón:** El filtrado es más útil si lleva la vista al resultado; reutiliza el cálculo de bounds existente y evita reinyectar datos.

## Risks / Trade-offs

- **[Riesgo: comuna con 65 valores y dependencia de región]** → `select` dependiente (comuna se rellena según región) para acotar opciones; sin búsqueda de texto en esta iteración.
- **[Riesgo: popups con HTML de campos no confiables]** → Escapar valores de texto antes de componer el HTML del popup.
- **[Riesgo: color por categoría poco accesible]** → Usar dos colores de contraste suficiente y confirmarlo con la leyenda.
- **[Riesgo: rendimiento con 79k vértices]** → Aceptable para una sola capa de polígonos; si fuera necesario, simplificar geometría fuera de alcance.
