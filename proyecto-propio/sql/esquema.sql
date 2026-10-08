BEGIN;

-- ---------------------------------------------------------------------
-- ARTISTA (Regla 1). oyentes_mensuales es DERIVADO: no se guarda,
-- se calcula en la vista v_artista (al final del script).
-- ---------------------------------------------------------------------
CREATE TABLE artista (
    artista_id  INT GENERATED ALWAYS AS IDENTITY,
    nombre      VARCHAR(100) NOT NULL,
    pais_origen VARCHAR(60)  NOT NULL,
    CONSTRAINT pk_artista PRIMARY KEY (artista_id)
);

-- ---------------------------------------------------------------------
-- ALBUM (Regla 1 + Regla 4). PUBLICA: ALBUM (1,1) - ARTISTA (0,N)
-- => artista_id NOT NULL en el lado muchos.
-- ---------------------------------------------------------------------
CREATE TABLE album (
    album_id          INT GENERATED ALWAYS AS IDENTITY,
    artista_id        INT NOT NULL,
    titulo            VARCHAR(150) NOT NULL,
    fecha_lanzamiento DATE        NOT NULL,
    CONSTRAINT pk_album PRIMARY KEY (album_id),
    CONSTRAINT fk_album_artista FOREIGN KEY (artista_id)
        REFERENCES artista (artista_id)
        ON DELETE RESTRICT ON UPDATE CASCADE
);

-- ---------------------------------------------------------------------
-- USUARIO (Reglas 1 y 2) + jerarquía disjunta/total (Regla 9, estrategia A).
-- Atributo compuesto nombre -> nombre_pila, apellidos.
-- tipo_usuario es el discriminador; UNIQUE (usuario_id, tipo_usuario)
-- permite que cada subtipo lo referencie con FK compuesta y así
-- garantizar la DISYUNCIÓN (un usuario no puede estar en ambos subtipos).
-- ---------------------------------------------------------------------
CREATE TABLE usuario (
    usuario_id     INT GENERATED ALWAYS AS IDENTITY,
    nombre_pila    VARCHAR(60)  NOT NULL,
    apellidos      VARCHAR(100) NOT NULL,
    correo         VARCHAR(150) NOT NULL,
    activo         BOOLEAN      NOT NULL DEFAULT TRUE,
    fecha_registro DATE         NOT NULL DEFAULT CURRENT_DATE,
    tipo_usuario   VARCHAR(7)   NOT NULL,
    CONSTRAINT pk_usuario PRIMARY KEY (usuario_id),
    CONSTRAINT uq_usuario_correo UNIQUE (correo),
    CONSTRAINT uq_usuario_tipo UNIQUE (usuario_id, tipo_usuario),
    CONSTRAINT ck_usuario_correo CHECK (correo LIKE '%_@_%._%'),
    CONSTRAINT ck_usuario_tipo CHECK (tipo_usuario IN ('FREE', 'PREMIUM'))
);

CREATE TABLE usuario_free (
    usuario_id        INT        NOT NULL,
    tipo_usuario      VARCHAR(7) NOT NULL DEFAULT 'FREE',
    minutos_publicidad INT       NOT NULL DEFAULT 0,
    saltos_restantes  INT        NOT NULL DEFAULT 0,
    CONSTRAINT pk_usuario_free PRIMARY KEY (usuario_id),
    CONSTRAINT ck_free_tipo CHECK (tipo_usuario = 'FREE'),
    CONSTRAINT ck_free_minutos CHECK (minutos_publicidad >= 0),
    CONSTRAINT ck_free_saltos CHECK (saltos_restantes >= 0),
    CONSTRAINT fk_free_usuario FOREIGN KEY (usuario_id, tipo_usuario)
        REFERENCES usuario (usuario_id, tipo_usuario)
        ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE usuario_premium (
    usuario_id   INT         NOT NULL,
    tipo_usuario VARCHAR(7)  NOT NULL DEFAULT 'PREMIUM',
    fecha_corte  DATE        NOT NULL,
    metodo_pago  VARCHAR(30) NOT NULL,
    CONSTRAINT pk_usuario_premium PRIMARY KEY (usuario_id),
    CONSTRAINT ck_premium_tipo CHECK (tipo_usuario = 'PREMIUM'),
    CONSTRAINT fk_premium_usuario FOREIGN KEY (usuario_id, tipo_usuario)
        REFERENCES usuario (usuario_id, tipo_usuario)
        ON DELETE CASCADE ON UPDATE CASCADE
);

-- ---------------------------------------------------------------------
-- PISTA_AUDIO + jerarquía disjunta/total (Regla 9, estrategia A).
-- Discriminador: tipo_pista.
-- ---------------------------------------------------------------------
CREATE TABLE pista_audio (
    pista_id     INT GENERATED ALWAYS AS IDENTITY,
    titulo       VARCHAR(150) NOT NULL,
    duracion_seg INT          NOT NULL,
    genero       VARCHAR(40)  NOT NULL,
    tipo_pista   VARCHAR(8)   NOT NULL,
    CONSTRAINT pk_pista_audio PRIMARY KEY (pista_id),
    CONSTRAINT uq_pista_tipo UNIQUE (pista_id, tipo_pista),
    CONSTRAINT ck_pista_duracion CHECK (duracion_seg > 0),
    CONSTRAINT ck_pista_tipo CHECK (tipo_pista IN ('CANCION', 'EPISODIO'))
);

-- CANCION. PERTENECE_A: CANCION (0,1) - ALBUM (0,N) => album_id admite NULL.
CREATE TABLE cancion (
    pista_id       INT        NOT NULL,
    tipo_pista     VARCHAR(8) NOT NULL DEFAULT 'CANCION',
    album_id       INT,
    bpm            INT          NOT NULL,
    valencia       NUMERIC(4,3) NOT NULL,
    nivel_energia  NUMERIC(4,3) NOT NULL,
    bailabilidad   NUMERIC(4,3) NOT NULL,
    CONSTRAINT pk_cancion PRIMARY KEY (pista_id),
    CONSTRAINT ck_cancion_tipo CHECK (tipo_pista = 'CANCION'),
    CONSTRAINT ck_cancion_bpm CHECK (bpm BETWEEN 20 AND 300),
    CONSTRAINT ck_cancion_valencia CHECK (valencia BETWEEN 0 AND 1),
    CONSTRAINT ck_cancion_energia CHECK (nivel_energia BETWEEN 0 AND 1),
    CONSTRAINT ck_cancion_bailab CHECK (bailabilidad BETWEEN 0 AND 1),
    CONSTRAINT fk_cancion_pista FOREIGN KEY (pista_id, tipo_pista)
        REFERENCES pista_audio (pista_id, tipo_pista)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_cancion_album FOREIGN KEY (album_id)
        REFERENCES album (album_id)
        ON DELETE SET NULL ON UPDATE CASCADE
);

-- EPISODIO_PODCAST. CONDUCE: ARTISTA (0,N) - EPISODIO (1,1)
-- => artista_conductor_id NOT NULL.
CREATE TABLE episodio_podcast (
    pista_id             INT        NOT NULL,
    tipo_pista           VARCHAR(8) NOT NULL DEFAULT 'EPISODIO',
    artista_conductor_id INT        NOT NULL,
    numero_episodio      INT        NOT NULL,
    temporada            INT        NOT NULL,
    CONSTRAINT pk_episodio_podcast PRIMARY KEY (pista_id),
    CONSTRAINT uq_episodio UNIQUE (artista_conductor_id, temporada, numero_episodio),
    CONSTRAINT ck_episodio_tipo CHECK (tipo_pista = 'EPISODIO'),
    CONSTRAINT ck_episodio_numero CHECK (numero_episodio > 0),
    CONSTRAINT ck_episodio_temporada CHECK (temporada > 0),
    CONSTRAINT fk_episodio_pista FOREIGN KEY (pista_id, tipo_pista)
        REFERENCES pista_audio (pista_id, tipo_pista)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_episodio_conductor FOREIGN KEY (artista_conductor_id)
        REFERENCES artista (artista_id)
        ON DELETE RESTRICT ON UPDATE CASCADE
);

-- Atributo MULTIVALUADO invitados (Regla 3): PK = (pista_id, invitado).
CREATE TABLE episodio_invitado (
    pista_id  INT          NOT NULL,
    invitado  VARCHAR(100) NOT NULL,
    CONSTRAINT pk_episodio_invitado PRIMARY KEY (pista_id, invitado),
    CONSTRAINT fk_invitado_episodio FOREIGN KEY (pista_id)
        REFERENCES episodio_podcast (pista_id)
        ON DELETE CASCADE ON UPDATE CASCADE
);

-- INTERPRETA: ARTISTA (0,N) - CANCION (1,N), muchos a muchos (Regla 5).
CREATE TABLE artista_cancion (
    artista_id INT NOT NULL,
    pista_id   INT NOT NULL,
    CONSTRAINT pk_artista_cancion PRIMARY KEY (artista_id, pista_id),
    CONSTRAINT fk_ac_artista FOREIGN KEY (artista_id)
        REFERENCES artista (artista_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_ac_cancion FOREIGN KEY (pista_id)
        REFERENCES cancion (pista_id)
        ON DELETE CASCADE ON UPDATE CASCADE
);

-- ---------------------------------------------------------------------
-- CREADOR_PLAYLIST: categoría (unión) USUARIO U ARTISTA.
-- Clave sustituta + CHECK que obliga a que EXACTAMENTE una de las
-- dos claves foráneas sea no nula.
-- ---------------------------------------------------------------------
CREATE TABLE creador_playlist (
    creador_playlist_id INT GENERATED ALWAYS AS IDENTITY,
    usuario_id          INT,
    artista_id          INT,
    CONSTRAINT pk_creador_playlist PRIMARY KEY (creador_playlist_id),
    CONSTRAINT uq_creador_usuario UNIQUE (usuario_id),
    CONSTRAINT uq_creador_artista UNIQUE (artista_id),
    CONSTRAINT ck_creador_exactamente_uno CHECK (
        (usuario_id IS NOT NULL)::INT + (artista_id IS NOT NULL)::INT = 1
    ),
    CONSTRAINT fk_creador_usuario FOREIGN KEY (usuario_id)
        REFERENCES usuario (usuario_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_creador_artista FOREIGN KEY (artista_id)
        REFERENCES artista (artista_id)
        ON DELETE CASCADE ON UPDATE CASCADE
);

-- PLAYLIST. CREA: PLAYLIST (1,1) - CREADOR_PLAYLIST (0,N) => FK NOT NULL.
CREATE TABLE playlist (
    playlist_id         INT GENERATED ALWAYS AS IDENTITY,
    creador_playlist_id INT          NOT NULL,
    nombre              VARCHAR(100) NOT NULL,
    fecha_creacion      DATE         NOT NULL DEFAULT CURRENT_DATE,
    es_colaborativa     BOOLEAN      NOT NULL DEFAULT FALSE,
    CONSTRAINT pk_playlist PRIMARY KEY (playlist_id),
    CONSTRAINT fk_playlist_creador FOREIGN KEY (creador_playlist_id)
        REFERENCES creador_playlist (creador_playlist_id)
        ON DELETE CASCADE ON UPDATE CASCADE
);

-- ---------------------------------------------------------------------
-- INCLUYE (N:M, Regla 5) con atributos propios. La AGREGACIÓN
-- (INCLUYE <- AGREGA -> USUARIO, (1,1)) se transforma agregando
-- agregado_por_usuario_id NOT NULL a la tabla de la relación agregada.
-- ---------------------------------------------------------------------
CREATE TABLE playlist_pista (
    playlist_id             INT  NOT NULL,
    pista_id                INT  NOT NULL,
    agregado_por_usuario_id INT  NOT NULL,
    posicion                INT  NOT NULL,
    fecha_agregado          DATE NOT NULL DEFAULT CURRENT_DATE,
    CONSTRAINT pk_playlist_pista PRIMARY KEY (playlist_id, pista_id),
    CONSTRAINT uq_playlist_posicion UNIQUE (playlist_id, posicion)
        DEFERRABLE INITIALLY DEFERRED,
    CONSTRAINT ck_playlist_posicion CHECK (posicion > 0),
    CONSTRAINT fk_pp_playlist FOREIGN KEY (playlist_id)
        REFERENCES playlist (playlist_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_pp_pista FOREIGN KEY (pista_id)
        REFERENCES pista_audio (pista_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_pp_usuario FOREIGN KEY (agregado_por_usuario_id)
        REFERENCES usuario (usuario_id)
        ON DELETE RESTRICT ON UPDATE CASCADE
);

-- ---------------------------------------------------------------------
-- DISPOSITIVO: entidad DÉBIL con dependencia de identificación (Regla 8).
-- PK = (usuario_id, dispositivo_num); FK NOT NULL con ON DELETE CASCADE.
-- ---------------------------------------------------------------------
CREATE TABLE dispositivo (
    usuario_id        INT         NOT NULL,
    dispositivo_num   INT         NOT NULL,
    tipo              VARCHAR(30) NOT NULL,
    sistema_operativo VARCHAR(40) NOT NULL,
    CONSTRAINT pk_dispositivo PRIMARY KEY (usuario_id, dispositivo_num),
    CONSTRAINT ck_dispositivo_num CHECK (dispositivo_num > 0),
    CONSTRAINT fk_dispositivo_usuario FOREIGN KEY (usuario_id)
        REFERENCES usuario (usuario_id)
        ON DELETE CASCADE ON UPDATE CASCADE
);

-- ---------------------------------------------------------------------
-- REPRODUCCION: entidad DÉBIL de USUARIO (Regla 8).
-- PK = (usuario_id, num_reproduccion).
-- ES_DE (1,1) con PISTA_AUDIO y SE_ESCUCHA_EN (1,1) con DISPOSITIVO
-- => ambas FK NOT NULL. La FK compuesta (usuario_id, dispositivo_num)
-- asegura que el dispositivo pertenece al mismo usuario que reproduce.
-- ---------------------------------------------------------------------
CREATE TABLE reproduccion (
    usuario_id          INT       NOT NULL,
    num_reproduccion    INT       NOT NULL,
    dispositivo_num     INT       NOT NULL,
    pista_id            INT       NOT NULL,
    timestamp_inicio    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    segundos_escuchados INT       NOT NULL DEFAULT 0,
    fue_completa        BOOLEAN   NOT NULL DEFAULT FALSE,
    CONSTRAINT pk_reproduccion PRIMARY KEY (usuario_id, num_reproduccion),
    CONSTRAINT ck_repro_num CHECK (num_reproduccion > 0),
    CONSTRAINT ck_repro_segundos CHECK (segundos_escuchados >= 0),
    CONSTRAINT fk_repro_usuario FOREIGN KEY (usuario_id)
        REFERENCES usuario (usuario_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_repro_dispositivo FOREIGN KEY (usuario_id, dispositivo_num)
        REFERENCES dispositivo (usuario_id, dispositivo_num)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_repro_pista FOREIGN KEY (pista_id)
        REFERENCES pista_audio (pista_id)
        ON DELETE RESTRICT ON UPDATE CASCADE
);

-- ---------------------------------------------------------------------
-- MODELO_RECOMENDACION (Regla 1)
-- ---------------------------------------------------------------------
CREATE TABLE modelo_recomendacion (
    modelo_id INT GENERATED ALWAYS AS IDENTITY,
    nombre    VARCHAR(100) NOT NULL,
    version   VARCHAR(20)  NOT NULL,
    CONSTRAINT pk_modelo_recomendacion PRIMARY KEY (modelo_id),
    CONSTRAINT uq_modelo_nombre_version UNIQUE (nombre, version)
);

-- ---------------------------------------------------------------------
-- RECOMIENDA: relación TERNARIA (Regla 7). PK = las tres claves.
-- ---------------------------------------------------------------------
CREATE TABLE recomendacion (
    usuario_id           INT           NOT NULL,
    modelo_id            INT           NOT NULL,
    pista_id             INT           NOT NULL,
    score                NUMERIC(5,4)  NOT NULL,
    fecha_recomendacion  TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fue_aceptada         BOOLEAN       NOT NULL DEFAULT FALSE,
    CONSTRAINT pk_recomendacion PRIMARY KEY (usuario_id, modelo_id, pista_id),
    CONSTRAINT ck_recomendacion_score CHECK (score BETWEEN 0 AND 1),
    CONSTRAINT fk_rec_usuario FOREIGN KEY (usuario_id)
        REFERENCES usuario (usuario_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_rec_modelo FOREIGN KEY (modelo_id)
        REFERENCES modelo_recomendacion (modelo_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_rec_pista FOREIGN KEY (pista_id)
        REFERENCES pista_audio (pista_id)
        ON DELETE CASCADE ON UPDATE CASCADE
);

-- ---------------------------------------------------------------------
-- Índices sobre claves foráneas que no son prefijo de una PK/UNIQUE
-- ---------------------------------------------------------------------
CREATE INDEX ix_album_artista        ON album (artista_id);
CREATE INDEX ix_cancion_album        ON cancion (album_id);
CREATE INDEX ix_playlist_creador     ON playlist (creador_playlist_id);
CREATE INDEX ix_pp_pista             ON playlist_pista (pista_id);
CREATE INDEX ix_repro_pista          ON reproduccion (pista_id);
CREATE INDEX ix_repro_timestamp      ON reproduccion (timestamp_inicio);
CREATE INDEX ix_ac_pista             ON artista_cancion (pista_id);
CREATE INDEX ix_rec_modelo           ON recomendacion (modelo_id);
CREATE INDEX ix_rec_pista            ON recomendacion (pista_id);

-- ---------------------------------------------------------------------
-- Atributo DERIVADO oyentes_mensuales: se calcula, no se almacena.
-- Oyentes únicos en los últimos 30 días de canciones que interpreta o
-- episodios que conduce el artista.
-- ---------------------------------------------------------------------
CREATE VIEW v_artista AS
SELECT a.artista_id,
       a.nombre,
       a.pais_origen,
       (SELECT COUNT(DISTINCT r.usuario_id)
          FROM reproduccion r
         WHERE r.timestamp_inicio >= CURRENT_TIMESTAMP - INTERVAL '30 days'
           AND (r.pista_id IN (SELECT ac.pista_id
                                 FROM artista_cancion ac
                                WHERE ac.artista_id = a.artista_id)
             OR r.pista_id IN (SELECT e.pista_id
                                 FROM episodio_podcast e
                                WHERE e.artista_conductor_id = a.artista_id))
       ) AS oyentes_mensuales
  FROM artista a;

COMMIT;