\pset pager off

SET client_encoding = 'UTF8';

BEGIN;

\echo 'Creando esquema temporal'

CREATE SCHEMA IF NOT EXISTS temporal;

-- Crear tablas temporales en el esquema

\echo 'Creando esquema temporal.discos'
CREATE TABLE IF NOT EXISTS temporal.discos(
    Id_disco TEXT,
    Nombre TEXT,
    Anno_publicacion TEXT,
    Id_grupo TEXT,
    Nombre_grupo TEXT,
    Url_grupo TEXT,
    Generos TEXT,
    Url_portada TEXT
);


\echo 'Creando esquema temporal.usuario'
CREATE TABLE IF NOT EXISTS temporal.usuario(
    Nombre TEXT,
    Nombre_usuario TEXT,
    Email TEXT,
    Contrasena TEXT
);


\echo 'Creando esquema temporal.canciones'
CREATE TABLE IF NOT EXISTS temporal.canciones(
    Id_disco TEXT,
    Titulo TEXT,
    Duracion TEXT
);


\echo 'Creando esquema temporal.ediciones'
CREATE TABLE IF NOT EXISTS temporal.ediciones(
    Id_disco TEXT,
    Anno_edicion TEXT,
    Pais TEXT,
    Formato TEXT
);


\echo 'Creando esquema temporal.desea'
CREATE TABLE IF NOT EXISTS temporal.desea(
    Nombre_usuario TEXT,
    Nombre_discos TEXT,
    Anno_disco TEXT
);


\echo 'Creando esquema temporal.tiene'
CREATE TABLE IF NOT EXISTS temporal.tiene(
    Nombre_usuario TEXT,
    Nombre_discos TEXT,
    Anno_disco TEXT,
    Anno_edicion TEXT,
    Pais_edicion TEXT,
    Formato_edicion TEXT,
    Estado TEXT
);


\echo 'Esquema temporal creado con exito'

-- Cargar datos desde los CSV al esquema temporal

\COPY temporal.discos FROM 'discos.csv' WITH (FORMAT csv, HEADER, DELIMITER ';', NULL 'NULL', ENCODING 'UTF-8');
\COPY temporal.usuario FROM 'usuarios.csv' WITH (FORMAT csv, HEADER, DELIMITER ';', NULL 'NULL', ENCODING 'UTF-8');
\COPY temporal.canciones FROM 'canciones.csv' WITH (FORMAT csv, HEADER, DELIMITER ';', NULL 'NULL', ENCODING 'UTF-8');
\COPY temporal.ediciones FROM 'ediciones.csv' WITH (FORMAT csv, HEADER, DELIMITER ';', NULL 'NULL', ENCODING 'UTF-8');
\COPY temporal.desea FROM 'usuario_desea_disco.csv' WITH (FORMAT csv, HEADER, DELIMITER ';', NULL 'NULL', ENCODING 'UTF-8');
\COPY temporal.tiene FROM 'usuario_tiene_edicion.csv' WITH (FORMAT csv, HEADER, DELIMITER ';', NULL 'NULL', ENCODING 'UTF-8');


\echo 'Datos cargados en el esquema temporal'





\echo 'Creando esquema final para la BBDD de discos'

CREATE SCHEMA IF NOT EXISTS bbdd;


\echo 'Creando esquema final de Discos'
-- Tabla Discos
CREATE TABLE bbdd.discos (
    Nombre VARCHAR(250) NOT NULL,
    Anno_publicacion INT,
    Url_portada TEXT,
    CONSTRAINT discos_pk PRIMARY KEY (Nombre, Anno_publicacion)
);


\echo 'Creando esquema final de Grupos'
-- Tabla Grupo
CREATE TABLE bbdd.grupos (
    Nombre VARCHAR(250) NOT NULL,
    Url_grupo TEXT,
    CONSTRAINT grupos_pk PRIMARY KEY (Nombre)
);


\echo 'Creando esquema final de Usuario'
-- Tabla Usuario
CREATE TABLE bbdd.usuario (
    Nombre_usuario VARCHAR(250) NOT NULL,
    Nombre VARCHAR(250),
    Email VARCHAR(250),
    Contrasena VARCHAR(250),
    CONSTRAINT usuario_pk PRIMARY KEY (Nombre_usuario)
);


\echo 'Creando esquema final de Canciones'
-- Tabla Canciones
CREATE TABLE bbdd.canciones (
    Titulo VARCHAR(250) NOT NULL,
    Duracion VARCHAR(20),
    Nombre_discos VARCHAR(250),
    Anno_disco INT,
    CONSTRAINT canciones_pk PRIMARY KEY (Titulo),
    CONSTRAINT discos_fk FOREIGN KEY (Nombre_discos, Anno_disco) REFERENCES bbdd.discos(Nombre, Anno_publicacion)
    ON DELETE CASCADE ON UPDATE CASCADE
);


\echo 'Creando esquema final de Ediciones'
-- Tabla Ediciones
CREATE TABLE bbdd.ediciones (
    Formato VARCHAR(250),
    Anno_edicion INT,
    Pais VARCHAR(250),
    Nombre_discos VARCHAR(250),
    Anno_disco INT,
    CONSTRAINT ediciones_pk PRIMARY KEY (Formato, Anno_edicion, Pais),
    CONSTRAINT discos_fk FOREIGN KEY (Nombre_discos, Anno_disco) REFERENCES bbdd.discos(Nombre, Anno_publicacion)
    ON DELETE CASCADE ON UPDATE CASCADE
);


\echo 'Creando esquema final de Edita'
-- Tabla Edita (relacion discos - Grupo)
CREATE TABLE bbdd.edita (
    Nombre_grupo VARCHAR(250),
    Nombre_discos VARCHAR(250),
    Anno_disco INT,
    CONSTRAINT edita_pk PRIMARY KEY (Nombre_grupo, Nombre_discos, Anno_disco),
    CONSTRAINT grupos_fk FOREIGN KEY (Nombre_grupo) REFERENCES bbdd.grupos(Nombre)
    ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT discos_fk FOREIGN KEY (Nombre_discos, Anno_disco) REFERENCES bbdd.discos(Nombre, Anno_publicacion)
    ON DELETE CASCADE ON UPDATE CASCADE
);


\echo 'Creando esquema final de Tiene'
-- Tabla Tiene (relacion Usuario - Ediciones)
CREATE TABLE bbdd.tiene (
    Nombre_usuario VARCHAR(250),
    Nombre_discos VARCHAR(250),
    Anno_disco INT,
    Formato_edicion VARCHAR(250),
    Anno_edicion INT,
    Pais_edicion VARCHAR(250),
    Estado VARCHAR(250),
    CONSTRAINT tiene_pk PRIMARY KEY (Nombre_usuario, Nombre_discos, Anno_disco, Formato_edicion, Anno_edicion, Pais_edicion),
    CONSTRAINT usuario_fk FOREIGN KEY (Nombre_usuario) REFERENCES bbdd.usuario(Nombre_usuario)
    ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT discos_fk FOREIGN KEY (Nombre_discos, Anno_disco) REFERENCES bbdd.discos(Nombre, Anno_publicacion)
    ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT ediciones_fk FOREIGN KEY (Formato_edicion, Anno_edicion, Pais_edicion) REFERENCES bbdd.ediciones(Formato, Anno_edicion, Pais)
    ON DELETE CASCADE ON UPDATE CASCADE
);


\echo 'Creando esquema final de Desea'
-- Tabla Desea (relacion Usuario - Ediciones)
CREATE TABLE bbdd.desea (
    Nombre_usuario VARCHAR(250),
    Nombre_discos VARCHAR(250),
    Anno_disco INT,
    CONSTRAINT desea_pk PRIMARY KEY (Nombre_usuario, Nombre_discos, Anno_disco),
    CONSTRAINT usuario_fk FOREIGN KEY (Nombre_usuario) REFERENCES bbdd.usuario(Nombre_usuario)
    ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT discos_fk FOREIGN KEY (Nombre_discos, Anno_disco) REFERENCES bbdd.discos(Nombre, Anno_publicacion)
    ON DELETE CASCADE ON UPDATE CASCADE
);


\echo 'Esquema final creado con exito'





-- Insertacion de datos del esquema temporal al esquema final
\echo 'Insertando datos en el esquema final'

\echo 'Insertamos los datos de temporal.discos a bbdd.discos'
INSERT INTO bbdd.discos (Nombre, Anno_publicacion, Url_portada)
SELECT DISTINCT
    discos.Nombre,
    discos.Anno_publicacion::INT,
    discos.Url_portada
FROM temporal.discos
ON CONFLICT (Nombre,Anno_publicacion) DO NOTHING;


\echo 'Insertamos los datos de temporal.grupos a bbdd.grupos'
INSERT INTO bbdd.grupos (Nombre, Url_grupo)
SELECT DISTINCT
    discos.Nombre_grupo,
    discos.Url_grupo
FROM temporal.discos discos
LEFT JOIN bbdd.grupos grupos ON discos.Nombre_grupo = grupos.Nombre
WHERE discos.Nombre_grupo IS NOT NULL AND grupos.Nombre IS NULL;


\echo 'Insertamos los datos de temporal.usuario a bbdd.usuario'
INSERT INTO bbdd.usuario (Nombre, Nombre_usuario, Email, Contrasena)
SELECT DISTINCT
    usuario.Nombre,
    usuario.Nombre_usuario,
    usuario.Email,
    usuario.Contrasena
FROM temporal.usuario
ON CONFLICT (Nombre_usuario) DO NOTHING;


\echo 'Insertamos los datos de temporal.canciones a bbdd.canciones'
-- INSERT INTO bbdd.canciones (Titulo, Duracion, Nombre_discos, Anno_disco)
INSERT INTO bbdd.canciones (Titulo, Duracion, Nombre_discos, Anno_disco)
SELECT DISTINCT
    canciones.Titulo,
    TO_CHAR(
        MAKE_INTERVAL(
            mins => SPLIT_PART(canciones.Duracion, ':', 1)::INT,
            secs => SPLIT_PART(canciones.Duracion, ':', 2)::INT
        )::TIME,
        'MI:SS'
    ) AS Duracion,
    discos.Nombre,
    discos.Anno_publicacion::INT
FROM temporal.canciones
JOIN temporal.discos ON canciones.Id_disco = discos.Id_disco
ON CONFLICT (Titulo) DO NOTHING;



\echo 'Insertamos los datos de temporal.ediciones a bbdd.ediciones'
INSERT INTO bbdd.ediciones (Formato, Anno_edicion, Pais, Nombre_discos, Anno_disco)
SELECT DISTINCT
    ediciones.Formato,
    ediciones.Anno_edicion::INT,
    ediciones.Pais,
    discos.Nombre,
    discos.Anno_publicacion::INT
FROM temporal.ediciones
JOIN temporal.discos ON ediciones.Id_disco = discos.Id_disco
ON CONFLICT (Formato, Anno_edicion, Pais) DO NOTHING;


\echo 'Insertamos los datos de temporal.discos a bbdd.edita'
INSERT INTO bbdd.edita (Nombre_grupo, Nombre_discos, Anno_disco)
SELECT DISTINCT
    discos.Nombre_grupo,
    discos.Nombre,
    discos.Anno_publicacion::INT
FROM temporal.discos discos
WHERE discos.Nombre_grupo IS NOT NULL
ON CONFLICT (Nombre_grupo, Nombre_discos, Anno_disco) DO NOTHING;


\echo 'Insertamos los datos de temporal.tiene a bbdd.tiene'
INSERT INTO bbdd.tiene (Nombre_usuario, Nombre_discos, Anno_disco, Formato_edicion, Anno_edicion, Pais_edicion, Estado)
SELECT DISTINCT
    usuario.Nombre_usuario,
    discos.Nombre,
    discos.Anno_publicacion::INT,
    ediciones.Formato,
    ediciones.Anno_edicion::INT,
    ediciones.Pais,
    tiene.Estado
FROM temporal.tiene
JOIN temporal.discos discos ON tiene.Nombre_discos = discos.Nombre
JOIN temporal.ediciones ediciones ON tiene.Nombre_discos = discos.Nombre AND tiene.Anno_disco = ediciones.Anno_edicion AND discos.Id_disco = ediciones.Id_disco
JOIN temporal.usuario usuario ON tiene.Nombre_usuario = usuario.Nombre_usuario
ON CONFLICT (Nombre_usuario, Nombre_discos, Anno_disco, Formato_edicion, Anno_edicion, Pais_edicion) DO NOTHING;


\echo 'Insertamos los datos de temporal.desea a bbdd.desea'
INSERT INTO bbdd.desea (Nombre_usuario, Nombre_discos, Anno_disco)
SELECT DISTINCT
    usuario.Nombre_usuario,
    discos.Nombre,
    discos.Anno_publicacion::INT
FROM temporal.desea
JOIN temporal.discos discos ON desea.Nombre_discos = discos.Nombre
JOIN temporal.usuario usuario ON desea.Nombre_usuario = usuario.Nombre_usuario
ON CONFLICT (Nombre_usuario, Nombre_discos, Anno_disco) DO NOTHING;


\echo 'Datos insertados al esquema final'





\echo 'Realizando consultas solicitadas'

\echo 'Consulta 1: Mostrar los discos que tengan mas de 5 canciones.'

SELECT Nombre_discos, Anno_disco
FROM bbdd.canciones
GROUP BY Nombre_discos, Anno_disco
HAVING COUNT(Nombre_discos) > 5;


\echo 'Consulta 2: Mostrar los vinilos que tiene el usuario Juan Garcia Gomez junto con el titulo del disco, y el pais y anno de edicion'

SELECT DISTINCT
    ediciones.Nombre_discos,
    ediciones.Pais,
    ediciones.Anno_edicion
FROM bbdd.tiene
JOIN bbdd.ediciones ON tiene.Formato_edicion = ediciones.Formato AND tiene.Anno_edicion = ediciones.Anno_edicion AND tiene.Pais_edicion = ediciones.Pais
JOIN bbdd.usuario ON tiene.Nombre_usuario = usuario.Nombre_usuario
WHERE usuario.Nombre = '%Juan Garcia Gomez%';


\echo 'Consulta 3: Disco con mayor duración de la colección.'

SELECT 
    discos.Nombre AS Nombre_disco,
    discos.Anno_publicacion,
    SUM(EXTRACT(EPOCH FROM ('00:' || canciones.Duracion)::INTERVAL)) AS Duracion_total_segundos
FROM bbdd.canciones canciones
JOIN bbdd.discos discos ON canciones.Nombre_discos = discos.Nombre AND canciones.Anno_disco = discos.Anno_publicacion
GROUP BY discos.Nombre, discos.Anno_publicacion
ORDER BY Duracion_total_segundos DESC
LIMIT 1;


\echo 'Consulta 4: De los discos que tiene en su lista de deseos el usuario Juan Garcia Gomez, indicar el nombre de los grupos musicales que los interpretan.'

SELECT DISTINCT grupos.Nombre
FROM bbdd.desea
JOIN bbdd.edita ON desea.Nombre_discos = edita.Nombre_discos AND desea.Anno_disco = edita.Anno_disco
JOIN bbdd.grupos ON edita.Nombre_grupo = grupos.Nombre
JOIN bbdd.usuario ON desea.Nombre_usuario = usuario.Nombre_usuario
WHERE usuario.Nombre = '%Juan Garcia Gomez%';


\echo 'Consulta 5: Mostrar los discos publicados entre 1970 y 1972 junto con sus ediciones ordenados por el anno de publicacion'

SELECT discos.Nombre, discos.Anno_publicacion, ediciones.Formato, ediciones.Anno_edicion, ediciones.Pais
FROM bbdd.discos
JOIN bbdd.ediciones ON discos.Nombre = ediciones.Nombre_discos AND discos.Anno_publicacion = ediciones.Anno_disco
WHERE discos.Anno_publicacion BETWEEN 1970 AND 1972
ORDER BY discos.Anno_publicacion;


\echo 'Consulta 6: . Listar el nombre de todos los grupos que han publicado discos del género ‘Electronic’.'

SELECT DISTINCT grupos.Nombre
FROM bbdd.discos
JOIN bbdd.edita ON discos.Nombre = edita.Nombre_discos AND discos.Anno_publicacion = edita.Anno_disco
JOIN bbdd.grupos ON edita.Nombre_grupo = grupos.Nombre
WHERE EXISTS (
    SELECT 1
    FROM temporal.discos temp_discos
    WHERE temp_discos.Nombre = discos.Nombre
      AND temp_discos.Anno_publicacion::INT = discos.Anno_publicacion
      AND temp_discos.Generos LIKE '%Electronic%'
);


\echo 'Consulta 7: Lista de discos con la duración total del mismo, editados antes del año 2000.'

SELECT 
    discos.Nombre AS Nombre_disco, 
    discos.Anno_publicacion AS Anno_disco, 
    SUM(EXTRACT(EPOCH FROM TO_TIMESTAMP(canciones.Duracion, 'MI:SS'))) AS Duracion_total_segundos
FROM bbdd.discos
JOIN bbdd.canciones ON discos.Nombre = canciones.Nombre_discos AND discos.Anno_publicacion = canciones.Anno_disco
WHERE discos.Anno_publicacion < 2000
GROUP BY discos.Nombre, discos.Anno_publicacion;



\echo 'Consulta 8: Lista de ediciones de discos deseados por el usuario Lorena Saez Perez que tiene el usuario Juan Garcia Gomez.'

SELECT desea.Nombre_discos, desea.Anno_disco, ediciones.Formato, ediciones.Anno_edicion, ediciones.Pais
FROM bbdd.desea
JOIN bbdd.tiene ON desea.Nombre_discos = tiene.Nombre_discos AND desea.Anno_disco = tiene.Anno_disco
JOIN bbdd.usuario AS UsuarioDesea ON desea.Nombre_usuario = UsuarioDesea.Nombre_usuario
JOIN bbdd.usuario AS UsuarioTiene ON tiene.Nombre_usuario = UsuarioTiene.Nombre_usuario
JOIN bbdd.ediciones ON desea.Nombre_discos = ediciones.Nombre_discos AND desea.Anno_disco = ediciones.Anno_disco
WHERE UsuarioDesea.Nombre = 'Lorena Saez Perez' AND UsuarioTiene.Nombre = 'Juan Garcia Gomez';


\echo 'Consulta 9: Lista todas las ediciones de los discos que tiene el usuario Gómez García en un estado NM o M.'

SELECT ediciones.Nombre_discos, ediciones.Anno_disco, ediciones.Formato, ediciones.Anno_edicion, ediciones.Pais, tiene.Estado
FROM bbdd.tiene
JOIN bbdd.ediciones ON tiene.Formato_edicion = ediciones.Formato AND tiene.Anno_edicion = ediciones.Anno_edicion AND tiene.Pais_edicion = ediciones.Pais
JOIN bbdd.usuario ON tiene.Nombre_usuario = usuario.Nombre_usuario
WHERE usuario.Nombre = 'Gomez Garcia' AND (tiene.Estado = 'NM' OR tiene.Estado = 'M');


\echo 'Consulta 10: Listar todos los usuarios junto al número de ediciones'

SELECT usuario.Nombre, COUNT(ediciones.Nombre_discos) AS num_ediciones, MIN(discos.Anno_publicacion) AS anno_min, MAX(discos.Anno_publicacion) AS anno_max, AVG(discos.Anno_publicacion) AS anno_medio
FROM bbdd.tiene
JOIN bbdd.ediciones ON tiene.Formato_edicion = ediciones.Formato AND tiene.Anno_edicion = ediciones.Anno_edicion AND tiene.Pais_edicion = ediciones.Pais
JOIN bbdd.discos ON ediciones.Nombre_discos = discos.Nombre AND ediciones.Anno_disco = discos.Anno_publicacion
JOIN bbdd.usuario ON tiene.Nombre_usuario = usuario.Nombre_usuario
GROUP BY usuario.Nombre;


\echo 'Consulta 11: Listar el nombre de los grupos que tienen mas de 5 ediciones de sus discos en la base de datos.'

SELECT grupos.Nombre
FROM bbdd.edita
JOIN bbdd.grupos ON edita.Nombre_grupo = grupos.Nombre
GROUP BY grupos.Nombre
HAVING COUNT(edita.Nombre_discos) > 5;


\echo 'Consulta 12: Lista el usuario que mas discos, contando todas sus ediciones tiene en la base de datos.'

SELECT usuario.Nombre
FROM bbdd.tiene
JOIN bbdd.usuario ON tiene.Nombre_usuario = usuario.Nombre_usuario
GROUP BY usuario.Nombre
ORDER BY COUNT(tiene.Nombre_discos) DESC
LIMIT 1;





ROLLBACK;                     -- importante! permite correr el script multiples veces...