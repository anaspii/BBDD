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
    Titulo_disco VARCHAR(100),
    Año_disco INT,
    Formato_edicion VARCHAR(100),
    Año_edicion INT,
    Pais_edicion VARCHAR(100),
    PRIMARY KEY (Nombre_usuario, Formato_edicion, Año_edicion, Pais),
    FOREIGN KEY (Nombre_usuario) REFERENCES Usuario(Nombre_usuario),
    FOREIGN KEY (Titulo_disco, Año_disco) REFERENCES Disco(Titulo, Año_publicacion),
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

\copy Tiene_temp(Nombre_usuario, Titulo_disco, Año_disco, Formato_edicion, Año_edicion, Pais_edicion) FROM 'usuario_tiene_edicion.csv' WITH CSV HEADER;


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
SELECT 
    Titulo,
    TO_TIMESTAMP(SPLIT_PART(Duracion, ':', 1) || ':' || SPLIT_PART(Duracion, ':', 2), 'MI:SS') - TIMESTAMP '1970-01-01 00:00:00' AS Duracion,
    Titulo_disco,
    Año_disco
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

INSERT INTO Tiene (Nombre_usuario, Titulo_disco, Año_disco, Formato_edicion, Año_edicion, Pais_edicion)
SELECT Nombre_usuario, Titulo_disco, Año_disco, Formato_edicion, Año_edicion, Pais_edicion
FROM Tiene_temp
WHERE Nombre_usuario IS NOT NULL;

\echo Consulta 1: 'Mostrar los discos que tengan más de 5 canciones.'

SELECT Titulo_disco, Año_disco
FROM Canciones_temp
GROUP BY Titulo_disco, Año_disco
HAVING COUNT(Titulo) > 5;


\echo Consulta 2: 'Mostrar los vinilos que tiene el usuario Juan García Gómez junto con el título del
disco, y el país y año de edición'

SELECT Ediciones.Titulo_disco, Ediciones.Año_disco, Ediciones.Pais, Ediciones.Año_edicion
FROM Tiene
JOIN Ediciones ON Tiene.Formato_edicion = Ediciones.Formato AND Tiene.Año_edicion = Ediciones.Año_edicion AND Tiene.Pais_edicion = Ediciones.Pais
JOIN Usuario ON Tiene.Nombre_usuario = Usuario.Nombre_usuario
WHERE Usuario.Nombre = 'Juan García Gómez';


\echo Consulta 3: 'Disco con mayor duración de la colección.'

SELECT Titulo_disco, Año_disco, SUM(EXTRACT(EPOCH FROM Duracion)) AS Duracion_total
FROM Canciones
GROUP BY Titulo_disco, Año_disco
ORDER BY Duracion_total DESC
LIMIT 1;


\echo Consulta 4: 'De los discos que tiene en su lista de deseos el usuario Juan García Gómez,
indicar el nombre de los grupos musicales que los interpretan.'

SELECT DISTINCT Grupo.Nombre
FROM Desea
JOIN Edita ON Desea.Titulo_disco = Edita.Titulo_disco AND Desea.Año_disco = Edita.Año_disco
JOIN Grupo ON Edita.Nombre_grupo = Grupo.Nombre
JOIN Usuario ON Desea.Nombre_usuario = Usuario.Nombre_usuario
WHERE Usuario.Nombre = 'Juan García Gómez';


\echo Consulta 5: 'Mostrar los discos publicados entre 1970 y 1972 junto con sus ediciones
ordenados por el año de publicación'

SELECT Disco.Titulo, Disco.Año_publicacion, Ediciones.Formato, Ediciones.Año_edicion, Ediciones.Pais
FROM Disco
JOIN Ediciones ON Disco.Titulo = Ediciones.Titulo_disco AND Disco.Año_publicacion = Ediciones.Año_disco
WHERE Disco.Año_publicacion BETWEEN 1970 AND 1972
ORDER BY Disco.Año_publicacion;


\echo Consulta 6: 'Listar el nombre de todos los grupos que han publicado discos del género
‘Electronic’.'

SELECT DISTINCT Grupo.Nombre
FROM Disco
JOIN Edita ON Disco.Titulo = Edita.Titulo_disco AND Disco.Año_publicacion = Edita.Año_disco
JOIN Grupo ON Edita.Nombre_grupo = Grupo.Nombre
WHERE Disco.Géneros LIKE 'Electronic';


\echo Consulta 7: 'Lista de discos con la duración total del mismo, editados antes del año 2000'

SELECT Disco.Titulo, Disco.Año_publicacion, SUM(EXTRACT(EPOCH FROM Canciones.Duracion)) AS Duracion_total
FROM Disco
JOIN Canciones ON Disco.Titulo = Canciones.Titulo_disco AND Disco.Año_publicacion = Canciones.Año_disco
WHERE Disco.Año_publicacion < 2000
GROUP BY Disco.Titulo, Disco.Año_publicacion;


\echo Consulta 8: 'Lista de ediciones de discos deseados por el usuario Lorena Sáez Pérez que tiene
el usuario Juan García Gómez.'

SELECT Desea.Titulo_disco, Desea.Año_disco, Ediciones.Formato, Ediciones.Año_edicion, Ediciones.Pais
FROM Desea
JOIN Tiene ON Desea.Titulo_disco = Tiene.Titulo_disco AND Desea.Año_disco = Tiene.Año_disco
JOIN Usuario AS UsuarioDesea ON Desea.Nombre_usuario = UsuarioDesea.Nombre_usuario
JOIN Usuario AS UsuarioTiene ON Tiene.Nombre_usuario = UsuarioTiene.Nombre_usuario
JOIN Ediciones ON Desea.Titulo_disco = Ediciones.Titulo_disco AND Desea.Año_disco = Ediciones.Año_disco
WHERE UsuarioDesea.Nombre = 'Lorena Sáez Pérez' AND UsuarioTiene.Nombre = 'Juan García Gómez';


\echo Consulta 9: 'Lista todas las ediciones de los discos que tiene el usuario Gómez García en un
estado NM o M.'

SELECT Ediciones.Titulo_disco, Ediciones.Año_disco, Ediciones.Formato, Ediciones.Año_edicion, Ediciones.Pais
FROM Tiene
JOIN Ediciones ON Tiene.Formato_edicion = Ediciones.Formato AND Tiene.Año_edicion = Ediciones.Año_edicion AND Tiene.Pais_edicion = Ediciones.Pais
JOIN Usuario ON Tiene.Nombre_usuario = Usuario.Nombre_usuario
WHERE Usuario.Nombre = 'Gómez García' AND (Ediciones.Estado = 'NM' OR Ediciones.Estado = 'M');


\echo Consulta 10: 'Listar todos los usuarios junto al número de ediciones que tiene de todos los discos
junto al año de lanzamiento de su disco más antiguo, el año de lanzamiento de su
disco más nuevo, y el año medio de todos sus discos de su colección.'

SELECT Usuario.Nombre, COUNT(Ediciones.Titulo_disco) AS num_ediciones, MIN(Disco.Año_publicacion) AS año_min, MAX(Disco.Año_publicacion) AS año_max, AVG(Disco.Año_publicacion) AS año_medio
FROM Tiene
JOIN Ediciones ON Tiene.Formato_edicion = Ediciones.Formato AND Tiene.Año_edicion = Ediciones.Año_edicion AND Tiene.Pais_edicion = Ediciones.Pais
JOIN Disco ON Ediciones.Titulo_disco = Disco.Titulo AND Ediciones.Año_disco = Disco.Año_publicacion
JOIN Usuario ON Tiene.Nombre_usuario = Usuario.Nombre_usuario
GROUP BY Usuario.Nombre;


\echo Consulta 11: 'Listar el nombre de los grupos que tienen más de 5 ediciones de sus discos en la
base de datos.'

SELECT Grupo.Nombre
FROM Edita
JOIN Grupo ON Edita.Nombre_grupo = Grupo.Nombre
GROUP BY Grupo.Nombre
HAVING COUNT(Edita.Titulo_disco) > 5;


\echo Consulta 12: '. Lista el usuario que más discos, contando todas sus ediciones tiene en la base de
datos.'

SELECT Usuario.Nombre
FROM Tiene
JOIN Usuario ON Tiene.Nombre_usuario = Usuario.Nombre_usuario
GROUP BY Usuario.Nombre
ORDER BY COUNT(Tiene.Titulo_disco) DESC
LIMIT 1;


ROLLBACK;                       -- importante! permite correr el script multiples veces...p