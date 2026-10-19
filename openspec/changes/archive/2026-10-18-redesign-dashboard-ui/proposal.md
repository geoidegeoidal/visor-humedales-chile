## Why

La interfaz actual del visor usa un lenguaje visual genérico (tarjetas redondeadas con blur, acentos sky/slate, sombras suaves) que no responde a un sistema de diseño definido. El objetivo es aplicar el sistema **Swiss International (International Typographic Style)** para dar una identidad coherente, mantenible y de alta legibilidad a la interfaz del dashboard, sin tocar el comportamiento funcional.

## What Changes

- Rediseñar la presentación visual del HUD, el panel de filtros/leyenda y el aviso de error, aplicando el sistema Swiss: paleta blanco/negro con rojo `#FF3000` como única señal, esquinas rectas (`radius 0`), bordes gruesos, tipografía Inter en mayúsculas con tracking, jerarquía por escala y **espacio negativo activo**.
- Centralizar los tokens del sistema (colores, tipografía, radios, bordes) en `tailwind.config` y variables CSS, más utilidades de textura (grid 24px, dots 16px, diagonales, noise) en el bloque `<style>`.
- Reestructurar el markup estático de `<head>`, `<body>`, `header`, `section` (filtros/leyenda) y toast cuando sea necesario para expresar la grilla y la asimetría; el HTML generado por JavaScript se re-estiliza **solo por CSS**.
- Incorporar la tipografía Inter (Google Fonts) respetando el rendimiento (peso/`display`).
- Preservar el modo claro/oscuro existente reinterpretándolo en clave Swiss (claro = blanco/negro; oscuro = negro/blanco), manteniendo la conmutación y la alternancia de mapas base.

**BREAKING**: ninguno. No hay cambios de comportamiento observable.

## Capabilities

### New Capabilities

### Modified Capabilities

> Ninguna. Es un refactor de presentación sin cambios de comportamiento; por eso el change declara `skip_specs: true` en `.openspec.yaml`. Todas las specs funcionales existentes de `geospatial-viewer` deben seguir cumpliéndose sin cambios.

## Impact

- Único archivo afectado: `index.html`.
- Secciones modificadas: `<head>` (fuente, tokens de Tailwind, `<style>`), `<body>` (fondo/tipografía/textura), `header` (HUD), panel de filtros y leyenda (`section`), toast de error.
- **No se modifica** la lógica JavaScript ni las funciones existentes; el `<script>` de la aplicación permanece intacto.
- **Se preservan todos los `id`**: `map`, `btn-fit-bounds`, `btn-theme-toggle`, `icon-sun`, `icon-moon`, `layer-status-dot`, `layer-status-text`, `features-count-badge`, `btn-reset-filters`, `filter-region`, `filter-comuna`, `filter-proceso`, `legend-container`, `toast-error`, `toast-error-message`.
- **No se altera la lógica de MapLibre** (estilo base, fuentes raster, capas, `fitBounds`, filtros, popups).
- Dependencias: se añade Inter vía Google Fonts; se mantienen MapLibre GL JS y Tailwind CSS por CDN.
