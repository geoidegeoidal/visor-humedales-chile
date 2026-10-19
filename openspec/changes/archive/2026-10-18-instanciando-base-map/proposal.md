## Why

El visor necesita una instanciación explícita y predecible de su mapa base: un lienzo MapLibre GL JS en modo oscuro, encuadrado inicialmente en Chile con zoom 4, montado sobre el contenedor `#map` ya existente y ocupando todo el espacio disponible. Hoy la vista inicial arranca sobre coordenadas locales de ejemplo (`[-70.655, -33.450]`, zoom 12), lo que no refleja el encuadre territorial deseado ni garantiza un estado inicial oscuro coherente.

## What Changes

- Instanciar el mapa base oscuro por defecto al inicializar el visor (sin marcas de agua ni API Key).
- Reutilizar el contenedor `#map` existente como punto de montaje del lienzo.
- Establecer la vista inicial centrada en Chile con zoom inicial 4.
- Garantizar que el lienzo del mapa ocupe el 100% del espacio disponible (ancho y alto).
- Mantener intactos el panel/HUD flotante y todos los componentes de interfaz existentes (selector de tema, botones, indicadores y popups).
- Ajustar la configuración inicial (`CONFIG`) para reflejar el nuevo centro y zoom, conservando la conmutación claro/oscuro ya implementada.

## Capabilities

### New Capabilities

### Modified Capabilities
- `geospatial-viewer`: se modifica el comportamiento de instanciación del mapa base para exigir estado inicial oscuro, contenedor `#map` reutilizado, encuadre inicial en Chile, zoom 4 y ocupación completa del espacio, sin alterar los componentes de interfaz existentes.

## Impact

- Código afectado: `index.html` (bloque `CONFIG`, inicialización de `new maplibregl.Map(...)` y clases del contenedor `#map`).
- Sin nuevas dependencias: se reutilizan MapLibre GL JS y Tailwind CSS ya integrados por CDN en el visor existente.
- Sin impacto en backend, APIs de pago ni claves de acceso.
- Los componentes de interfaz (HUD superior, conmutador de tema, botón de centrado, popups) permanecen sin cambios funcionales.
- Nota de alcance: el mapa base de la especificación original ya contemplaba alternancia claro/oscuro; este cambio fija el estado inicial oscuro y el encuadre territorial, y añade explícitamente la reutilización del contenedor `#map` y la ocupación del espacio.
