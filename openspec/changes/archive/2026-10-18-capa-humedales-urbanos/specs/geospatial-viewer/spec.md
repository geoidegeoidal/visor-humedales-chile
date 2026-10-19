## ADDED Requirements

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
