## Why

Proveer una solución cartográfica web geoespacial extremadamente ligera y sin servidor (*Zero-Server*), alojada directamente en GitHub Pages con un único archivo `index.html`. Permite a los usuarios visualizar y explorar capas GeoJSON alojadas en su repositorio, alternando fluidamente entre mapas base claros y oscuros sin requerir backend, bases de datos ni claves de API pagas.

## What Changes

- Creación de un visor geoespacial en un único archivo `index.html` aplicando el principio KISS.
- Integración de MapLibre GL JS y Tailwind CSS mediante CDN.
- Configuración de fuentes de mapas base sin API Key (OpenStreetMap para modo claro y Esri Dark Canvas para modo oscuro).
- Consumo directo de capas vectoriales GeoJSON desde rutas relativas del repositorio de GitHub Pages.
- Centrado automático de la cámara mediante cálculo dinámico de `LngLatBounds`.
- Interfaz gráfica flotante (HUD) con selector de tema, indicador de estado de capa, contador de geometrías y popups de inspección de atributos.

## Capabilities

### New Capabilities
- `geospatial-viewer`: Visor web geoespacial ligero sin backend que consume GeoJSON y gestiona visualización y mapas base.

### Modified Capabilities

## Impact

- Código nuevo: `index.html` (visor principal) y `data/capa.geojson` (datos espaciales).
- Sin impacto en APIs de terceros con costo o claves secretas.
- Compatible al 100% con GitHub Pages y navegadores con soporte WebGL.
