## ADDED Requirements

### Requirement: Capa espacial secundaria cargada tras inicializar MapLibre
The system SHALL cargar y renderizar una capa espacial secundaria de puntos (registro SINADER 2024) desde una ruta relativa del repositorio, **además** de la capa de humedales, incorporándola únicamente cuando el mapa base esté inicializado y su estilo cargado, sin requerir backend ni claves de API.

#### Scenario: Carga de la capa secundaria tras el evento de carga
- **WHEN** el mapa termina de inicializarse (`map.on('load')`) y el estilo está cargado
- **THEN** el sistema añade la fuente y las capas de la capa secundaria de puntos, y la muestra junto con la capa de humedales existente

#### Scenario: Falla de carga de la capa secundaria
- **WHEN** el archivo de la capa secundaria no existe o responde con un código de error HTTP
- **THEN** el sistema muestra una notificación visible de error y la capa de humedales y el mapa base siguen funcionando con normalidad

#### Scenario: Coordenadas inválidas del dataset secundario
- **WHEN** el dataset secundario contiene entidades con coordenadas nulas o fuera del rango geográfico válido
- **THEN** el sistema no las renderiza ni provoca errores, y las entidades restantes se muestran correctamente

### Requirement: Separación entre datos y simbología por capa
The system SHALL definir la fuente de datos de cada capa (origen y geometría) de forma independiente de su simbología (campo de clasificación, categorías y colores), de modo que modificar una capa no altere los datos ni la simbología de las demás.

#### Scenario: Simbología modificable sin afectar los datos
- **WHEN** se cambia la configuración de simbología de la capa secundaria
- **THEN** los datos cargados y la simbología de la capa de humedales permanecen inalterados

#### Scenario: Fuente de datos independiente
- **WHEN** se modifica la ruta o la geometría de la capa secundaria
- **THEN** la simbología definida para esa capa se reutiliza sin cambios y no afecta a la otra capa

### Requirement: Visibilidad independiente de cada capa
The system SHALL permitir mostrar u ocultar la capa secundaria de forma independiente del estado de visibilidad de la capa de humedales.

#### Scenario: Ocultar la capa secundaria
- **WHEN** el usuario desactiva la capa secundaria
- **THEN** el sistema deja de renderizar sus puntos y la capa de humedales permanece visible y sin cambios

#### Scenario: Mostrar la capa secundaria
- **WHEN** el usuario activa la capa secundaria
- **THEN** el sistema vuelve a renderizar sus puntos sin recargar la aplicación ni alterar la cámara ni la capa de humedales

### Requirement: Filtrado propio de la capa secundaria sin afectar a las demás
The system SHALL proveer filtros para la capa secundaria (al menos por región y por categoría del dataset) que actualicen únicamente esa capa y su conteo de entidades visibles, sin modificar la visualización ni los filtros de la capa de humedales.

#### Scenario: Filtro por región de la capa secundaria
- **WHEN** el usuario selecciona una región en el filtro de la capa secundaria
- **THEN** solo los puntos de la capa secundaria cuya región coincide permanecen visibles y su conteo se actualiza, mientras la capa de humedales no cambia

#### Scenario: Filtro por categoría de la capa secundaria
- **WHEN** el usuario selecciona una categoría en el filtro de la capa secundaria
- **THEN** solo los puntos de esa categoría permanecen visibles y el conteo de la capa secundaria refleja las entidades visibles

#### Scenario: Re-encuadre a la extensión filtrada de la capa secundaria
- **WHEN** el usuario aplica o modifica un filtro de la capa secundaria y quedan puntos visibles
- **THEN** el sistema ajusta la cámara a la extensión delimitadora de esos puntos mediante una transición animada

#### Scenario: Filtro sin resultados en la capa secundaria
- **WHEN** los filtros de la capa secundaria no coinciden con ningún punto
- **THEN** el sistema mantiene la cámara sin cambios y el conteo refleja cero entidades visibles

#### Scenario: Restablecer filtros de la capa secundaria
- **WHEN** el usuario restablece los filtros de la capa secundaria
- **THEN** el sistema vuelve a mostrar la totalidad de sus puntos, restaura su conteo completo y re-encuadra la cámara a la extensión total de la capa secundaria

### Requirement: Preservación de las capacidades existentes
The system SHALL mantener inalteradas las capacidades ya existentes del visor al incorporar la capa secundaria, incluyendo la carga y filtrado de humedales, sus popups, la leyenda, el conteo, el botón de encuadre, el mapa base oscuro y la alternancia de tema.

#### Scenario: Coexistencia de ambas capas
- **WHEN** ambas capas están cargadas y visibles
- **THEN** los filtros, la leyenda, los popups y el conteo de humedales se comportan igual que antes de incorporar la capa secundaria

#### Scenario: Alternancia de tema con la capa secundaria visible
- **WHEN** el usuario conmuta entre modo claro y oscuro con la capa secundaria cargada
- **THEN** el cambio de mapa base se aplica sin recargar la vista y la capa secundaria permanece visible y coherente con el tema
