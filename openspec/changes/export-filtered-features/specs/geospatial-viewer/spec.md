## ADDED Requirements

### Requirement: Exportación client-side del subconjunto filtrado
The system SHALL permitir exportar, por capa y sin backend, exactamente las entidades que cumplen los filtros activos de esa capa en el momento de la exportación.

#### Scenario: Exportación de humedales filtrados
- **WHEN** el usuario exporta la capa de humedales con filtros activos
- **THEN** el archivo contiene únicamente los humedales que cumplen dichos filtros

#### Scenario: Exportación de SINADER filtrado
- **WHEN** el usuario exporta la capa SINADER 2024 con filtros activos
- **THEN** el archivo contiene únicamente los puntos que cumplen dichos filtros

#### Scenario: Exportación sin filtros activos
- **WHEN** el usuario exporta una capa que no tiene filtros activos
- **THEN** el archivo contiene la totalidad de las entidades cargadas de esa capa

#### Scenario: Exclusión de entidades no filtradas
- **WHEN** el usuario exporta una capa con un subconjunto filtrado
- **THEN** las entidades que no cumplen los filtros no aparecen en el archivo

### Requirement: Formatos de exportación
The system SHALL ofrecer dos formatos por capa: GeoJSON y Shapefile comprimido, ambos en EPSG:4326 y con las propiedades de cada entidad.

#### Scenario: Exportación GeoJSON
- **WHEN** el usuario elige el formato GeoJSON
- **THEN** se descarga un archivo `.geojson` con un `FeatureCollection` válido que contiene las entidades filtradas y todas sus propiedades

#### Scenario: Exportación Shapefile
- **WHEN** el usuario elige el formato Shapefile
- **THEN** se descarga un archivo `.zip` que contiene los componentes `.shp`, `.shx`, `.dbf` y `.prj` del conjunto filtrado, en EPSG:4326

#### Scenario: Nombres de campo en Shapefile
- **WHEN** se exporta un Shapefile
- **THEN** las propiedades se conservan y los nombres de campo se ajustan al límite del formato DBF sin impedir la descarga

#### Scenario: Nombre de archivo identificable
- **WHEN** se completa una exportación
- **THEN** el nombre del archivo identifica la capa y la fecha de generación

### Requirement: Controles de exportación deshabilitados sin resultados
The system SHALL deshabilitar los controles de exportación de una capa cuando no haya entidades filtradas que exportar.

#### Scenario: Capa sin entidades filtradas
- **WHEN** los filtros activos de una capa no arrojan resultados
- **THEN** los controles de exportación de esa capa se muestran deshabilitados

#### Scenario: Capa no cargada
- **WHEN** una capa todavía no se cargó o falló su carga
- **THEN** sus controles de exportación se muestran deshabilitados

#### Scenario: Rehabilitación al haber resultados
- **WHEN** el usuario ajusta los filtros y la capa vuelve a tener al menos una entidad
- **THEN** los controles de exportación de esa capa se habilitan

### Requirement: Retroalimentación de progreso y errores
The system SHALL informar el estado de la exportación y evitar exportaciones duplicadas mientras una generación está en curso.

#### Scenario: Generación en curso
- **WHEN** el usuario inicia una exportación
- **THEN** la interfaz muestra un estado de generación y bloquea los controles de exportación hasta finalizar

#### Scenario: Exportación exitosa
- **WHEN** la generación termina correctamente
- **THEN** la interfaz confirma la descarga y restaura los controles según los resultados disponibles

#### Scenario: Error de generación
- **WHEN** la generación falla, por ejemplo por no poder cargar la dependencia de Shapefile
- **THEN** la interfaz muestra un mensaje de error comprensible, no se descarga un archivo corrupto y los datos del visor permanecen intactos

#### Scenario: Clic repetido durante la generación
- **WHEN** el usuario pulsa nuevamente un control de exportación mientras hay una generación en curso
- **THEN** no se inicia una segunda exportación ni se generan descargas duplicadas
