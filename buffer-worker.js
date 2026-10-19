const TURF_URL = 'https://unpkg.com/@turf/turf@7.2.0/turf.min.js';
const POLYGON_CLIPPING_URL = 'https://unpkg.com/polygon-clipping@0.15.7/dist/polygon-clipping.umd.js';
const BUFFER_STEPS = 8;
const UNION_BATCH_SIZE = 1000;
const MIN_DISTANCE = 1;
const MAX_DISTANCE = 50000;

let librariesReady = false;

function ensureLibraries() {
  if (librariesReady) return;

  try {
    importScripts(TURF_URL, POLYGON_CLIPPING_URL);
  } catch (error) {
    throw new Error('No se pudieron cargar las librerías de cálculo. Revisa tu conexión a internet.');
  }

  if (!globalThis.turf || typeof globalThis.turf.buffer !== 'function') {
    throw new Error('La librería Turf.js no quedó disponible.');
  }
  if (!globalThis.polygonClipping || typeof globalThis.polygonClipping.union !== 'function') {
    throw new Error('La librería polygon-clipping no quedó disponible.');
  }

  librariesReady = true;
}

function emit(payload) {
  globalThis.postMessage(payload);
}

function validateRequest(message) {
  if (!message || message.type !== 'buffer') {
    throw new Error('Solicitud de análisis inválida.');
  }
  if (!Array.isArray(message.features) || message.features.length === 0) {
    throw new Error('No hay entidades para procesar.');
  }

  const distance = Number(message.distance);
  if (!Number.isFinite(distance) || distance < MIN_DISTANCE || distance > MAX_DISTANCE) {
    throw new Error('La distancia debe ser un número entre 1 y 50.000 metros.');
  }

  return {
    requestId: message.requestId,
    features: message.features,
    distance,
    dissolve: Boolean(message.dissolve),
    sourceLayer: message.sourceLayer || 'sinader'
  };
}

function countUnionOperations(count) {
  let operations = 0;
  let level = count;
  while (level > 1) {
    level = Math.ceil(level / UNION_BATCH_SIZE);
    operations += level;
  }
  return operations;
}

function unionBatched(geometries, onBatch) {
  let current = geometries;

  while (current.length > 1) {
    const next = [];
    for (let index = 0; index < current.length; index += UNION_BATCH_SIZE) {
      const batch = current.slice(index, index + UNION_BATCH_SIZE);
      next.push(batch.length === 1 ? batch[0] : globalThis.polygonClipping.union(batch[0], ...batch.slice(1)));
      if (onBatch) onBatch(1);
    }
    current = next;
  }

  return current[0];
}

function assertBufferedGeometry(feature, index) {
  if (!feature || !feature.geometry) {
    throw new Error(`No se pudo generar el buffer de la entidad ${index + 1}.`);
  }
  if (feature.geometry.type !== 'Polygon' && feature.geometry.type !== 'MultiPolygon') {
    throw new Error(`El buffer de la entidad ${index + 1} tiene una geometría incompatible.`);
  }
}

function buildDissolvedFeature(sourceFeatures, bufferedFeatures, distance, sourceLayer, requestId) {
  const geometries = bufferedFeatures.map((feature, index) => {
    assertBufferedGeometry(feature, index);
    return { type: feature.geometry.type, coordinates: feature.geometry.coordinates };
  });

  let merged;
  if (geometries.length === 1) {
    const only = geometries[0];
    merged = only.type === 'Polygon' ? [only.coordinates] : only.coordinates;
  } else {
    const totalOperations = countUnionOperations(geometries.length);
    let completed = 0;
    merged = unionBatched(
      geometries.map(item => item.coordinates),
      () => {
        completed += 1;
        emit({
          type: 'progress',
          requestId,
          phase: 'union',
          done: completed,
          total: totalOperations
        });
      }
    );
  }

  if (!Array.isArray(merged) || merged.length === 0) {
    throw new Error('La disolución no produjo geometrías.');
  }

  return {
    type: 'Feature',
    properties: {
      capa: sourceLayer,
      dist_m: distance,
      n_origen: sourceFeatures.length
    },
    geometry: {
      type: 'MultiPolygon',
      coordinates: merged
    }
  };
}

function buildIndividualFeatures(sourceFeatures, bufferedFeatures, distance) {
  return bufferedFeatures.map((feature, index) => {
    assertBufferedGeometry(feature, index);
    return {
      type: 'Feature',
      geometry: feature.geometry,
      properties: {
        ...(sourceFeatures[index].properties || {}),
        buffer_m: distance
      }
    };
  });
}

async function handleRequest(message) {
  const requestId = message && message.requestId;

  try {
    const request = validateRequest(message);
    ensureLibraries();

    emit({
      type: 'progress',
      requestId: request.requestId,
      phase: 'buffer',
      done: 0,
      total: request.features.length
    });

    const collection = {
      type: 'FeatureCollection',
      features: request.features
    };

    const buffered = globalThis.turf.buffer(collection, request.distance, {
      units: 'meters',
      steps: BUFFER_STEPS
    });

    if (!buffered || !Array.isArray(buffered.features) || buffered.features.length !== request.features.length) {
      throw new Error('El cálculo de buffers no devolvió todas las entidades.');
    }

    emit({
      type: 'progress',
      requestId: request.requestId,
      phase: 'buffer',
      done: request.features.length,
      total: request.features.length
    });

    const features = request.dissolve
      ? [buildDissolvedFeature(request.features, buffered.features, request.distance, request.sourceLayer, request.requestId)]
      : buildIndividualFeatures(request.features, buffered.features, request.distance);

    emit({
      type: 'done',
      requestId: request.requestId,
      features,
      meta: {
        sourceCount: request.features.length,
        outputCount: features.length,
        mode: request.dissolve ? 'disuelto' : 'individual',
        parts: request.dissolve && features[0].geometry.type === 'MultiPolygon'
          ? features[0].geometry.coordinates.length
          : features.length,
        distance: request.distance,
        sourceLayer: request.sourceLayer
      }
    });
  } catch (error) {
    emit({
      type: 'error',
      requestId,
      message: error && error.message ? error.message : 'No se pudo completar el análisis.'
    });
  }
}

globalThis.onmessage = function onmessage(event) {
  const message = event && event.data;
  if (!message || message.type !== 'buffer') return;
  handleRequest(message);
};
