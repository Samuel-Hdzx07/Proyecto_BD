
-- ---------- PARTE 1: datos válidos (deben ejecutarse sin error) -------
INSERT INTO usuario (nombre_pila, apellidos, correo, tipo_usuario) VALUES
    ('Ana',  'Pérez López', 'ana@correo.com',  'FREE'),      -- id 1
    ('Luis', 'Gómez Ruiz',  'luis@correo.com', 'PREMIUM');   -- id 2

INSERT INTO usuario_free (usuario_id, minutos_publicidad, saltos_restantes)
VALUES (1, 0, 6);
INSERT INTO usuario_premium (usuario_id, fecha_corte, metodo_pago)
VALUES (2, '2026-11-01', 'tarjeta');

INSERT INTO artista (nombre, pais_origen) VALUES ('Artista Demo', 'México'); -- id 1
INSERT INTO album (artista_id, titulo, fecha_lanzamiento)
VALUES (1, 'Álbum Demo', '2025-05-10');                                       -- id 1

INSERT INTO pista_audio (titulo, duracion_seg, genero, tipo_pista)
VALUES ('Canción Demo', 200, 'Pop', 'CANCION');                               -- id 1
INSERT INTO cancion (pista_id, album_id, bpm, valencia, nivel_energia, bailabilidad)
VALUES (1, 1, 120, 0.7, 0.8, 0.6);
INSERT INTO artista_cancion (artista_id, pista_id) VALUES (1, 1);

INSERT INTO dispositivo (usuario_id, dispositivo_num, tipo, sistema_operativo)
VALUES (1, 1, 'movil', 'Android');

-- ---------- PARTE 2: cada sentencia debe fallar -----------------------

-- Prueba 1: UNIQUE (correo duplicado)
INSERT INTO usuario (nombre_pila, apellidos, correo, tipo_usuario)
VALUES ('Otra', 'Persona', 'ana@correo.com', 'FREE');

-- Prueba 2: disyunción de la jerarquía (usuario PREMIUM no puede ser FREE)
INSERT INTO usuario_free (usuario_id, minutos_publicidad, saltos_restantes)
VALUES (2, 0, 6);

-- Prueba 3: CHECK de la categoría/unión (ambas FK no nulas)
INSERT INTO creador_playlist (usuario_id, artista_id) VALUES (1, 1);

-- Prueba 4: CHECK de dominio (bpm fuera de rango)
INSERT INTO pista_audio (titulo, duracion_seg, genero, tipo_pista)
VALUES ('Pista 2', 180, 'Rock', 'CANCION');                                   -- id 2 (válida)
INSERT INTO cancion (pista_id, bpm, valencia, nivel_energia, bailabilidad)
VALUES (2, 5000, 0.5, 0.5, 0.5);

-- Prueba 5: entidad débil, el dispositivo debe ser del mismo usuario
INSERT INTO reproduccion (usuario_id, num_reproduccion, dispositivo_num, pista_id)
VALUES (2, 1, 1, 1);

-- Prueba 6: ON DELETE RESTRICT (artista con álbumes)
DELETE FROM artista WHERE artista_id = 1;