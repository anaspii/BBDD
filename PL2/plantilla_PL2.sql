\pset pager off


SET client_encoding = 'UTF8';


BEGIN;


\echo 'Creando esquema temporal'


CREATE SCHEMA IF NOT EXISTS temporal;


-- Crear tablas temporales en el esquema
CREATE TABLE IF NOT EXISTS temporal.discos(
    Id_disco TEXT,
    Titulo TEXT,
    Anno_publicacion TEXT,
    Nombre_grupo TEXT,
    Generos TEXT,
    Url_portada TEXT
);


CREATE TABLE IF NOT EXISTS temporal.grupos(
    Nombre TEXT,
    Url_grupo TEXT
);


CREATE TABLE IF NOT EXISTS temporal.usuario(
    Nombre TEXT,
    Nombre_usuario TEXT,
    Email TEXT,
    Contrasena TEXT
);


CREATE TABLE IF NOT EXISTS temporal.canciones(
    Id_disco TEXT,
    Titulo TEXT,
    Duracion TEXT
);


CREATE TABLE IF NOT EXISTS temporal.ediciones(
    Id_disco TEXT,
    Anno_edicion TEXT,
    Pais TEXT,
    Formato TEXT
);


CREATE TABLE IF NOT EXISTS temporal.desea(
    Nombre_usuario TEXT,
    Titulo_disco TEXT,
    Anno_publicacion TEXT
);


CREATE TABLE IF NOT EXISTS temporal.tiene(
    Nombre_usuario TEXT,
    Titulo_disco TEXT,
    Anno_publicacion TEXT,
    Anno_edicion TEXT,
    Pais_edicion TEXT,
    Formato_edicion TEXT,
    Estado TEXT
);


\echo 'Esquema temporal creado con exito'


-- Cargar datos desde los CSV al esquema temporal
\copy temporal.discos (Id_disco, Titulo, Anno_publicacion, Nombre_grupo, Generos, Url_portada) FROM 'discos.csv' WITH CSV HEADER;
\copy temporal.usuario (Nombre, Nombre_usuario, Email, Contrasena) FROM 'usuarios.csv' WITH CSV HEADER;
\copy temporal.canciones (Id_disco, Titulo, Duracion) FROM 'canciones.csv' WITH CSV HEADER;
\copy temporal.ediciones (Id_disco, Anno_edicion, Pais, Formato) FROM 'ediciones.csv' WITH CSV HEADER;
\copy temporal.desea (Nombre_usuario, Titulo_disco, Anno_publicacion) FROM 'usuario_desea_disco.csv' WITH CSV HEADER;
\copy temporal.tiene (Nombre_usuario, Titulo_disco, Anno_publicacion, Anno_edicion, Pais, Formato) FROM 'usuario_tiene_edicion.csv' WITH CSV HEADER;


\echo 'Datos cargados en el esquema temporal'


\echo 'Creando esquema final para la BBDD de discos'


CREATE SCHEMA IF NOT EXISTS bbdd;


-- Tabla Discos
CREATE TABLE bbdd.discos (
    Id_disco INT,
    Titulo VARCHAR(100) NOT NULL,
    Anno_publicacion INT,
    Nombre_grupo VARCHAR(100) NOT NULL,
    Generos VARCHAR(100),
    Url_portada TEXT,
    PRIMARY KEY (Id_disco, Titulo, Anno_publicacion),
    FOREIGN KEY (Nombre_grupo) REFERENCES bbdd.grupos(Nombre)
);


-- Tabla Grupo
CREATE TABLE bbdd.grupos (
    Nombre VARCHAR(100) NOT NULL,
    Url_grupo TEXT,
    PRIMARY KEY (Nombre)
);


-- Tabla Usuario
CREATE TABLE bbdd.usuario (
    Nombre VARCHAR(100),
    Nombre_usuario VARCHAR(100) NOT NULL,
    Email VARCHAR(100),
    Contrasena VARCHAR(100),
    PRIMARY KEY (Nombre_usuario)
);


-- Tabla Canciones
CREATE TABLE bbdd.canciones (
    Id_disco INT,
    Titulo VARCHAR(100) NOT NULL,
    Duracion INTERVAL,
    PRIMARY KEY (Titulo),
    FOREIGN KEY (Id_disco) REFERENCES bbdd.discos(Id_disco)
);


-- Tabla Ediciones
CREATE TABLE bbdd.ediciones (
    Id_disco INT,
    Anno_edicion INT,
    Pais VARCHAR(100),
    Formato VARCHAR(100),
    PRIMARY KEY (Formato, Anno_edicion, Pais),
    FOREIGN KEY (Id_disco) REFERENCES bbdd.discos(Id_disco)
);


-- Tabla Edita (relacion discos - Grupo)
CREATE TABLE bbdd.edita (
    Nombre_grupo VARCHAR(100),
    Titulo_disco VARCHAR(100),
    Anno_publicacion INT,
    PRIMARY KEY (Nombre_grupo, Titulo_disco, Anno_publicacion),
    FOREIGN KEY (Nombre_grupo) REFERENCES bbdd.grupos(Nombre),
    FOREIGN KEY (Titulo_disco, Anno_publicacion) REFERENCES bbdd.discos(Id_disco, Titulo, Anno_publicacion)
);


-- Tabla Tiene (relacion Usuario - Ediciones)
CREATE TABLE bbdd.tiene (
    Nombre_usuario VARCHAR(255),
    Titulo_disco VARCHAR(100),
    Anno_publicacion INT,
    Anno_edicion INT,
    Pais_edicion VARCHAR(100),
    Formato_edicion VARCHAR(100),
    Estado VARCHAR(10),
    PRIMARY KEY (Nombre_usuario, Formato_edicion, Anno_edicion, Pais),
    FOREIGN KEY (Nombre_usuario) REFERENCES bbdd.usuario(Nombre_usuario),
    FOREIGN KEY (Titulo_disco, Anno_publicacion) REFERENCES bbdd.discos(Id_disco, Titulo, Anno_publicacion),
    FOREIGN KEY (Formato_edicion, Anno_edicion, Pais_edicion) REFERENCES bbdd.ediciones(Formato, Anno_edicion, Pais)
);


-- Tabla Desea (relacion Usuario - Ediciones)
CREATE TABLE bbdd.desea (
    Nombre_usuario VARCHAR(255),
    Titulo_disco VARCHAR(100),
    Anno_publicacion INT,
    PRIMARY KEY (Nombre_usuario, Titulo_disco, Anno_publicacion),
    FOREIGN KEY (Nombre_usuario) REFERENCES bbdd.usuario(Nombre_usuario),
    FOREIGN KEY (Titulo_disco, Anno_publicacion) REFERENCES bbdd.discos(Titulo, Anno_publicacion)
);


\echo 'Esquema final creado con exito'






-- Insertacion de datos del esquema temporal al esquema final
\echo 'Insertando datos en el esquema final'


INSERT INTO bbdd.discos (Id_disco, Titulo, Anno_publicacion, Nombre_grupo, Generos, Url_portada)
SELECT
    Id_disco,
    Titulo,
    Anno_publicacion,
    Nombre_grupo,
    Generos,
    Url_portada
FROM temporal.discos
WHERE Titulo IS NOT NULL;


INSERT INTO bbdd.grupos (Nombre, Url_grupo)
SELECT
    Nombre,
    Url_grupo
FROM temporal.grupos
WHERE Nombre IS NOT NULL;


INSERT INTO bbdd.usuario (Nombre, Nombre_usuario, Email, Contrasena)
SELECT
    Nombre,
    Nombre_usuario,
    Email,
    Contrasena
FROM temporal.usuario
WHERE Nombre_usuario IS NOT NULL;


INSERT INTO bbdd.canciones (Id_disco, Titulo, Duracion)
SELECT 
    Id_disco,
    Titulo,
    TO_TIMESTAMP(SPLIT_PART(Duracion, ':', 1) || ':' || SPLIT_PART(Duracion, ':', 2), 'MI:SS') AS Duracion
FROM temporal.canciones
WHERE Titulo IS NOT NULL;


INSERT INTO bbdd.ediciones (Id_disco, Anno_edicion, Pais, Formato)
SELECT
    Id_disco,
    Anno_edicion,
    Pais,
    Formato
FROM temporal.ediciones
WHERE Formato IS NOT NULL AND Pais IS NOT NULL;


INSERT INTO bbdd.desea (Nombre_usuario, Titulo_disco, Anno_publicacion)
SELECT
    Nombre_usuario,
    Titulo_disco,
    Anno_publicacion
FROM temporal.desea
WHERE Nombre_usuario IS NOT NULL;


INSERT INTO bbdd.tiene (Nombre_usuario, Titulo_disco, Anno_publicacion, Anno_edicion, Pais_edicion, Formato_edicion, Estado)
SELECT
    Nombre_usuario,
    Titulo_disco,
    Anno_publicacion,
    Anno_edicion,
    Pais_edicion,
    Formato_edicion,
    Estado
FROM temporal.tiene
WHERE Nombre_usuario IS NOT NULL;


\echo 'Datos insertados al esquema final'


-- Eliminar esquema temporal
DROP SCHEMA IF EXISTS temporal CASCADE;


\echo 'Esquema temporal eliminado'






-- Consultas a realizar
\echo 'Realizando consultas solicitadas'


\echo 'Consulta 1: Mostrar los discos que tengan mas de 5 canciones.'


SELECT Id_disco, Titulo_disco, Anno_publicacion
FROM bbdd.canciones
GROUP BY Id_disco, Titulo_disco, Anno_publicacion
HAVING COUNT(Titulo) > 5;




\echo 'Consulta 2: Mostrar los vinilos que tiene el usuario Juan Garcia Gomez junto con el titulo del disco, y el pais y anno de edicion'

SELECT ediciones.Titulo_disco, ediciones.Anno_publicacion, ediciones.Pais, ediciones.Anno_edicion
FROM bbdd.tiene
JOIN bbdd.ediciones ON tiene.Formato_edicion = ediciones.Formato AND tiene.Anno_edicion = ediciones.Anno_edicion AND tiene.Pais_edicion = ediciones.Pais
JOIN bbdd.usuario ON tiene.Nombre_usuario = usuario.Nombre_usuario
WHERE usuario.Nombre = 'Juan Garcia Gomez';




\echo 'Consulta 3: discos con mayor duracion de la coleccion.'


SELECT Id_disco, Titulo_disco, Anno_publicacion, SUM(EXTRACT(EPOCH FROM Duracion)) AS Duracion_total
FROM bbdd.canciones
GROUP BY Id_disco, Titulo_disco, Anno_publicacion
ORDER BY Duracion_total DESC
LIMIT 1;




\echo 'Consulta 4: De los discos que tiene en su lista de deseos el usuario Juan Garcia Gomez,
indicar el nombre de los grupos musicales que los interpretan.'


SELECT DISTINCT grupos.Nombre
FROM bbdd.desea
JOIN bbdd.edita ON desea.Titulo_disco = edita.Titulo_disco AND desea.Anno_publicacion = edita.Anno_publicacion
JOIN bbdd.grupos ON edita.Nombre_grupo = grupos.Nombre
JOIN bbdd.usuario ON desea.Nombre_usuario = usuario.Nombre_usuario
WHERE usuario.Nombre = 'Juan Garcia Gomez';




\echo 'Consulta 5: Mostrar los discos publicados entre 1970 y 1972 junto con sus ediciones
ordenados por el anno de publicacion'


SELECT discos.Titulo, discos.Anno_publicacion, ediciones.Formato, ediciones.Anno_edicion, ediciones.Pais
FROM bbdd.discos
JOIN bbdd.ediciones ON discos.Titulo = ediciones.Titulo_disco AND discos.Anno_publicacion = ediciones.Anno_publicacion
WHERE discos.Anno_publicacion BETWEEN 1970 AND 1972
ORDER BY discos.Anno_publicacion;




\echo 'Consulta 6: Listar el nombre de todos los grupos que han publicado discos del genero
‘Electronic’.'


SELECT DISTINCT grupos.Nombre
FROM bbdd.discos
JOIN bbdd.edita ON discos.Titulo = edita.Titulo_disco AND discos.Anno_publicacion = edita.Anno_publicacion
JOIN bbdd.grupos ON edita.Nombre_grupo = grupos.Nombre
WHERE discos.Generos LIKE 'Electronic';




\echo 'Consulta 7: Lista de discos con la duracion total del mismo, editados antes del anno 2000'


SELECT discos.Titulo, discos.Anno_publicacion, SUM(EXTRACT(EPOCH FROM canciones.Duracion)) AS Duracion_total
FROM bbdd.discos
JOIN bbdd.canciones ON discos.Titulo = canciones.Titulo_disco AND discos.Anno_publicacion = canciones.Anno_publicacion
WHERE discos.Anno_publicacion < 2000
GROUP BY discos.Titulo, discos.Anno_publicacion;




\echo 'Consulta 8: Lista de ediciones de discos deseados por el usuario Lorena Saez Perez que tiene
el usuario Juan Garcia Gomez.'


SELECT desea.Titulo_disco, desea.Anno_publicacion, ediciones.Formato, ediciones.Anno_edicion, ediciones.Pais
FROM bbdd.desea
JOIN bbdd.tiene ON desea.Titulo_disco = tiene.Titulo_disco AND desea.Anno_publicacion = tiene.Anno_publicacion
JOIN bbdd.usuario AS UsuarioDesea ON desea.Nombre_usuario = UsuarioDesea.Nombre_usuario
JOIN bbdd.usuario AS UsuarioTiene ON tiene.Nombre_usuario = UsuarioTiene.Nombre_usuario
JOIN bbdd.ediciones ON desea.Titulo_disco = ediciones.Titulo_disco AND desea.Anno_publicacion = ediciones.Anno_publicacion
WHERE UsuarioDesea.Nombre = 'Lorena Saez Perez' AND UsuarioTiene.Nombre = 'Juan Garcia Gomez';




\echo 'Consulta 9: Lista todas las ediciones de los discos que tiene el usuario Gomez Garcia en un
estado NM o M.'


SELECT ediciones.Titulo_disco, ediciones.Anno_publicacion, ediciones.Formato, ediciones.Anno_edicion, ediciones.Pais
FROM bbdd.tiene
JOIN bbdd.ediciones ON tiene.Formato_edicion = ediciones.Formato AND tiene.Anno_edicion = ediciones.Anno_edicion AND tiene.Pais_edicion = ediciones.Pais
JOIN bbdd.usuario ON tiene.Nombre_usuario = usuario.Nombre_usuario
WHERE usuario.Nombre = 'Gomez Garcia' AND (ediciones.Estado = 'NM' OR ediciones.Estado = 'M');




\echo 'Consulta 10: Listar todos los usuarios junto al numero de ediciones que tiene de todos los discos
junto al anno de lanzamiento de su disco mas antiguo, el anno de lanzamiento de su
disco mas nuevo, y el anno medio de todos sus discos de su coleccion.'


SELECT usuario.Nombre, COUNT(ediciones.Titulo_disco) AS num_ediciones, MIN(discos.Anno_publicacion) AS anno_min, MAX(discos.Anno_publicacion) AS anno_max, AVG(discos.Anno_publicacion) AS anno_medio
FROM bbdd.tiene
JOIN bbdd.ediciones ON tiene.Formato_edicion = ediciones.Formato AND tiene.Anno_edicion = ediciones.Anno_edicion AND tiene.Pais_edicion = ediciones.Pais
JOIN bbdd.discos ON ediciones.Titulo_disco = discos.Titulo AND ediciones.Anno_publicacion = discos.Anno_publicacion
JOIN bbdd.usuario ON tiene.Nombre_usuario = usuario.Nombre_usuario
GROUP BY usuario.Nombre;




\echo 'Consulta 11: Listar el nombre de los grupos que tienen mas de 5 ediciones de sus discos en la
base de datos.'


SELECT grupos.Nombre
FROM bbdd.edita
JOIN bbdd.grupos ON edita.Nombre_grupo = grupos.Nombre
GROUP BY grupos.Nombre
HAVING COUNT(edita.Titulo_disco) > 5;




\echo 'Consulta 12: Lista el usuario que mas discos, contando todas sus ediciones tiene en la base de
datos.'


SELECT usuario.Nombre
FROM bbdd.tiene
JOIN bbdd.usuario ON tiene.Nombre_usuario = usuario.Nombre_usuario
GROUP BY usuario.Nombre
ORDER BY COUNT(tiene.Titulo_disco) DESC
LIMIT 1;




ROLLBACK;                       -- importante! permite correr el script multiples veces...