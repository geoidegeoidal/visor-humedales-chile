## 1. Configuración inicial del mapa

- [x] 1.1 Actualizar `CONFIG.INITIAL_CENTER` a coordenadas de Chile (`[-71.5, -35.7]`) y `CONFIG.INITIAL_ZOOM` a `4` en `index.html`; verificar por inspección que ambos valores quedan aplicados
- [x] 1.2 Confirmar que `new maplibregl.Map(...)` se monta sobre el contenedor `#map` existente; verificar que no se crean contenedores adicionales ni se altera la estructura del HUD

## 2. Estado inicial oscuro

- [x] 2.1 Aplicar el tema oscuro durante la inicialización (clase `dark` en el documento y capa base oscura visible) sin requerir interacción del usuario; verificar que al cargar el visor se muestra el mapa oscuro sin parpadeo claro
- [x] 2.2 Verificar que el conmutador de tema sigue alternando claro/oscuro sin recargar la vista

## 3. Ocupación del espacio disponible

- [x] 3.1 Verificar que el contenedor `#map` ocupa el 100% del ancho y alto sin scroll, márgenes ni recortes; ajustar clases Tailwind si fuera necesario

## 4. Validación de no-regresión

- [x] 4.1 Verificar visualmente en el navegador que el HUD, el botón de centrado y los popups permanecen intactos y funcionales
- [x] 4.2 Validar el encuadre: vista inicial centrada en Chile con zoom 4 y, tras cargar la capa GeoJSON, ajuste a la extensión de los datos sin errores
