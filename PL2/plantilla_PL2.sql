\pset pager off

SET client_encoding = 'UTF8';

BEGIN;

\echo 'Creando esquema temporal'

CREATE SCHEMA IF NOT EXISTS temporal;

-- Crear tablas temporales en el esquema "temporal" con todos los campos como tipo TEXT y sin restricciones
CREATE TABLE IF NOT EXISTS temporal.discos(
    Titulo TEXT,
    Anno_publicacion TEXT,
    Generos TEXT,
    Url_portada TEXT
);

CREATE TABLE IF NOT EXISTS temporal.grupos(
    Nombre TEXT,
    Url_grupo TEXT
);

CREATE TABLE IF NOT EXISTS temporal.usuario(
    Nombre_usuario TEXT,
    Nombre TEXT,
    Email TEXT,
    Contrasena TEXT
);

CREATE TABLE IF NOT EXISTS temporal.canciones(
    Titulo TEXT,
    Duracion TEXT,
    Titulo_disco TEXT,
    Anno_disco TEXT
);

CREATE TABLE IF NOT EXISTS temporal.ediciones(
    Formato TEXT,
    Anno_edicion TEXT,
    Pais TEXT,
    Titulo_disco TEXT,
    Anno_disco TEXT
);

--CREATE TABLE IF NOT EXISTS temporal.edita(
--    Nombre_grupo TEXT,
--    Titulo_disco TEXT,
--    Anno_disco TEXT
--);

CREATE TABLE IF NOT EXISTS temporal.desea(
    Nombre_usuario TEXT,
    Titulo_disco TEXT,
    Anno_disco TEXT
);

CREATE TABLE IF NOT EXISTS temporal.tiene(
    Nombre_usuario TEXT,
    Titulo_disco TEXT,
    Anno_disco TEXT,
    Formato_edicion TEXT,
    Anno_edicion TEXT,
    Pais_edicion TEXT
);

\echo 'Esquema temporal creado con exito'

-- Cargar datos desde los CSV al esquema temporal
\copy temporal.discos FROM 'discos.csv' WITH CSV HEADER;
\copy temporal.usuario FROM 'usuarios.csv' WITH CSV HEADER;
\copy temporal.canciones FROM 'canciones.csv' WITH CSV HEADER;
\copy temporal.ediciones FROM 'ediciones.csv' WITH CSV HEADER;
\copy temporal.desea FROM 'usuario_desea_disco.csv' WITH CSV HEADER;
\copy temporal.tiene FROM 'usuario_tiene_edicion.csv' WITH CSV HEADER;

\echo 'Datos cargados en el esquema temporal'

\echo 'Creando esquema final para la BBDD de discos'

CREATE SCHEMA IF NOT EXISTS bbdd;

-- Tabla Discos
CREATE TABLE bbdd.discos (
    Titulo VARCHAR(100) NOT NULL,
    Anno_publicacion INT,
    Generos VARCHAR(100),
    Url_portada TEXT,
    PRIMARY KEY (Titulo, Anno_publicacion)
);

-- Tabla Grupo
CREATE TABLE bbdd.grupos (
    Nombre VARCHAR(100) NOT NULL,
    Url_grupo TEXT,
    PRIMARY KEY (Nombre)
);

-- Tabla Usuario
CREATE TABLE bbdd.usuario (
    Nombre_usuario VARCHAR(100) NOT NULL,
    Nombre VARCHAR(100),
    Email VARCHAR(100),
    Contrasena VARCHAR(100),
    PRIMARY KEY (Nombre_usuario)
);

-- Tabla Canciones
CREATE TABLE bbdd.canciones (
    Titulo VARCHAR(100) NOT NULL,
    Duracion INTERVAL,
    Titulo_disco VARCHAR(100),
    Anno_disco INT,
    PRIMARY KEY (Titulo),
    FOREIGN KEY (Titulo_disco, Anno_disco) REFERENCES bbdd.discos(Titulo, Anno_publicacion)
);

-- Tabla Ediciones
CREATE TABLE bbdd.ediciones (
    Formato VARCHAR(100),
    Anno_edicion INT,
    Pais VARCHAR(100),
    Titulo_disco VARCHAR(100),
    Anno_disco INT,
    PRIMARY KEY (Formato, Anno_edicion, Pais),
    FOREIGN KEY (Titulo_disco, Anno_disco) REFERENCES bbdd.discos(Titulo, Anno_publicacion)
);

-- Tabla Edita (relacion discos - Grupo)
CREATE TABLE bbdd.edita (
    Nombre_grupo VARCHAR(100),
    Titulo_disco VARCHAR(100),
    Anno_disco INT,
    PRIMARY KEY (Nombre_grupo, Titulo_disco, Anno_disco),
    FOREIGN KEY (Nombre_grupo) REFERENCES bbdd.grupos(Nombre),
    FOREIGN KEY (Titulo_disco, Anno_disco) REFERENCES bbdd.discos(Titulo, Anno_publicacion)
);

-- Tabla Tiene (relacion Usuario - Ediciones)
CREATE TABLE bbdd.tiene (
    Nombre_usuario VARCHAR(255),
    Titulo_disco VARCHAR(100),
    Anno_disco INT,
    Formato_edicion VARCHAR(100),
    Anno_edicion INT,
    Pais_edicion VARCHAR(100),
    PRIMARY KEY (Nombre_usuario, Formato_edicion, Anno_edicion, Pais),
    FOREIGN KEY (Nombre_usuario) REFERENCES bbdd.usuario(Nombre_usuario),
    FOREIGN KEY (Titulo_disco, Anno_disco) REFERENCES bbdd.discos(Titulo, Anno_publicacion),
    FOREIGN KEY (Formato_edicion, Anno_edicion, Pais_edicion) REFERENCES bbdd.ediciones(Formato, Anno_edicion, Pais)
);

-- Tabla Desea (relacion Usuario - Ediciones)
CREATE TABLE bbdd.desea (
    Nombre_usuario VARCHAR(255),
    Titulo_disco VARCHAR(100),
    Anno_disco INT,
    PRIMARY KEY (Nombre_usuario, Titulo_disco, Anno_disco),
    FOREIGN KEY (Nombre_usuario) REFERENCES bbdd.usuario(Nombre_usuario),
    FOREIGN KEY (Titulo_disco, Anno_disco) REFERENCES bbdd.discos(Titulo, Anno_publicacion)
);

\echo 'Esquema final creado con exito'



-- Insertacion de datos del esquema temporal al esquema final
\echo 'Insertando datos en el esquema final'

INSERT INTO bbdd.discos (Titulo, Anno_publicacion, Generos, Url_portada)
SELECT Titulo, CAST(Anno_publicacion AS INT), Generos, Url_portada
FROM temporal.discos
WHERE Titulo IS NOT NULL;

INSERT INTO bbdd.grupos (Nombre, Url_grupo)
SELECT Nombre, Url_grupo
FROM temporal.grupos
WHERE Nombre IS NOT NULL;

INSERT INTO bbdd.usuario (Nombre_usuario, Nombre, Email, Contrasena)
SELECT Nombre_usuario, Nombre, Email, Contrasena
FROM temporal.usuario
WHERE Nombre_usuario IS NOT NULL;

INSERT INTO bbdd.canciones (Titulo, Duracion, Titulo_disco, Anno_disco)
SELECT 
    Titulo,
    TO_TIMESTAMP(SPLIT_PART(Duracion, ':', 1) || ':' || SPLIT_PART(Duracion, ':', 2), 'MI:SS') - TIMESTAMP '1970-01-01 00:00:00' AS Duracion,
    Titulo_disco,
    CAST(Anno_disco AS INT)
FROM temporal.canciones
WHERE Titulo IS NOT NULL;

INSERT INTO bbdd.ediciones (Formato, Anno_edicion, Pais, Titulo_disco, Anno_disco)
SELECT Formato, CAST(Anno_edicion AS INT), Pais, Titulo_disco, CAST(Anno_disco AS INT)
FROM temporal.ediciones
WHERE Formato IS NOT NULL AND Pais IS NOT NULL;

INSERT INTO bbdd.desea (Nombre_usuario, Titulo_disco, Anno_disco)
SELECT Nombre_usuario, Titulo_disco, CAST(Anno_disco AS INT)
FROM temporal.desea
WHERE Nombre_usuario IS NOT NULL;

INSERT INTO bbdd.tiene (Nombre_usuario, Titulo_disco, Anno_disco, Formato_edicion, Anno_edicion, Pais_edicion)
SELECT Nombre_usuario, Titulo_disco, CAST(Anno_disco AS INT), Formato_edicion, Anno_edicion, Pais_edicion
FROM temporal.tiene
WHERE Nombre_usuario IS NOT NULL;

\echo 'Datos insertados al esquema final'

-- Eliminar esquema temporal
DROP SCHEMA IF EXISTS temporal CASCADE;

\echo 'Esquema temporal eliminado'



-- Consultas a realizar
\echo 'Realizando consultas solicitadas'

\echo 'Consulta 1: Mostrar los discos que tengan mas de 5 canciones.'

SELECT Titulo_disco, Anno_disco
FROM canciones
GROUP BY Titulo_disco, Anno_disco
HAVING COUNT(Titulo) > 5;


\echo 'Consulta 2: Mostrar los vinilos que tiene el usuario Juan Garcia Gomez junto con el titulo del
disco, y el pais y anno de edicion'

SELECT ediciones.Titulo_disco, ediciones.Anno_disco, ediciones.Pais, ediciones.Anno_edicion
FROM tiene
JOIN ediciones ON tiene.Formato_edicion = ediciones.Formato AND tiene.Anno_edicion = ediciones.Anno_edicion AND tiene.Pais_edicion = ediciones.Pais
JOIN usuario ON tiene.Nombre_usuario = usuario.Nombre_usuario
WHERE usuario.Nombre = 'Juan Garcia Gomez';


\echo 'Consulta 3: discos con mayor duracion de la coleccion.'

SELECT Titulo_disco, Anno_disco, SUM(EXTRACT(EPOCH FROM Duracion)) AS Duracion_total
FROM canciones
GROUP BY Titulo_disco, Anno_disco
ORDER BY Duracion_total DESC
LIMIT 1;


\echo 'Consulta 4: De los discos que tiene en su lista de deseos el usuario Juan Garcia Gomez,
indicar el nombre de los grupos musicales que los interpretan.'

SELECT DISTINCT grupos.Nombre
FROM desea
JOIN edita ON desea.Titulo_disco = edita.Titulo_disco AND desea.Anno_disco = edita.Anno_disco
JOIN grupos ON edita.Nombre_grupo = grupos.Nombre
JOIN usuario ON desea.Nombre_usuario = usuario.Nombre_usuario
WHERE usuario.Nombre = 'Juan Garcia Gomez';


\echo 'Consulta 5: Mostrar los discos publicados entre 1970 y 1972 junto con sus ediciones
ordenados por el anno de publicacion'

SELECT discos.Titulo, discos.Anno_publicacion, ediciones.Formato, ediciones.Anno_edicion, ediciones.Pais
FROM discos
JOIN ediciones ON discos.Titulo = ediciones.Titulo_disco AND discos.Anno_publicacion = ediciones.Anno_disco
WHERE discos.Anno_publicacion BETWEEN 1970 AND 1972
ORDER BY discos.Anno_publicacion;


\echo 'Consulta 6: Listar el nombre de todos los grupos que han publicado discos del genero
‘Electronic’.'

SELECT DISTINCT grupos.Nombre
FROM discos
JOIN edita ON discos.Titulo = edita.Titulo_disco AND discos.Anno_publicacion = edita.Anno_disco
JOIN grupos ON edita.Nombre_grupo = grupos.Nombre
WHERE discos.Generos LIKE 'Electronic';


\echo 'Consulta 7: Lista de discos con la duracion total del mismo, editados antes del anno 2000'

SELECT discos.Titulo, discos.Anno_publicacion, SUM(EXTRACT(EPOCH FROM canciones.Duracion)) AS Duracion_total
FROM discos
JOIN canciones ON discos.Titulo = canciones.Titulo_disco AND discos.Anno_publicacion = canciones.Anno_disco
WHERE discos.Anno_publicacion < 2000
GROUP BY discos.Titulo, discos.Anno_publicacion;


\echo 'Consulta 8: Lista de ediciones de discos deseados por el usuario Lorena Saez Perez que tiene
el usuario Juan Garcia Gomez.'

SELECT desea.Titulo_disco, desea.Anno_disco, ediciones.Formato, ediciones.Anno_edicion, ediciones.Pais
FROM desea
JOIN tiene ON desea.Titulo_disco = tiene.Titulo_disco AND desea.Anno_disco = tiene.Anno_disco
JOIN usuario AS UsuarioDesea ON desea.Nombre_usuario = UsuarioDesea.Nombre_usuario
JOIN usuario AS UsuarioTiene ON tiene.Nombre_usuario = UsuarioTiene.Nombre_usuario
JOIN ediciones ON desea.Titulo_disco = ediciones.Titulo_disco AND desea.Anno_disco = ediciones.Anno_disco
WHERE UsuarioDesea.Nombre = 'Lorena Saez Perez' AND UsuarioTiene.Nombre = 'Juan Garcia Gomez';


\echo 'Consulta 9: Lista todas las ediciones de los discos que tiene el usuario Gomez Garcia en un
estado NM o M.'

SELECT ediciones.Titulo_disco, ediciones.Anno_disco, ediciones.Formato, ediciones.Anno_edicion, ediciones.Pais
FROM tiene
JOIN ediciones ON tiene.Formato_edicion = ediciones.Formato AND tiene.Anno_edicion = ediciones.Anno_edicion AND tiene.Pais_edicion = ediciones.Pais
JOIN usuario ON tiene.Nombre_usuario = usuario.Nombre_usuario
WHERE usuario.Nombre = 'Gomez Garcia' AND (ediciones.Estado = 'NM' OR ediciones.Estado = 'M');


\echo 'Consulta 10: Listar todos los usuarios junto al numero de ediciones que tiene de todos los discos
junto al anno de lanzamiento de su disco mas antiguo, el anno de lanzamiento de su
disco mas nuevo, y el anno medio de todos sus discos de su coleccion.'

SELECT usuario.Nombre, COUNT(ediciones.Titulo_disco) AS num_ediciones, MIN(discos.Anno_publicacion) AS anno_min, MAX(discos.Anno_publicacion) AS anno_max, AVG(discos.Anno_publicacion) AS anno_medio
FROM tiene
JOIN ediciones ON tiene.Formato_edicion = ediciones.Formato AND tiene.Anno_edicion = ediciones.Anno_edicion AND tiene.Pais_edicion = ediciones.Pais
JOIN discos ON ediciones.Titulo_disco = discos.Titulo AND ediciones.Anno_disco = discos.Anno_publicacion
JOIN usuario ON tiene.Nombre_usuario = usuario.Nombre_usuario
GROUP BY usuario.Nombre;


\echo 'Consulta 11: Listar el nombre de los grupos que tienen mas de 5 ediciones de sus discos en la
base de datos.'

SELECT grupos.Nombre
FROM edita
JOIN grupos ON edita.Nombre_grupo = grupos.Nombre
GROUP BY grupos.Nombre
HAVING COUNT(edita.Titulo_disco) > 5;


\echo 'Consulta 12: Lista el usuario que mas discos, contando todas sus ediciones tiene en la base de
datos.'

SELECT usuario.Nombre
FROM tiene
JOIN usuario ON tiene.Nombre_usuario = usuario.Nombre_usuario
GROUP BY usuario.Nombre
ORDER BY COUNT(tiene.Titulo_disco) DESC
LIMIT 1;


ROLLBACK;                       -- importante! permite correr el script multiples veces...p