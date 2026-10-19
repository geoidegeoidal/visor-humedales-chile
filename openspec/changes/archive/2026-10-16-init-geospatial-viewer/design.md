## Context

El visor se concibe como una solución Zero-Server orientada a despliegue estático en GitHub Pages. La aplicación carece de capas de servidor, middleware, bases de datos o servicios backend. Toda la lógica de renderizado, parsing de geometrías e interacción transcurre en el navegador web del usuario. Véase `proposal.md` para la motivación general.

## Goals / Non-Goals

**Goals:**
- Estructurar el visor en un único archivo `index.html` (principio KISS).
- Integrar MapLibre GL JS y Tailwind CSS mediante CDN.
- Utilizar exclusivamente mapas base públicos, libres y sin marcas de agua de API Key (OpenStreetMap y Esri Canvas Dark).
- Permitir la alternancia instantánea entre temas claro y oscuro sin recarga de página ni re-renderizado de fuentes vectoriales.
- Cargar capas GeoJSON alojadas en el mismo repositorio evitando restricciones de CORS.

**Non-Goals:**
- No implementar paneles complejos de edición de geometrías o dibujo en mapa.
- No incluir soporte para ingesta de formatos binarios pesados (Shapefiles en ZIP, GeoTIFFs masivos o bases de datos espaciales remotas).
- No depender de proveedores de teselas con planes de pago o tokens de acceso restringidos.

## Decisions

### 1. Pre-carga de mapas base en un único estilo MapLibre
- **Decisión:** Declarar las fuentes de OpenStreetMap y Esri Canvas Dark en el objeto `initialMapStyle` inicial, controlando su visibilidad mediante `map.setLayoutProperty(id, 'visibility', ...)`.
- **Alternativas consideradas:** Usar `map.setStyle()`, lo cual hubiera obligado a destruir y recrear todas las capas GeoJSON y listeners de eventos del usuario en cada cambio de tema.
- **Razón:** Cero parpadeo, transición inmediata e integridad permanente de las capas del usuario.

### 2. Consumo de GeoJSON relativo al origen
- **Decisión:** Usar `fetch('./data/capa.geojson')` como ruta relativa configurable en `CONFIG.DATA_URL`.
- **Alternativas consideradas:** Drag & drop de archivos locales o URLs absolutas de APIs externas.
- **Razón:** En GitHub Pages (`https://<usuario>.github.io/<repo>/`), la ruta relativa garantiza que el origen sea idéntico, neutralizando problemas de CORS sin requerir proxies.

### 3. Tailwind CSS Play CDN con clase `dark`
- **Decisión:** Configurar Tailwind en modo clase (`darkMode: 'class'`) vía CDN Play.
- **Alternativas consideradas:** Compilación previa con Node.js / Vite / CLI.
- **Razón:** Máxima simplicidad Zero-Server y mantenimiento KISS en un único archivo sin herramientas de build.

## Risks / Trade-offs

- **[Riesgo: Datasets GeoJSON grandes]** → Parsear archivos de más de 20MB en el hilo principal de JavaScript puede ralentizar el navegador. *Mitigación:* Recomendar capas optimizadas y simplificadas para visualización web.
- **[Riesgo: Conectividad a CDNs externos]** → Si las CDNs de unpkg o tailwindcss fallan, la carga inicial se interrumpe. *Mitigación:* Se emplean CDNs con alta disponibilidad global y versionado fijo.
- **[Riesgo: Políticas de uso de OpenStreetMap]** → Peticiones intensivas a `tile.openstreetmap.org` pueden sufrir límites si el tráfico es masivo. *Mitigación:* Para proyectos de producción a gran escala, se puede sustituir la URL por teselas vectoriales autohospedadas con PMTiles.
