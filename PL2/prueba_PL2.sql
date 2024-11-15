\pset pager off


SET client_encoding = 'UTF8';


BEGIN;


\echo 'Creando esquema temporal'


CREATE SCHEMA IF NOT EXISTS temporal;


-- Crear tablas temporales en el esquema
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


CREATE TABLE IF NOT EXISTS temporal.grupos(
    Id_grupo TEXT,
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
    Nombre_discos TEXT,
    Anno_publicacion TEXT
);


CREATE TABLE IF NOT EXISTS temporal.tiene(
    Nombre_usuario TEXT,
    Nombre_discos TEXT,
    Anno_publicacion TEXT,
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

-- Tabla Grupo
CREATE TABLE bbdd.grupos (
    Nombre VARCHAR(200) NOT NULL,
    Url_grupo TEXT,
    PRIMARY KEY (Nombre, Url_grupo)
);



-- Tabla Discos
CREATE TABLE bbdd.discos (
    Id_disco INT NOT NULL,
    Nombre VARCHAR(200) NOT NULL,
    Anno_publicacion INT NOT NULL,
    Nombre_grupo VARCHAR(200) NOT NULL,
    Url_grupo TEXT,
    Generos VARCHAR(200),
    Url_portada TEXT,
    UNIQUE (Id_disco),
    PRIMARY KEY (Id_disco, Nombre, Anno_publicacion),
    FOREIGN KEY (Nombre_grupo, Url_grupo) REFERENCES bbdd.grupos(Nombre, Url_grupo)
);


-- Tabla Usuario
CREATE TABLE bbdd.usuario (
    Nombre VARCHAR(200),
    Nombre_usuario VARCHAR(200) NOT NULL,
    Email VARCHAR(200),
    Contrasena VARCHAR(200),
    PRIMARY KEY (Nombre_usuario)
);


-- Tabla Canciones
CREATE TABLE bbdd.canciones (
    Id_disco INT,
    Titulo VARCHAR(200) NOT NULL,
    Duracion TIME,
    PRIMARY KEY (Id_disco, Titulo),
    FOREIGN KEY (Id_disco) REFERENCES bbdd.discos(Id_disco)
);


-- Tabla Ediciones
CREATE TABLE bbdd.ediciones (
    Id_disco INT,
    Anno_edicion INT,
    Pais VARCHAR(200),
    Formato VARCHAR(200),
    PRIMARY KEY (Id_disco, Anno_edicion, Pais, Formato)
);


-- Tabla Tiene (relacion Usuario - Ediciones)
CREATE TABLE bbdd.tiene (
    Nombre_usuario VARCHAR(255),
    Id_disco INT,
    Anno_edicion INT,
    Pais VARCHAR(200),
    Formato VARCHAR(200),
    Estado VARCHAR(10),
    PRIMARY KEY (Nombre_usuario, Id_disco, Anno_edicion, Pais, Formato),
    FOREIGN KEY (Id_disco) REFERENCES bbdd.discos(Id_disco),
    FOREIGN KEY (Id_disco, Anno_edicion, Pais, Formato) REFERENCES bbdd.ediciones(Id_disco, Anno_edicion, Pais, Formato)
);



-- Tabla Desea (relacion Usuario - Ediciones)
CREATE TABLE bbdd.desea (
    Nombre_usuario VARCHAR(255) NOT NULL,
    Nombre_discos VARCHAR(200) NOT NULL,
    Anno_publicacion INT NOT NULL,
    PRIMARY KEY (Nombre_usuario, Nombre_discos, Anno_publicacion),
    FOREIGN KEY (Nombre_discos, Anno_publicacion) REFERENCES bbdd.discos(Nombre, Anno_publicacion)
);





\echo 'Esquema final creado con exito'






-- Insertacion de datos del esquema temporal al esquema final
\echo 'Insertando datos en el esquema final'


INSERT INTO bbdd.discos (Id_disco, Nombre, Anno_publicacion, Nombre_grupo, Url_grupo, Generos, Url_portada)
SELECT DISTINCT
    Id_disco::INT,
    Nombre,
    Anno_publicacion::INT,
    Nombre_grupo,
    Url_grupo,
    Generos,
    Url_portada
FROM temporal.discos
ON CONFLICT (Id_disco) DO NOTHING;

\echo 'Datos insertados al esquema final'





-- Consultas a realizar
\echo 'Realizando consultas solicitadas'


\echo 'Consulta 1: Mostrar los discos que tengan mas de 5 canciones.'


SELECT Id_disco, Nombre_discos, Anno_publicacion
FROM bbdd.canciones
GROUP BY Id_disco, Nombre_discos, Anno_publicacion
HAVING COUNT(Nombre) > 5;

ROLLBACK;                     -- importante! permite correr el script multiples veces...