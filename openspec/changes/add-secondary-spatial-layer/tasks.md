## 1. Dataset secundario (conversión offline)

- [x] 1.1 Crear un script de preparación (fuera del navegador) que lea `gi-sinader-2024-ckan (3).xlsx` y genere `data/sinader_2024.geojson`; verificar que el archivo se crea y es JSON válido
- [x] 1.2 Descartar en la conversión las filas con `latitud`/`longitud` nulas o fuera de `[-90,90]`/`[-180,180]` (se esperan 36 descartes) y registrar el conteo; verificar que ninguna coordenada del resultado está fuera de rango
- [x] 1.3 Agregar un `Point` por establecimiento (`id_vu` + coordenada única) conservando `region`, `comuna`, `rubro`, `tipo_recepcion`, `codigo_unico_territorial` y métricas agregadas (`n_declaraciones`, `toneladas_totales`); verificar que el resultado tiene ~9.109 features y que `rubro` presenta ~20 categorías
- [x] 1.4 Verificar por inspección que el GeoJSON usa EPSG:4326 (coordenadas lon/lat) y que su tamaño es sustancialmente menor a 43,5 MB

## 2. Separación de datos y simbología

- [x] 2.1 Introducir un registro de capas (`CONFIG.LAYERS`) donde datos (URL, `sourceId`, geometría, `layerIds`) y simbología (`symbology`) son bloques independientes por capa; verificar que cada capa conserva su simbología al modificar la URL de otra
- [x] 2.2 Extraer una función genérica de carga/render a partir de la lógica actual de humedales sin alterar sus `id` (`humedales-source`, `humedales-fill`, `humedales-outline`); verificar que la capa de humedales se sigue dibujando igual
- [x] 2.3 Definir en el registro la simbología propia de la capa secundaria (`circle`, color único y radio), separada de la simbología de humedales; verificar que cambiar la simbología secundaria no altera humedales

## 3. Carga de la capa secundaria tras inicializar MapLibre

- [x] 3.1 Añadir la carga de la capa secundaria dentro de `map.on('load')` condicionada a que el estilo esté cargado; verificar que la capa secundaria aparece solo después de inicializar el mapa
- [x] 3.2 Gestionar la falla de carga de la capa secundaria con el toast de error existente sin interrumpir humedales ni el mapa base; verificar simulando un `DATA_URL` inexistente para esa capa
- [x] 3.3 Verificar que la carga de la capa secundaria no mueve la cámara (el encuadre inicial sigue correspondiendo a humedales)
- [x] 3.4 Validar la sintaxis del JavaScript embebido con `node --check`

## 4. Visibilidad y filtros de la capa secundaria

- [x] 4.1 Añadir un control de visibilidad por capa (mostrar/ocultar humedales y SINADER de forma independiente) conservando los controles existentes; verificar que ocultar/mostrar la capa secundaria no afecta a humedales ni recarga la vista
- [x] 4.2 Construir el panel de filtros propio de la capa secundaria (`region` y `rubro`) con el mecanismo genérico; verificar que los `select` se pueblan con valores únicos del dataset secundario
- [x] 4.3 Aplicar el filtrado de la capa secundaria con `map.setFilter` sobre sus propias capas y actualizar su conteo visible; verificar que filtrar la capa secundaria no altera la visualización ni los filtros de humedales
- [x] 4.4 Implementar el restablecimiento de los filtros de la capa secundaria; verificar que vuelve a mostrarse la totalidad y se restaura su conteo completo
- [x] 4.5 Exponer el conteo de entidades visibles y el subconjunto filtrado por capa en el estado de la aplicación; verificar en consola que ambos están disponibles (preparación para gráficos futuros)
- [x] 4.6 Re-encuadrar la cámara a la extensión de los puntos filtrados al aplicar o modificar un filtro de la capa secundaria; verificar con filtros de región y rubro
- [x] 4.7 Re-encuadrar a la extensión total al restablecer filtros y no mover la cámara cuando el filtro no tiene resultados; verificar los tres casos

## 5. No-regresión y validación

- [x] 5.1 Verificar que los filtros de humedales (`region`/`comuna`/`proceso`), su `fitBounds`, la leyenda, los popups y el badge de conteo se comportan igual que antes de la Change
- [x] 5.2 Verificar que el mapa base oscuro, la alternancia de tema y el botón de encuadre funcionan con la capa secundaria cargada
- [x] 5.3 Confirmar que el visor sigue siendo 100% client-side (sin backend ni claves de API) y que la capa secundaria se sirve por ruta relativa
- [x] 5.4 Validar la Change con `openspec validate "add-secondary-spatial-layer"`
