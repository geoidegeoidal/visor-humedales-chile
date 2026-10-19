# Visor Humedales Urbanos · Chile

Visor geoespacial web, **100% del lado del cliente** (sin servidor ni claves de API), para explorar, filtrar y analizar los **Humedales Urbanos de Chile** junto con el registro **SINADER 2024** de declaraciones de residuos de establecimientos.

> Página pública: https://julloa.space/visor-humedales-chile/
>
> Alternativa: https://geoidegeoidal.github.io/visor-humedales-chile/

## ¿Qué muestra?

- **Humedales Urbanos** (107 polígonos): región, comuna, superficie, proceso de declaratoria y resolución.
- **SINADER 2024** (~9.105 puntos): establecimientos generadores de residuos, rubro, declaraciones y toneladas declaradas.

## Funcionalidades

- Mapa interactivo con MapLibre GL y mapas base claro/oscuro.
- Filtros independientes por capa (región, comuna, proceso; región y rubro para SINADER) con re-encuadre automático.
- Popups con los atributos de cada entidad.
- Exportación del subconjunto filtrado a **GeoJSON** y **Shapefile ZIP**.
- Áreas de influencia (buffers) en metros, individuales o disueltas, calculadas en un Web Worker.
- Panel **Dashboard** con tres gráficos (Chart.js) sincronizados con el mapa mediante un estado de filtros único (*cross-filter*).

## Cómo verlo

### En línea

Abre la dirección principal indicada arriba (o su alternativa).

### En tu computadora

La página carga los datos `.geojson` con `fetch`, por lo que necesita servirse desde un servidor local (no basta con abrir el archivo directamente). Por ejemplo:

```bash
python -m http.server 8000
```

Luego abre `http://localhost:8000/`.

## Tecnologías

- [MapLibre GL JS](https://maplibre.org/) para el mapa.
- [Tailwind CSS](https://tailwindcss.com/) para la interfaz.
- [Chart.js](https://www.chartjs.org/) para los gráficos.
- [Turf.js](https://turfjs.org/) y [polygon-clipping](https://github.com/mfogel/polygon-clipping) para las áreas de influencia.
- [@mapbox/shp-write](https://github.com/mapbox/shp-write) para exportar Shapefile.

Todas las dependencias se cargan por CDN y solo cuando se usan.

## Estructura del proyecto

```
index.html                        Aplicación completa (interfaz + lógica)
buffer-worker.js                  Cálculo de áreas de influencia en segundo plano
data/humedales_urbanos.geojson    Capa de humedales urbanos
data/sinader_2024.geojson         Capa SINADER 2024
scripts/build-sinader-geojson.ps1 Conversión offline del Excel a GeoJSON
openspec/                         Planificación y especificaciones del proyecto
```

## Fuentes de datos

- **Humedales Urbanos**: Ministerio del Medio Ambiente (MMA), Sistema de Humedales Urbanos.
- **SINADER 2024**: Registro de Emisiones y Transferencias de Residuos / declaraciones de residuos (ventanilla única).

Los datos se sirven como archivos estáticos dentro del repositorio; no se consultan servicios externos en tiempo de ejecución.

## Aviso

Proyecto con fines de visualización y análisis territorial. Para decisiones oficiales, consulta siempre las fuentes originales.
