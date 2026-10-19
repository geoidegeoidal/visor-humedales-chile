## Purpose

Proporciona capacidades de visualización y consulta cartográfica web interactiva en el cliente sin requerir servicios de backend ni claves de API propietarias.

## ADDED Requirements

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
