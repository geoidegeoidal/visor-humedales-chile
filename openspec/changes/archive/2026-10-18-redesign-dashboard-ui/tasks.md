## 1. Tokens y tipografía

- [x] 1.1 Añadir Inter (Google Fonts con `preconnect` y `display=swap`) y fallback a grotescas del sistema en `<head>`; verificar que la fuente se carga y que hay fallback si la CDN falla
- [x] 1.2 Reemplazar la escala `brand` por tokens `swiss` en `tailwind.config` (bg, fg, muted, accent, border, fontFamily, radios, escala tipográfica) y reflejarlos como variables CSS; verificar que las utilidades `bg-swiss-*`, `text-swiss-*`, `border-swiss-*` resuelven
- [x] 1.3 Definir variables CSS para modo claro/oscuro bajo la clase `.dark`, sin tocar `applyTheme()`; verificar que ambas variantes conservan contraste

## 2. Patrones y estilos globales

- [x] 2.1 Implementar `.swiss-grid-pattern`, `.swiss-dots`, `.swiss-diagonal` y `.swiss-noise` en `<style>` y aplicarlos a `body` y superficies `muted`; verificar que no se aplican sobre negro puro ni rojo y que no afectan el canvas del mapa
- [x] 2.2 Ajustar `body` (fondo, tipografía, color base) conservando `h-full w-full overflow-hidden`; verificar que `#map` sigue ocupando el 100% sin scroll

## 3. Rediseño del HUD

- [x] 3.1 Reestructurar el `header` con grilla, bordes gruesos, esquinas rectas, mayúsculas/tracking y rojo como señal; verificar que `btn-fit-bounds`, `btn-theme-toggle`, `icon-sun`, `icon-moon`, `layer-status-dot`, `layer-status-text` y `features-count-badge` siguen existiendo con sus mismos `id`
- [x] 3.2 Restilizar botones con inversión de color en hover y rotación de iconos, respetando `prefers-reduced-motion`; verificar interacción y que el toggle de tema sigue conmutando

## 4. Panel de filtros y leyenda

- [x] 4.1 Rediseñar el `section` de filtros con contenedor rectangular, bordes y tipografía Swiss; conservar `btn-reset-filters`, `filter-region`, `filter-comuna`, `filter-proceso` y `legend-container`
- [x] 4.2 Re-estilizar la leyenda generada por JS **solo con CSS** (selectores sobre `#legend-container`); verificar que los colores de leyenda coinciden con el mapa y que no se editó `renderLegend()`
- [x] 4.3 Re-estilizar los `select` (borde, foco rojo, tipografía) sin alterar `populateFilters()`; verificar que filtran y que el mapa se re-encuadra como antes

## 5. Toast, popups y overrides CSS

- [x] 5.1 Rediseñar el toast de error (rectangular, borde, rojo de señal) conservando `toast-error` y `toast-error-message`; verificar mostrando un error de carga simulado
- [x] 5.2 Re-estilizar `.maplibregl-popup-content` y su contenido **solo con CSS**, sin tocar `buildHumedalPopupHtml()`; verificar que el popup muestra los atributos y enlaces correctamente en claro y oscuro

## 6. Accesibilidad, responsive y no-regresión

- [x] 6.1 Añadir foco visible rojo (`focus-visible`) y targets mínimos 44px en móvil; verificar navegación por teclado
- [x] 6.2 Verificar layout responsive (móvil/tablet/escritorio) manteniendo bordes gruesos, mayúsculas y patrones; confirmar que los paneles no bloquean el mapa
- [x] 6.3 Confirmar que el `<script>` de la aplicación no cambió (diff sin cambios), que todos los `id` existen y que las specs de `geospatial-viewer` siguen cumpliéndose
- [x] 6.4 Validar sintaxis del JS embebido con `node --check` y `openspec validate "redesign-dashboard-ui"`
