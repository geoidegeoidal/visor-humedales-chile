## ADDED Requirements

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
