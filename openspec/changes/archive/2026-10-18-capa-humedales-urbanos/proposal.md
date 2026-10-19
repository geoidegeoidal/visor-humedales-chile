## Why

El visor actual carga una capa GeoJSON de demostración genérica. El proyecto cuenta ahora con el dataset real de Humedales Urbanos de Chile (107 humedales declarados, `MultiPolygon` en EPSG:4326), que requiere visualización temática, filtrado por territorio y consulta de atributos oficiales. Sin esta capa, el visor no aporta valor sobre los datos que realmente interesa explorar.

## What Changes

- Incorporar la capa GeoJSON `data/humedales_urbanos.geojson` (107 humedales) en reemplazo de la capa de demostración `data/capa.geojson`.
- Renderizar los polígonos con **simbología categórica según `proceso_humedal_urbano`** (`Municipal` vs `de Oficio`) y una leyenda asociada.
- Añadir un panel de **filtros interactivos** por `region`, `comuna` y `proceso_humedal_urbano`, con restablecimiento y conteo dinámico de entidades visibles.
- **Re-encuadrar automáticamente la cámara** a la extensión de los humedales filtrados al aplicar filtros, volviendo a la extensión total al restablecer.
- Mostrar **popups de atributos** al hacer clic: `nombre_humedal`, `cod_humedal`, `region`, `comuna`, `ha`, `proceso_humedal_urbano`, `resolucion` y enlaces a `url_res_bcn` / `url_simbio`.
- Normalizar los datos al cargar (recorte de espacios) para evitar valores sucios en filtros y popups.
- Conservar el mapa base oscuro, el conmutador de tema, el encuadre y el HUD existentes.

## Capabilities

### New Capabilities

### Modified Capabilities
- `geospatial-viewer`: se añaden requisitos para la carga y renderizado del dataset de humedales urbanos, su simbología por proceso de declaratoria, el filtrado interactivo por atributos y la inspección de atributos del humedal.

## Impact

- Código afectado: `index.html` (configuración `CONFIG`, capa de datos, simbología, panel de filtros, leyenda y popups).
- Datos: nuevo `data/humedales_urbanos.geojson` (copia del dataset entregado en la raíz).
- Sin nuevas dependencias ni backend; se reutilizan MapLibre GL JS y Tailwind CSS por CDN.
- Los componentes de interfaz existentes (HUD, conmutador de tema, botón de centrado) permanecen funcionales; se añade un panel de filtros.
- Supuesto de alcance: la capa de humedales **reemplaza** a la capa de demostración como capa activa del visor.
