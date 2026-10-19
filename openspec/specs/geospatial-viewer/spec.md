# geospatial-viewer Specification

## Purpose
Proporciona capacidades de visualización y consulta cartográfica web interactiva en el cliente sin requerir servicios de backend ni claves de API propietarias.

## Requirements

### Requirement: Consumo de datos GeoJSON locales o de repositorio
The system SHALL cargar y renderizar capas vectoriales en formato GeoJSON servidas desde rutas relativas del repositorio estático sin generar errores de CORS.

#### Scenario: Carga exitosa de capa GeoJSON
- **WHEN** la aplicación inicializa el mapa y realiza la petición al archivo GeoJSON configurado
- **THEN** el sistema renderiza polígonos, líneas y puntos en el lienzo del mapa y actualiza el contador de entidades en la interfaz de usuario

#### Scenario: Falla de carga de capa GeoJSON
- **WHEN** el archivo GeoJSON no existe o responde con un código de error HTTP
- **THEN** el sistema muestra una notificación visible de error al usuario sin interrumpir el funcionamiento del mapa base

### Requirement: Alternancia de mapas base sin API Key
The system MUST proveer mapas base para modo claro y modo oscuro que no requieran claves de acceso o autenticación, permitiendo conmutar entre ambos sin recargar la vista.

#### Scenario: Cambio a modo oscuro
- **WHEN** el usuario hace clic en el conmutador de tema estando en modo claro
- **THEN** el sistema oculta la capa clara, hace visible la capa base oscura de Esri Canvas junto con sus etiquetas, y aplica las clases oscuras a la interfaz

#### Scenario: Cambio a modo claro
- **WHEN** el usuario hace clic en el conmutador de tema estando en modo oscuro
- **THEN** el sistema oculta las capas oscuras, hace visible la capa base de OpenStreetMap y restaura el tema claro en la interfaz

### Requirement: Ajuste automático de encuadre espacial
The system SHALL calcular la extensión delimitadora (bounding box) de los datos espaciales y ajustar la cámara automáticamente.

#### Scenario: Centrado automático al cargar datos
- **WHEN** el archivo GeoJSON es procesado correctamente
- **THEN** el mapa ejecuta una transición animada de cámara hacia la extensión delimitadora de todas las geometrías presentes

#### Scenario: Centrado manual por botón
- **WHEN** el usuario pulsa el botón de centrado rápido en la barra de herramientas
- **THEN** el mapa re-encuadra la vista a la extensión delimitadora calculada previamente

### Requirement: Inspección interactiva de atributos mediante popups
The system MUST permitir la inspección de atributos de cualquier entidad geográfica al hacer clic sobre ella.

#### Scenario: Clic en entidad vectorial
- **WHEN** el usuario hace clic sobre un punto, línea o polígono de la capa activa
- **THEN** el sistema despliega una ventana emergente en la coordenada pulsada listando las propiedades y valores de la entidad

### Requirement: Instanciación del mapa base oscuro
The system SHALL instanciar el lienzo de MapLibre GL JS sobre el contenedor `#map` existente, mostrando un mapa base oscuro visible por defecto y ocupando todo el espacio disponible sin alterar el panel ni los componentes de interfaz existentes.

#### Scenario: Montaje sobre el contenedor existente
- **WHEN** la aplicación inicializa el visor
- **THEN** el mapa se monta dentro del contenedor `#map` ya presente y no se crean contenedores adicionales ni se modifica la estructura del panel o HUD existente

#### Scenario: Estado inicial en modo oscuro
- **WHEN** el visor carga por primera vez
- **THEN** la capa base oscura es visible y la capa clara permanece oculta, con las clases de tema oscuro aplicadas a la interfaz

#### Scenario: Ocupación total del espacio disponible
- **WHEN** el contenedor `#map` es renderizado en el navegador
- **THEN** el lienzo del mapa ocupa el 100% del ancho y alto disponibles, sin barras vacías, desplazamientos ni recortes

### Requirement: Encuadre inicial en Chile
The system SHALL iniciar la cámara del mapa centrada en Chile con un nivel de zoom inicial de 4.

#### Scenario: Vista inicial territorial
- **WHEN** el mapa termina de inicializarse
- **THEN** el centro de la cámara corresponde a las coordenadas geográficas de Chile y el nivel de zoom es 4

#### Scenario: Compatibilidad con el encuadre automático de capas
- **WHEN** una capa GeoJSON se carga correctamente tras la inicialización
- **THEN** el encuadre automático de la extensión puede reemplazar la vista inicial sin errores ni conflictos con el centro y zoom inicialmente definidos

### Requirement: Visualización de la capa de humedales urbanos
The system SHALL cargar y renderizar el dataset GeoJSON de Humedales Urbanos alojado en una ruta relativa del repositorio, mostrando sus polígonos y el conteo de entidades.

#### Scenario: Carga exitosa de la capa de humedales
- **WHEN** el visor inicializa y solicita `data/humedales_urbanos.geojson`
- **THEN** el sistema renderiza los 107 polígonos de humedales en el mapa y actualiza el contador de entidades en la interfaz

#### Scenario: Falla de carga de la capa de humedales
- **WHEN** el archivo de humedales no existe o responde con un código de error HTTP
- **THEN** el sistema muestra una notificación visible de error sin interrumpir el funcionamiento del mapa base

### Requirement: Simbología por proceso de declaratoria
The system SHALL colorear los polígonos de humedales según el atributo `proceso_humedal_urbano`, asignando un color distinto a `Municipal` y a `de Oficio`, y mostrar una leyenda que asocie cada color con su categoría.

#### Scenario: Colores diferenciados por categoría
- **WHEN** la capa de humedales se renderiza
- **THEN** cada polígono recibe el color correspondiente a su valor de `proceso_humedal_urbano`, distinguiendo visualmente `Municipal` de `de Oficio`

#### Scenario: Leyenda de simbología visible
- **WHEN** el usuario observa la interfaz
- **THEN** se muestra una leyenda que relaciona cada color con la categoría `Municipal` o `de Oficio`

#### Scenario: Valor de proceso desconocido
- **WHEN** un humedal presenta un valor de `proceso_humedal_urbano` distinto de las categorías conocidas
- **THEN** el sistema le aplica un color por defecto sin fallar el renderizado

### Requirement: Filtrado interactivo de humedales
The system SHALL permitir filtrar la capa de humedales simultáneamente por `region`, `comuna` y `proceso_humedal_urbano`, actualizando la visualización del mapa, re-encuadrando la cámara a la extensión de los humedales filtrados y el conteo de entidades al modificar cualquier criterio.

#### Scenario: Filtro por región
- **WHEN** el usuario selecciona una región en el filtro
- **THEN** el mapa muestra únicamente los humedales cuya `region` coincide y el conteo refleja el número de entidades visibles

#### Scenario: Filtro combinado
- **WHEN** el usuario combina una región con un proceso de declaratoria (y opcionalmente una comuna)
- **THEN** el sistema aplica todos los criterios de forma conjunta sobre la capa

#### Scenario: Encuadre automático a la extensión filtrada
- **WHEN** el usuario modifica uno o más filtros y quedan humedales visibles
- **THEN** el sistema ajusta la cámara a la extensión delimitadora de los humedales filtrados mediante una transición animada

#### Scenario: Filtro sin resultados
- **WHEN** los criterios aplicados no coinciden con ningún humedal
- **THEN** el sistema mantiene la cámara sin cambios y el conteo refleja cero entidades visibles

#### Scenario: Restablecer filtros
- **WHEN** el usuario pulsa el control de restablecer filtros
- **THEN** el sistema vuelve a mostrar la totalidad de los humedales, restaura el conteo completo y re-encuadra la cámara a la extensión total

### Requirement: Inspección de atributos del humedal
The system MUST mostrar un popup con los atributos del humedal al hacer clic sobre su polígono, incluyendo nombre, código, región, comuna, superficie en hectáreas, proceso de declaratoria y resolución, además de enlaces a las fuentes oficiales.

#### Scenario: Clic sobre un humedal
- **WHEN** el usuario hace clic sobre el polígono de un humedal
- **THEN** el sistema despliega un popup con los atributos `nombre_humedal`, `cod_humedal`, `region`, `comuna`, `ha`, `proceso_humedal_urbano` y `resolucion`, y enlaces utilizables a `url_res_bcn` y `url_simbio`
