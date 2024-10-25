\pset pager off

SET client_encoding = 'UTF8';

BEGIN;
\echo 'creando el esquema para la BBDD de discos'


\echo 'creando un esquema temporal'

-- Tabla Disco
CREATE TABLE Disco_temp (
    Titulo VARCHAR(100) NOT NULL,
    Año_publicacion INT,
    Géneros VARCHAR(100),
    Url_portada TEXT,
    PRIMARY KEY (Titulo, Año_publicacion)
);

-- Tabla Grupo
CREATE TABLE Grupo_temp (
    Nombre VARCHAR(100) NOT NULL,
    Url_grupo TEXT,
    PRIMARY KEY (Nombre)
);

-- Tabla Usuario
CREATE TABLE Usuario_temp (
    Nombre_usuario VARCHAR(100) NOT NULL,
    Nombre VARCHAR(100),
    Email VARCHAR(100),
    Contraseña VARCHAR(100),
    PRIMARY KEY (Nombre_usuario)
);

-- Tabla Canciones
CREATE TABLE Canciones_temp (
    Titulo VARCHAR(100) NOT NULL,
    Duracion INTERVAL,
    Titulo_disco VARCHAR(100),
    Año_disco INT,
    PRIMARY KEY (Titulo),
    FOREIGN KEY (Titulo_disco, Año_disco) REFERENCES Disco(Titulo, Año_publicacion)
);

-- Tabla Ediciones
CREATE TABLE Ediciones_temp (
    Formato VARCHAR(100),
    Año_edicion INT,
    Pais VARCHAR(100),
    Titulo_disco VARCHAR(100),
    Año_disco INT,
    PRIMARY KEY (Formato, Año_edicion, Pais),
    FOREIGN KEY (Titulo_disco, Año_disco) REFERENCES Disco(Titulo, Año_publicacion)
);

-- Tabla Edita (relación Disco - Grupo)
CREATE TABLE Edita_temp (
    Nombre_grupo VARCHAR(100),
    Titulo_disco VARCHAR(100),
    Año_disco INT,
    PRIMARY KEY (Nombre_grupo, Titulo_disco, Año_disco),
    FOREIGN KEY (Nombre_grupo) REFERENCES Grupo(Nombre),
    FOREIGN KEY (Titulo_disco, Año_disco) REFERENCES Disco(Titulo, Año_publicacion)
);

-- Tabla Tiene (relación Usuario - Ediciones)
CREATE TABLE Tiene_temp (
    Nombre_usuario VARCHAR(255),
    Formato_edicion VARCHAR(100),
    Año_edicion INT,
    Pais_edicion VARCHAR(100),
    PRIMARY KEY (Nombre_usuario, Formato_edicion, Año_edicion, Pais),
    FOREIGN KEY (Nombre_usuario) REFERENCES Usuario(Nombre_usuario),
    FOREIGN KEY (Formato_edicion, Año_edicion, Pais_edicion) REFERENCES Ediciones(Formato, Año_edicion, Pais)
);

-- Tabla Desea (relación Usuario - Ediciones)
CREATE TABLE Desea_temp (
    Nombre_usuario VARCHAR(255),
    Titulo_disco VARCHAR(100),
    Año_disco INT,
    PRIMARY KEY (Nombre_usuario, Titulo_disco, Año_disco),
    FOREIGN KEY (Nombre_usuario) REFERENCES Usuario(Nombre_usuario),
    FOREIGN KEY (Titulo_disco, Año_disco) REFERENCES Disco(Titulo, Año_publicacion)
);

\echo 'Esquema temporal creado con éxito'

SET search_path='nombre del esquema o esquemas utilizados';

-- Cargando los datos a las tablas
\copy Disco_temp(Titulo, Año_publicacion, Géneros, Url_portada) FROM 'discos.csv' WITH CSV HEADER;

\copy Usuario_temp(Nombre_usuario, Nombre, Email, Contraseña) FROM 'usuarios.csv' WITH CSV HEADER;

\copy Canciones_temp(Titulo, Duracion, Titulo_disco, Año_disco) FROM 'canciones.csv' WITH CSV HEADER;

\copy Ediciones_temp(Formato, Año_edicion, Pais, Titulo_disco, Año_disco) FROM 'ediciones.csv' WITH CSV HEADER;

\copy Desea_temp(Nombre_usuario, Titulo_disco, Año_disco) FROM 'usuario_desea_disco.csv' WITH CSV HEADER;

\copy Tiene_temp(Nombre_usuario, Formato_edicion, Año_edicion, Pais_edicion) FROM 'usuario_tiene_edicion.csv' WITH CSV HEADER;


\echo 'Cargando datos'


\echo insertando datos en el esquema final

INSERT INTO Disco (Titulo, Año_publicacion, Géneros, Url_portada)
SELECT Titulo, Año_publicacion, Géneros, Url_portada
FROM Disco_temp
WHERE Titulo IS NOT NULL;

INSERT INTO Grupo (Nombre, Url_grupo)
SELECT Nombre, Url_grupo
FROM Grupo_temp
WHERE Nombre IS NOT NULL;

INSERT INTO Usuario (Nombre_usuario, Nombre, Email, Contraseña)
SELECT Nombre_usuario, Nombre, Email, Contraseña
FROM Usuario_temp
WHERE Nombre_usuario IS NOT NULL;

INSERT INTO Canciones (Titulo, Duracion, Titulo_disco, Año_disco)
SELECT Titulo, Duracion, Titulo_disco, Año_disco
FROM Canciones_temp
WHERE Titulo IS NOT NULL;

INSERT INTO Ediciones (Formato, Año_edicion, Pais, Titulo_disco, Año_disco)
SELECT Formato, Año_edicion, Pais, Titulo_disco, Año_disco
FROM Ediciones_temp
WHERE Formato IS NOT NULL AND Pais IS NOT NULL;

INSERT INTO Desea (Nombre_usuario, Titulo_disco, Año_disco)
SELECT Nombre_usuario, Titulo_disco, Año_disco
FROM Desea_temp
WHERE Nombre_usuario IS NOT NULL;

INSERT INTO Tiene (Nombre_usuario, Formato_edicion, Año_edicion, Pais_edicion)
SELECT Nombre_usuario, Formato_edicion, Año_edicion, Pais_edicion
FROM Tiene_temp
WHERE Nombre_usuario IS NOT NULL;

\echo Consulta 1: texto de la consulta

\echo Consulta n:


ROLLBACK;                       -- importante! permite correr el script multiples veces...p