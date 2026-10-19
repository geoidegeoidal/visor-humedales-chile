## ADDED Requirements

### Requirement: Generación de áreas de influencia en metros
El visor SHALL generar áreas de influencia (buffers) a partir de la capa seleccionada, usando una distancia en metros definida por el usuario y sin depender de un backend. La distancia MUST ser un número mayor o igual a 1 y menor o igual a 50.000 metros. El usuario SHALL poder elegir entre bufferizar todas las entidades cargadas de la capa o solo las que cumplen los filtros activos. El resultado SHALL ser una capa temporal independiente de las capas de origen.

#### Scenario: Buffer sobre entidades filtradas
- **WHEN** el usuario selecciona SINADER, aplica un filtro de región, elige alcance "solo filtradas", ingresa 500 metros y genera el análisis
- **THEN** el resultado contiene un buffer por cada entidad filtrada de SINADER y la cantidad coincide con el contador filtrado de esa capa

#### Scenario: Buffer sobre todas las entidades
- **WHEN** el usuario mantiene filtros activos pero elige alcance "todas las entidades"
- **THEN** el análisis usa todas las entidades cargadas de la capa seleccionada y no descarta las que quedan fuera del filtro

#### Scenario: Distancia inválida
- **WHEN** el usuario ingresa una distancia vacía, cero, negativa o mayor a 50.000 metros
- **THEN** el visor muestra un mensaje de validación, no ejecuta el cálculo y conserva sin cambios el resultado anterior si existía

#### Scenario: Alcance filtrado sin entidades
- **WHEN** el usuario elige "solo filtradas" y la capa seleccionada tiene cero entidades filtradas
- **THEN** el visor impide generar el análisis e informa que no hay entidades para procesar

#### Scenario: Distancia geodésica aproximada
- **WHEN** se genera un buffer de 1.000 metros sobre una entidad puntual
- **THEN** la distancia entre el punto de origen y el borde del buffer es aproximadamente 1.000 metros, con una tolerancia de ±1%

### Requirement: Disolución opcional de buffers
El usuario SHALL poder elegir entre conservar un buffer por entidad o disolver los buffers solapados. En modo individual, el resultado MUST contener exactamente un Feature por entidad de origen y conservar sus propiedades, agregando la distancia usada. En modo disuelto, el resultado MUST contener un único Feature cuya geometría sea la unión de todos los buffers, expresada como Polygon o MultiPolygon con partes disjuntas cuando corresponda, e incluir la capa de origen, la distancia y la cantidad de entidades de origen.

#### Scenario: Buffers individuales
- **WHEN** el usuario genera 340 buffers sin disolver
- **THEN** el resultado contiene 340 Features, cada uno con la geometría del buffer y las propiedades de su entidad de origen más la distancia utilizada

#### Scenario: Disolución de buffers solapados
- **WHEN** el usuario genera buffers de 500 metros con disolución sobre entidades cuyos buffers se solapan
- **THEN** el resultado es un único Feature cuya geometría cubre la unión de los buffers y no conserva límites internos entre ellos

#### Scenario: Disolución con partes disjuntas
- **WHEN** el usuario disuelve buffers que pertenecen a grupos separados geográficamente
- **THEN** el resultado es un único Feature con geometría MultiPolygon que contiene una parte por cada grupo disjunto

#### Scenario: Metadatos del resultado disuelto
- **WHEN** el usuario disuelve 525 buffers de 500 metros de SINADER
- **THEN** el Feature resultante informa la capa de origen, la distancia de 500 metros y una cantidad de origen igual a 525

### Requirement: Visualización y gestión del resultado
El visor SHALL mostrar el resultado como una capa temporal visible sobre las capas base, ajustar la vista a su extensión y permitir ocultarla, mostrarla y limpiarla. Una nueva ejecución SHALL reemplazar el resultado anterior en lugar de acumular capas. La visualización del resultado MUST NOT modificar las capas de origen ni sus filtros.

#### Scenario: Resultado visible y ajustado
- **WHEN** el análisis termina correctamente
- **THEN** el resultado aparece en el mapa, la vista se ajusta a su extensión y el panel muestra capa, distancia, modo y cantidad de entidades

#### Scenario: Reemplazo del resultado
- **WHEN** el usuario genera un segundo análisis con otra distancia o capa
- **THEN** el visor elimina el resultado anterior y muestra únicamente el nuevo

#### Scenario: Visibilidad del resultado
- **WHEN** el usuario desactiva y vuelve a activar el resultado desde el control de capas
- **THEN** la capa de resultado se oculta y se muestra sin perder sus datos ni sus controles de exportación

#### Scenario: Limpieza del resultado
- **WHEN** el usuario limpia el resultado
- **THEN** la capa desaparece del mapa, el estado del resultado se vacía y la exportación queda deshabilitada

#### Scenario: Capas de origen intactas
- **WHEN** el usuario genera, oculta o limpia un resultado
- **THEN** las capas de humedales y SINADER conservan sus datos, filtros y visibilidad

### Requirement: Exportación del resultado del análisis
El visor SHALL exportar únicamente el resultado del análisis en formato GeoJSON y Shapefile comprimido en ZIP. Los nombres de archivo MUST identificar la capa de origen, la distancia y el modo (individual o disuelto). Los controles de exportación MUST permanecer deshabilitados mientras no exista un resultado. La exportación MUST conservar la geometría del resultado, incluidas las partes disjuntas del modo disuelto.

#### Scenario: Exportación GeoJSON del resultado
- **WHEN** el usuario exporta un resultado disuelto en GeoJSON
- **THEN** el archivo descargado contiene solo el Feature del resultado, su geometría completa y el nombre incluye capa, distancia y modo

#### Scenario: Exportación Shapefile del resultado
- **WHEN** el usuario exporta un resultado individual en Shapefile
- **THEN** se descarga un ZIP con los archivos Shapefile válidos, el CRS WGS84 y las propiedades de origen conservadas

#### Scenario: Exportación sin resultado
- **WHEN** no existe un resultado de análisis
- **THEN** los botones de exportación del resultado están deshabilitados y no descargan archivos

#### Scenario: Partes disjuntas en la exportación
- **WHEN** se exporta un resultado disuelto con varias partes disjuntas
- **THEN** la geometría exportada conserva todas las partes como MultiPolygon

### Requirement: Retroalimentación y estabilidad durante el cálculo
Durante el cálculo, el visor SHALL mostrar un estado de procesamiento, impedir ejecuciones duplicadas y mantener la interfaz operativa sin bloquearse. Si el cálculo falla, el visor MUST mostrar un mensaje de error, rehabilitar los controles y conservar el resultado anterior si existía. El visor MUST ignorar respuestas de solicitudes obsoletas.

#### Scenario: Cálculo prolongado
- **WHEN** el usuario disuelve 9.105 buffers y el cálculo tarda varios segundos
- **THEN** el visor muestra el estado de procesamiento, mantiene la interfaz operable y no permite iniciar otra ejecución mientras tanto

#### Scenario: Error de cálculo
- **WHEN** el cálculo falla por datos inválidos o por un fallo al cargar las dependencias
- **THEN** el visor muestra un mensaje de error, rehabilita los controles y no elimina el resultado anterior

#### Scenario: Ejecución duplicada
- **WHEN** el usuario intenta generar el análisis nuevamente mientras hay uno en curso
- **THEN** el visor ignora la segunda solicitud y notifica que ya hay un cálculo en progreso

#### Scenario: Respuesta obsoleta
- **WHEN** llega el resultado de una solicitud anterior después de iniciar una nueva
- **THEN** el visor descarta la respuesta obsoleta y solo aplica la solicitud más reciente
