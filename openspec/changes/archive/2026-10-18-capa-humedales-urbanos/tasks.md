## 1. Datos y configuración

- [x] 1.1 Copiar el dataset a `data/humedales_urbanos.geojson` y verificar que el archivo existe con 107 features
- [x] 1.2 Actualizar `CONFIG.DATA_URL` a `./data/humedales_urbanos.geojson` y verificar por inspección que apunta a la nueva ruta
- [x] 1.3 Normalizar al cargar (trim de strings) y calcular en memoria regiones únicas, mapa región→comunas y categorías de proceso; verificar en consola que las 15 regiones y 2 categorías se detectan

## 2. Renderizado y simbología por proceso

- [x] 2.1 Reemplazar las capas de demostración por una capa `fill` y su `line` para los polígonos de humedales; verificar que los 107 polígonos se dibujan
- [x] 2.2 Aplicar color data-driven según `proceso_humedal_urbano` con color por defecto para valores desconocidos; verificar visualmente que `Municipal` y `de Oficio` se distinguen
- [x] 2.3 Añadir la leyenda de categorías (color ↔ categoría) y verificar que coincide con los colores del mapa

## 3. Filtros interactivos

- [x] 3.1 Construir el panel de filtros con `select` de `region`, `comuna` (dependiente de región) y `proceso_humedal_urbano`, más botón de restablecer
- [x] 3.2 Implementar el filtrado combinado con `map.setFilter(['all', ...])` y verificar que cada criterio reduce las entidades visibles
- [x] 3.3 Actualizar el conteo de entidades según el resultado filtrado y verificar que coincide con el número de humedales visibles
- [x] 3.4 Re-encuadrar la cámara a la extensión de los humedales filtrados al aplicar filtros (fitBounds con transición), volver a la extensión total al restablecer y no mover la cámara si no hay resultados

## 4. Popup de atributos

- [x] 4.1 Implementar el popup al hacer clic con `nombre_humedal`, `cod_humedal`, `region`, `comuna`, `ha`, `proceso_humedal_urbano`, `resolucion` y enlaces a `url_res_bcn` y `url_simbio`
- [x] 4.2 Escapar los valores de texto del popup y verificar que no se rompe el HTML con caracteres especiales (tildes, `&`, `°`)

## 5. Validación

- [x] 5.1 Validar con `node --check` la sintaxis del JavaScript embebido
- [x] 5.2 Verificar que el mapa base oscuro, el conmutador de tema y el botón de centrado siguen funcionando tras los cambios
