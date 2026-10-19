## ADDED Requirements

### Requirement: Estado de filtros unificado
El visor SHALL mantener una única fuente de verdad para los filtros activos de cada capa, expuesta mediante operaciones de lectura, escritura y restablecimiento, y SHALL derivar de ella la visualización del mapa, los contadores, los controles de exportación y los gráficos. Ningún componente MUST calcular un subconjunto filtrado a partir de una interpretación propia de los criterios. Al cambiar el estado de filtros, el visor SHALL notificar a todos los consumidores suscritos.

#### Scenario: Una sola lectura del filtro
- **WHEN** el usuario selecciona una región en los filtros de SINADER
- **THEN** el mapa, el contador de entidades, el estado de exportación y los gráficos reflejan exactamente el mismo subconjunto filtrado

#### Scenario: Escritura centralizada
- **WHEN** cualquier componente (selector del visor o interacción de un gráfico) modifica un criterio de filtro
- **THEN** el cambio se aplica a través de la misma operación del estado y notifica a los consumidores

#### Scenario: Restablecimiento coherente
- **WHEN** el usuario restablece los filtros de una capa
- **THEN** el estado unificado vuelve a sus valores vacíos y el mapa, los contadores, la exportación y los gráficos regresan al conjunto completo

### Requirement: Pipeline de filtrado sin duplicación
El visor SHALL aplicar el filtrado de cada capa mediante una única declaración de campos que genere tanto la expresión de MapLibre como el predicado de selección en JavaScript, y SHALL procesar el cambio de filtros en un solo pipeline que calcule la selección una vez y actualice el mapa, los contadores, la exportación y el encuadre. Agregar una nueva dimensión de filtro MUST NOT requerir una ruta de filtrado independiente.

#### Scenario: Selección calculada una sola vez
- **WHEN** se aplica o cambia un filtro de humedales
- **THEN** la expresión del mapa y el conjunto filtrado derivan de la misma definición de campos y el resultado es idéntico entre ambos

#### Scenario: Encuadre y contadores conservados
- **WHEN** el usuario modifica un filtro y quedan entidades visibles
- **THEN** el visor re-encuadra la cámara a la extensión filtrada y actualiza el contador, igual que antes del cambio

#### Scenario: Nueva dimensión reutiliza el pipeline
- **WHEN** se agrega una dimensión de filtro a una capa
- **THEN** su población, filtrado y conteo usan el mismo pipeline genérico sin duplicar la lógica existente

### Requirement: Dashboard analítico client-side
El visor SHALL mostrar un dashboard de tres visualizaciones construidas con Chart.js cargado por CDN bajo demanda, sin backend, manteniendo el mapa como elemento visual principal. Si Chart.js no está disponible, el visor MUST mostrar un error y conservar el mapa y los filtros operativos.

#### Scenario: Carga diferida de Chart.js
- **WHEN** el usuario abre el visor
- **THEN** Chart.js se carga solo al inicializar el dashboard y no se descarga si no se usa

#### Scenario: Falla de la dependencia
- **WHEN** el CDN de Chart.js no responde
- **THEN** el visor muestra un mensaje de error y el mapa y los filtros siguen funcionando

#### Scenario: Mapa como elemento principal
- **WHEN** el dashboard está visible
- **THEN** el contenedor del mapa conserva su tamaño y protagonismo y el dashboard se integra en el panel sin tapar el mapa

### Requirement: Gráfico de humedales por región y proceso
El dashboard SHALL incluir una visualización que agregue los humedales por `region` y los desglose por `proceso_humedal_urbano`, mostrando el conteo de humedales. La visualización SHALL recalcularse al cambiar los filtros de humedales.

#### Scenario: Agregación por región y proceso
- **WHEN** no hay filtros activos
- **THEN** el gráfico muestra el conteo de humedales por región, desglosado en `Municipal` y `De Oficio`, y la suma de sus segmentos coincide con las 107 entidades

#### Scenario: Recalculo por filtro
- **WHEN** el usuario filtra humedales por región
- **THEN** el gráfico refleja únicamente los humedales filtrados y su conteo total coincide con el contador de la capa

### Requirement: Gráfico de rubros SINADER por carga declarada
El dashboard SHALL incluir una visualización que agregue los establecimientos SINADER por `rubro`, ordenada por carga declarada (suma de `toneladas_totales`), con la posibilidad de alternar la métrica a conteo de establecimientos. La visualización SHALL recalcularse al cambiar los filtros de SINADER.

#### Scenario: Ranking por toneladas
- **WHEN** no hay filtros activos
- **THEN** el gráfico ordena los rubros por suma de `toneladas_totales` de mayor a menor y la suma de las barras coincide con el total declarado de las entidades mostradas

#### Scenario: Cambio de métrica
- **WHEN** el usuario alterna la métrica a conteo de establecimientos
- **THEN** el gráfico muestra la cantidad de establecimientos por rubro reutilizando los mismos rubros filtrados

### Requirement: Gráfico de coincidencia territorial entre capas
El dashboard SHALL incluir una visualización que compare ambas capas por región, usando un eje para la carga declarada de SINADER (suma de `toneladas_totales`) y otro para el número de humedales. Para alinear los datasets, el visor SHALL normalizar los nombres de `region` mediante un mapeo canónico que preserve el valor nativo de cada capa.

#### Scenario: Alineación de regiones divergentes
- **WHEN** una región se nombra de forma distinta en cada dataset
- **THEN** la visualización la trata como una sola categoría en lugar de duplicarla o perderla

#### Scenario: Doble medida por región
- **WHEN** el gráfico se renderiza
- **THEN** cada región muestra la carga declarada de SINADER y el número de humedales urbanos en ejes separados

### Requirement: Interacción de los gráficos con el mapa
El visor SHALL permitir que las interacciones definidas en cada visualización actualicen el estado de filtros unificado y, en consecuencia, el mapa. La interacción de un gráfico MUST NOT introducir una ruta de filtrado distinta de la usada por los controles del visor, y los controles SHALL reflejar el filtro originado en el gráfico.

#### Scenario: Filtro desde el gráfico de humedales
- **WHEN** el usuario hace clic en la barra de una región del gráfico de humedales
- **THEN** el mapa muestra esa región, el selector de región queda con ese valor y el contador se actualiza

#### Scenario: Filtro desde el gráfico de rubros
- **WHEN** el usuario hace clic en la barra de un rubro del gráfico de SINADER
- **THEN** el mapa muestra únicamente los establecimientos de ese rubro y el selector de rubro refleja la selección

#### Scenario: Filtro entre capas por región
- **WHEN** el usuario hace clic en una región del gráfico de coincidencia territorial
- **THEN** el estado de filtros aplica esa región a humedales y a SINADER con el valor nativo de cada capa y el mapa se re-encuadra

#### Scenario: Sincronización filtro del visor hacia gráfico
- **WHEN** el usuario cambia un filtro desde los controles del visor
- **THEN** el gráfico correspondiente resalta o actualiza la categoría filtrada sin iniciar otra ruta de filtrado

### Requirement: No regresión de las capacidades existentes
La incorporación del dashboard y del estado de filtros unificado MUST NOT alterar el comportamiento de los filtros existentes, los popups, la exportación filtrada, la visibilidad de capas, el tema claro/oscuro ni el encuadre de cámara.

#### Scenario: Capacidades preservadas
- **WHEN** el usuario filtra, inspecciona un popup, exporta o cambia el tema con el dashboard activo
- **THEN** cada capacidad se comporta igual que antes de este cambio

#### Scenario: Exportación coherente con los gráficos
- **WHEN** el usuario exporta el subconjunto filtrado tras interactuar con un gráfico
- **THEN** el archivo descargado contiene exactamente el subconjunto reflejado por el mapa y los gráficos
