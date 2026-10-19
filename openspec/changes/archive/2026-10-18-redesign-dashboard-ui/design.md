## Context

Véase `proposal.md` para la motivación. Modelo del sistema actual:

- **Stack:** archivo único `index.html`; Tailwind CSS Play CDN con `darkMode: 'class'`; MapLibre GL JS 4.7.1 por CDN; JavaScript vanilla. Sin build, sin bundler, sin framework de componentes.
- **Tokens actuales:** definidos inline en `tailwind.config` (solo escala `brand` sky) y utilidades `slate`/`sky` dispersas en el markup; sin variables CSS ni escala tipográfica propia. Radios `rounded-xl/2xl`, sombras `shadow-xl`, fondos `backdrop-blur` con `bg-white/90 dark:bg-slate-900/90`.
- **Arquitectura de UI:** sin componentes; tres bloques flotantes sobre el mapa: `header` (HUD: título, botones, estado/conteo), `section` (filtros + leyenda) y `div` de toast. Los popups y la leyenda se generan desde JavaScript.
- **Restricciones del cambio:** preservar comportamiento, mantener todos los `id`, no alterar la lógica de MapLibre, **no modificar funciones JavaScript**, tocar solo estructura y estilos.
- **Dato crítico:** el markup de la leyenda (`#legend-container`) y de los popups (`.maplibregl-popup-content`) se construye dentro de funciones JS que no se pueden editar; su re-estilizado debe ser **exclusivamente por CSS**.

## Goals / Non-Goals

**Goals:**
- Aplicar el sistema Swiss (paleta B/N + `#FF3000`, Inter, esquinas rectas, bordes gruesos, mayúsculas, tracking, grilla visible, patrones de textura).
- Centralizar tokens y utilidades para eliminar estilos de una sola vez y facilitar mantenimiento.
- Preservar íntegros el DOM funcional, los `id`, el `<script>` de la aplicación y el comportamiento de MapLibre.
- Mantener y mejorar accesibilidad (contraste, foco visible, targets táctiles) y respuesta responsive.

**Non-Goals:**
- No se reescriben funciones JS ni se migra a un framework o build step.
- No se añaden nuevas funcionalidades, capas, filtros ni vistas.
- No se rediseñan los popups por JavaScript: solo se restilizan por CSS.
- No se introducen imágenes, iconografía nueva ni librerías de componentes.

## Decisions

### 1. Centralizar tokens en `tailwind.config` + variables CSS
- **Decisión:** Extender `tailwind.config.theme.extend` con `colors.swiss` (`bg #FFFFFF`, `fg #000000`, `muted #F2F2F2`, `accent #FF3000`, `border #000000`), `fontFamily.sans: ['Inter', ...]`, `borderRadius.none` como base y una escala tipográfica fluida; reflejar los mismos valores como custom properties (`--swiss-*`) para usarlos en CSS plano y en el modo oscuro.
- **Alternativas consideradas:** Seguir con utilidades `slate/sky` por bloque; compilar Tailwind con un build.
- **Razón:** Una sola fuente de verdad, coherente con el CDN ya usado y sin introducir tooling.

### 2. Preservar IDs y el `<script>` de la aplicación intacto
- **Decisión:** No editar ninguna función JavaScript. Todo el rediseño se hace en `<head>` (fuente, config, `<style>`), en el `<body>` y en el markup estático de `header`/`section`/toast.
- **Alternativas consideradas:** Refactorizar el markup generado por JS (leyenda/popups) para usar clases Swiss.
- **Razón:** Es una restricción explícita del cambio; evita regresiones en MapLibre, filtros y popups.

### 3. Re-estilizar markup generado por JS solo con CSS
- **Decisión:** Aplicar reglas CSS de mayor especificidad o `!important` a `#legend-container` (y sus utilidades `text-slate-600`, `text-slate-400`) y a `.maplibregl-popup-content` (y descendientes) para imponer tipografía, colores, bordes y radios Swiss. No tocar `renderLegend()`, `buildHumedalPopupHtml()` ni `populateFilters()`.
- **Alternativas consideradas:** Cambiar los `className` en las funciones JS.
- **Razón:** Cumple la restricción de no modificar JS. Como Tailwind Play CDN inyecta sus reglas en tiempo de ejecución, se usan selectores con `id`/`!important` para garantizar precedencia.

### 4. Modo claro/oscuro reinterpretado en clave Swiss
- **Decisión:** Mantener la clase `dark` y la lógica de conmutación existentes. Claro = fondo blanco, texto negro, bordes negros, rojo de señal; Oscuro = fondo negro, texto blanco, bordes blancos, mismo rojo. Se implementa con variables CSS que cambian bajo `.dark`, dejando intacto `applyTheme()`.
- **Alternativas consideradas:** Eliminar el modo oscuro para ceñirse al blanco puro.
- **Razón:** La spec funcional exige alternancia claro/oscuro y clases oscuras; eliminarla rompería specs existentes.

### 5. Grilla visible, asimetría y texturas
- **Decisión:** Usar `border-2/border-4` negro, separadores horizontales y una columna flotante izquierda de ancho fijo (`md:w-80`) que expresa una retícula asimétrica respecto al mapa. Añadir utilidades `.swiss-grid-pattern`, `.swiss-dots`, `.swiss-diagonal` y `.swiss-noise` (CSS puro) y aplicarlas a superficies `muted` y al `body`, nunca sobre negro puro ni sobre el rojo.
- **Alternativas consideradas:** Fondo liso sin textura.
- **Razón:** Las texturas aportan profundidad sin sombras, fiel al sistema.

### 6. Tipografía y escala
- **Decisión:** Cargar Inter (Google Fonts, `display=swap`, pesos 400/500/700/900) con `preconnect`; titulares en mayúsculas `tracking-tighter` con escala fluida; etiquetas pequeñas `tracking-widest`; cuerpo 400/500. Fallback a grotescas del sistema.
- **Alternativas consideradas:** Usar la sans por defecto del sistema.
- **Razón:** Inter es la fuente indicada por el sistema; el fallback protege ante fallo de red.

### 7. Movimiento y accesibilidad
- **Decisión:** Transiciones `duration-150/200 ease-out`; inversiones de color, rotación de iconos y traslación de 1px; `prefers-reduced-motion` desactiva animaciones; foco `focus-visible` con anillo rojo de 2px; targets mínimos 44×44px en móvil.
- **Alternativas consideradas:** Animaciones suaves tipo spring.
- **Razón:** El sistema pide movimiento mecánico e inmediato y accesibilidad alta.

## Alcance exacto de archivos y bloques

Archivo único: `index.html`. Ningún otro archivo se modifica.

| Bloque | Cambio | Tipo | IDs afectados |
|---|---|---|---|
| `<head>` | Añadir Inter (`preconnect` + `link`), ampliar `tailwind.config` (tokens Swiss), ampliar `<style>` (variables, patrones, overrides de leyenda/popup, foco, reduced-motion) | Estructura/estilos | — |
| `<head>` → `tailwind.config` | Sustituir escala `brand` por tokens `swiss` | Config (no función JS) | — |
| `<body>` | Fondo/textura noise, tipografía y color base; conservar `h-full w-full overflow-hidden` | Estilos | — |
| `#map` | **Sin cambios** (contenedor y dimensiones intactos) | — | `map` |
| `header` (HUD) | Reestructurar composición (grilla, tipografía, bordes, rojo de señal); conservar botones, estado y conteo | Estructura/estilos | `btn-fit-bounds`, `btn-theme-toggle`, `icon-sun`, `icon-moon`, `layer-status-dot`, `layer-status-text`, `features-count-badge` |
| `section` (filtros + leyenda) | Restilizar contenedor y selects; conservar controles y contenedor de leyenda | Estructura/estilos | `btn-reset-filters`, `filter-region`, `filter-comuna`, `filter-proceso`, `legend-container` |
| Toast | Restilizar (rectangular, borde, rojo de señal); conservar semántica y mensaje | Estilos | `toast-error`, `toast-error-message` |
| `<script>` aplicación | **Sin cambios** — ninguna función, `CONFIG`, filtros, popups ni lógica MapLibre | — | — |

## Risks / Trade-offs

- **[Riesgo: orden de inyección de Tailwind CDN]** → Reglas de override con `id`/`!important` y variables CSS; verificar visualmente en claro y oscuro.
- **[Riesgo: estilos de controles nativos (`select`) limitados por navegador]** → Estilizar contenedor, borde, tipografía y foco; aceptar diferencias menores del control nativo.
- **[Riesgo: markup generado por JS con utilidades `slate`]** → Cubrirlo por CSS con selectores de `#legend-container` y `.maplibregl-popup-content`; no editar JS.
- **[Riesgo: contraste del rojo `#FF3000` sobre blanco en texto pequeño]** → Usar el rojo como borde/fondo de señal con texto blanco, o rojo solo en elementos ≥18px/negrita; validar AA.
- **[Riesgo: dependencia de Google Fonts]** → `display=swap` y fallback a grotescas del sistema.
- **[Riesgo: paneles flotantes que tapan el mapa en móvil]** → Mantener `max-h` + scroll interno y anchos `w-80`/full responsive; el contenedor `#map` no se altera.
