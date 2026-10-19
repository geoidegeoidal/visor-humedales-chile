## Context

Véase `proposal.md` para la motivación. El visor existente es un único `index.html` que ya integra MapLibre GL JS y Tailwind CSS por CDN. El mapa se crea con `new maplibregl.Map({ container: 'map', ... })` sobre el contenedor `<div id="map" class="h-full w-full">`, y el estilo inicial (`initialMapStyle`) ya declara las fuentes raster de OpenStreetMap (claro) y Esri Canvas Dark (oscuro) como capas conmutables por visibilidad. El encuadre y zoom actuales provienen de `CONFIG.INITIAL_CENTER` (`[-70.655, -33.450]`) y `CONFIG.INITIAL_ZOOM` (`12`).

## Goals / Non-Goals

**Goals:**
- Fijar el estado inicial del mapa base en modo oscuro sobre Chile (zoom 4) reutilizando el contenedor `#map`.
- Garantizar ocupación completa del espacio del lienzo.
- Mantener intactos el HUD, el conmutador de tema, el botón de centrado y los popups.

**Non-Goals:**
- No añadir nuevos mapas base, capas vectoriales ni dependencias.
- No reestructurar el HUD ni renombrar el contenedor `#map`.
- No modificar la lógica de carga de GeoJSON ni de popups existente.

## Decisions

### 1. Reutilizar el contenedor `#map` y las capas pre-cargadas del estilo
- **Decisión:** Conservar el patrón actual de un único `initialMapStyle` con las capas clara y oscura, alternando visibilidad con `setLayoutProperty`. El mapa se sigue montando sobre el contenedor `#map` existente.
- **Alternativas consideradas:** Recrear el estilo con `map.setStyle()` al iniciar en oscuro.
- **Razón:** Mantiene el encuadre, los listeners y futuras capas sin recargar; cero parpadeo y mínima intervención sobre el HUD.

### 2. Configuración del encuadre inicial vía `CONFIG`
- **Decisión:** Ajustar `CONFIG.INITIAL_CENTER` a las coordenadas de Chile (aprox. `[-71.5, -35.7]`, formato `[lng, lat]`) y `CONFIG.INITIAL_ZOOM` a `4`.
- **Alternativas consideradas:** Calcular límites por `fitBounds` sobre una geometría de Chile embebida.
- **Razón:** Menor complejidad (KISS) y coincidencia exacta con el requisito de centro y zoom solicitados.

### 3. Arranque en tema oscuro coherente
- **Decisión:** Aplicar el estado oscuro (clases de tema en la interfaz y visibilidad de la capa base oscura) durante la inicialización, sin requerir clic del usuario.
- **Alternativas consideradas:** Dejar el tema claro por defecto y que el usuario conmute.
- **Razón:** Evita parpadeo claro→oscuro y cumple el estado inicial exigido por la spec.

### 4. Ocupación total del espacio
- **Decisión:** Mantener `h-full` en `html`/`body` y `h-full w-full` en `#map`, verificando que no existan márgenes ni scroll que reduzcan el lienzo.
- **Alternativas consideradas:** Dimensionar con `100vh`/`100vw` en línea.
- **Razón:** Se apoya en las utilidades Tailwind ya presentes y respeta el layout actual.

## Risks / Trade-offs

- **[Riesgo: parpadeo claro→oscuro al arrancar]** → Aplicar las clases de tema antes de crear/renderizar el mapa.
- **[Riesgo: el encuadre automático de la capa GeoJSON sobrescribe Chile/zoom 4]** → Es comportamiento aceptado por la spec (Scenario "Compatibilidad con el encuadre automático de capas"): la vista Chile/zoom 4 es el estado inicial previo; el ajuste a la extensión de los datos ocurre al cargar la capa.
- **[Riesgo: zoom 4 oculta detalle de entidades puntuales]** → Intencional: es una vista territorial de país, no de detalle local.
