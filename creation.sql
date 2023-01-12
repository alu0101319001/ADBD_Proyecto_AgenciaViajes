---------------------------------------------------------------
-- BORRADO
---------------------------------------------------------------
DROP SCHEMA public CASCADE;
CREATE SCHEMA public;

DROP DATABASE IF EXISTS turismo;
CREATE DATABASE turismo;

\c turismo

DROP TABLE IF EXISTS oficina;
DROP TABLE IF EXISTS empleado;
DROP TABLE IF EXISTS cliente;
DROP TABLE IF EXISTS ubicacion;
DROP TABLE IF EXISTS telefono;
DROP TABLE IF EXISTS destino;
DROP TABLE IF EXISTS ofrece_destino;
DROP TABLE IF EXISTS alojamiento;
DROP TABLE IF EXISTS transporte;
DROP TABLE IF EXISTS actividad;
DROP TABLE IF EXISTS contrata;
DROP TABLE IF EXISTS tiene; 
DROP TABLE IF EXISTS ofrece_actividad;

---------------------------------------------------------------
-- CREACION DE RELACIONES
---------------------------------------------------------------
CREATE TABLE oficina (
  oficina_id INT GENERATED ALWAYS AS IDENTITY,
  oficina_nombre VARCHAR(50) NOT NULL UNIQUE,
  PRIMARY KEY(oficina_id)
);

CREATE TABLE empleado (
  empleado_id INT GENERATED ALWAYS AS IDENTITY,
  oficina_id INT NOT NULL REFERENCES oficina ON DELETE CASCADE,
  empleado_nombre VARCHAR(50) NOT NULL,
  empleado_apellidos VARCHAR(50) NOT NULL,
  empleado_fecha_nacimiento DATE NOT NULL CHECK (empleado_fecha_nacimiento > '1900-01-01'),
  empleado_direccion VARCHAR(50),
  PRIMARY KEY(empleado_id)
);

CREATE TABLE cliente (
  cliente_id INT GENERATED ALWAYS AS IDENTITY,
  empleado_id INT NOT NULL REFERENCES empleado ON DELETE CASCADE,
  cliente_nombre VARCHAR(50) NOT NULL,
  cliente_apellidos VARCHAR(50) NOT NULL,
  cliente_fecha_nacimiento DATE NOT NULL CHECK (cliente_fecha_nacimiento > '1900-01-01'),
  cliente_direccion VARCHAR(50),
  PRIMARY KEY(cliente_id)
);

CREATE TABLE ubicacion (
  oficina_id INT NOT NULL REFERENCES oficina ON DELETE CASCADE,
  municipio VARCHAR(50) NOT NULL,
  direccion VARCHAR(50) NOT NULL,
  latitud VARCHAR(50) NOT NULL,
  longitud VARCHAR(50) NOT NULL,
  PRIMARY KEY(oficina_id)
);

CREATE TABLE telefono (
  cliente_id INT NOT NULL REFERENCES cliente ON DELETE CASCADE,
  numero_telefono VARCHAR(9) NOT NULL UNIQUE,
  PRIMARY KEY(cliente_id, numero_telefono)
);

CREATE TABLE destino (
  destino_id INT GENERATED ALWAYS AS IDENTITY,
  municipio VARCHAR(50) NOT NULL UNIQUE,
  PRIMARY KEY(destino_id)
);

CREATE TABLE ofrece_destino (
  oficina_id INT NOT NULL REFERENCES oficina ON DELETE CASCADE,
  destino_id INT NOT NULL REFERENCES destino ON DELETE CASCADE,
  PRIMARY KEY(oficina_id, destino_id)
);

CREATE TABLE alojamiento (
  alojamiento_id INT GENERATED ALWAYS AS IDENTITY,
  alojamiento_nombre VARCHAR(50) NOT NULL,
  alojamiento_direccion VARCHAR(50) NOT NULL,
  alojamiento_municipio VARCHAR(50) NOT NULL,
  PRIMARY KEY(alojamiento_id)
);

CREATE TABLE transporte (
  transporte_id INT GENERATED ALWAYS AS IDENTITY,
  ciudad_origen VARCHAR(50) NOT NULL,
  ciudad_destino VARCHAR(50) NOT NULL,
  transporte_tipo VARCHAR(50) NOT NULL,
  PRIMARY KEY(transporte_id)
);

CREATE TABLE actividad (
  actividad_id INT GENERATED ALWAYS AS IDENTITY,
  actividad_tipo VARCHAR(50) NOT NULL,
  ocio_nombre VARCHAR(50),
  ocio_descripcion VARCHAR(100),
  deporte_nombre VARCHAR(50),
  deporte_descripcion VARCHAR(100),
  deporte_tipo VARCHAR(50),
  PRIMARY KEY(actividad_id),
  CONSTRAINT if_tipo_ocio_not_null
    CHECK (NOT (actividad_tipo = 'Ocio' AND ocio_nombre IS NULL)),
  CONSTRAINT if_tipo_deporte_not_null
    CHECK (NOT (actividad_tipo = 'Deporte' AND deporte_nombre IS NULL AND deporte_tipo IS NULL)),
  CONSTRAINT tipo_not_recognized
    CHECK (actividad_tipo = 'Ocio' OR actividad_tipo = 'Deporte')
);

CREATE TABLE contrata (
  cliente_id INT NOT NULL REFERENCES cliente ON DELETE CASCADE,
  destino_id INT NOT NULL REFERENCES destino ON DELETE CASCADE,
  fecha_contratacion TIMESTAMP without time zone DEFAULT now() NOT NULL,
  PRIMARY KEY(cliente_id, destino_id)
);

CREATE TABLE tiene (
  destino_id INT NOT NULL REFERENCES destino ON DELETE CASCADE,
  alojamiento_id INT NOT NULL REFERENCES alojamiento ON DELETE CASCADE,
  transporte_id INT NOT NULL REFERENCES transporte ON DELETE CASCADE,
  PRIMARY KEY(destino_id, alojamiento_id, transporte_id)
);

CREATE TABLE ofrece_actividad (
  alojamiento_id INT NOT NULL REFERENCES alojamiento ON DELETE CASCADE,
  actividad_id INT NOT NULL REFERENCES actividad ON DELETE CASCADE,
  PRIMARY KEY(alojamiento_id, actividad_id)
);

---------------------------------------------------------------
-- FUNCIONES
---------------------------------------------------------------
CREATE FUNCTION public.fecha_contratacion() RETURNS TRIGGER
  LANGUAGE plpgsql
  AS $$
BEGIN
  NEW.fecha_contratacion = CURRENT_TIMESTAMP;
  RETURN NEW;
END $$;

---------------------------------------------------------------
-- DISPARADORES
---------------------------------------------------------------
CREATE TRIGGER fecha_contratacion_trigger 
AFTER INSERT OR UPDATE ON public.contrata
FOR EACH ROW
EXECUTE FUNCTION public.fecha_contratacion();


---------------------------------------------------------------
-- CARGA DE DATOS DE EJEMPLO
---------------------------------------------------------------
INSERT INTO oficina(oficina_nombre)
VALUES
  ('Turismo Santiago del Teide'),
  ('Guias Puerto de la Cruz'),
  ('Rutas Anaga'),
  ('Oficina de Turismo Santa Cruz'),
  ('Guia Punta del Hidalgo');

INSERT INTO empleado(oficina_id, empleado_nombre, empleado_apellidos, empleado_fecha_nacimiento, empleado_direccion)
VALUES
  (1, 'Juan', 'Pérez', '1989-10-04', 'Calle El Hoyo N8'),
  (1, 'Antonio', 'Perez', '1992-04-23', 'Avenida Santiago N23'),
  (2, 'Manolo', 'Rodriguez', '1975-09-23', 'Avenida Maritima N45 B'),
  (2, 'María', 'González', '1998-04-27', 'Calle Sotomayor N3 C'),
  (3, 'Avelino', 'Gutierrez', '1965-12-04', null),
  (4, 'Magdalena', 'Santos', '1972-02-06', 'Avenida Anaga N6'),
  (4, 'Laura', 'González', '2001-02-06', 'Calle Los Limoneros N2'),
  (4, 'Clara', 'Martel', '2000-05-12', 'Calle Camino de la Iglesia N21'),
  (4, 'Adahi', 'Oval', '2000-11-26', 'Calle General Afonso N1'),
  --(6, 'Error', 'Error', '2000-01-01', 'Error'),
  --(5, 'Error', 'Error', '1899-01-01', 'ERROR'),
  (5, 'Fernando', 'Díaz', '1987-02-22', 'Avenida La Barriada N34');

INSERT INTO cliente(empleado_id, cliente_nombre, cliente_apellidos, cliente_fecha_nacimiento, cliente_direccion)
VALUES
  (1, 'Susana', 'Perez', '1942-08-24', 'Avenida Santiago N12'),
  (2, 'Laura', 'Salamanca', '2001-11-07', 'Avenida Santiago N52'),
  (4, 'Esteban', 'Mayor', '1982-06-03', 'Calle El Puertito N3'),
  (4, 'Susana', 'Exposito', '1954-12-24', 'Calle El Marinero'),
  (5, 'Javier', 'Perez', '1996-04-07', 'Calle Alemania N112'),
  (6, 'Alvaro', 'Martin', '2003-07-13', 'Calle Juan Carlos II N2'),
  (7, 'Abimael', 'Casado', '2001-03-02', 'Calle Las Rosas N21'),
  (7, 'Alejandra', 'Spiretto', '1992-01-01', 'Calle Alejandría'),
  (9, 'Daniel', 'Dolores', '1999-08-04', 'Calle María Magdalena N43'),
  --(11, 'Error', 'Error', '2000-01-01', 'Error'),
  --(5, 'Error', 'Error', '1899-01-01', 'ERROR'),
  (10, 'Delfina', 'González', '1962-09-18', 'Avenida Arguayo N7');

INSERT INTO ubicacion(oficina_id, municipio, direccion, latitud, longitud)
VALUES
  (1, 'Santiago del Teide', 'Avenida Santiago N59', '28.29723', '-16.81591'),
  (2, 'Puerto de la Cruz', 'Avenida Blas Pérez González N7', '28.41055', '-16.55281'),
  (3, 'Santa Cruz de Tenerife', 'Barrio Cruz Carmen N2', '28.53075', '-16.28027'),
  (4, 'Santa Cruz de Tenerife', 'Plaza de España SN', '28.46718', '-16.24779'),
  --(6, 'Error', 'Error', 'Error', 'Error'),
  (5, 'La Laguna', 'Camino Los Corrales N7', '28.56961', '-16.32874');

INSERT INTO telefono(cliente_id, numero_telefono)
VALUES
  (1, '922723451'),
  (2, '922309212'),
  (2, '623158290'),
  (3, '679202189'),
  (4, '922678392'),
  (5, '628617281'),
  (5, '922566783'),
  (6, '638291823'),
  (7, '670293821'),
  (8, '922789192'),
  (8, '683920123'),
  (9, '671029831'),
  --(11, 'Error'),
  (10, '922567290');

INSERT INTO destino(municipio)
VALUES
  ('La Laguna'),
  ('Santa Cruz de Tenerife'),
  ('Santiago del Teide'),
  ('Puerto de la Cruz'),
  ('Adeje'),
  ('Tegueste'),
  ('Los Realejos'),
  ('Tacoronte'),
  ('El Sauzal'),
  ('La Orotava'),
  ('Arico'),
  ('Granadilla de Abona'),
  ('Guia de Isora'),
  ('Icod de los Vinos');

INSERT INTO ofrece_destino(oficina_id, destino_id)
VALUES
  (1, 1),
  (1, 2),
  (1, 6),
  (2, 1),
  (2, 2),
  (2, 6),
  (2, 7),
  (2, 3),
  (3, 1),
  (4, 1),
  (4, 2),
  (4, 3),
  (4, 4),
  (4, 5),
  (4, 6),
  (5, 1),
  --Error(6, 1),
  --Error (5, 10),
  (5, 7);

INSERT INTO alojamiento(alojamiento_nombre, alojamiento_direccion, alojamiento_municipio)
VALUES
  ('Panoramica Garden', 'La Longuera SN', 'Los Realejos'),
  ('Hotel Boutique San Diego', 'Avenida San Diego N40', 'La Laguna'),
  ('Hotel Casa del Sol', 'Calle Finlandia N4', 'Puerto de la Cruz'),
  ('Puerto Nest Hotel', 'Calle Victor Machado N12', 'Puerto de la Cruz'),
  ('Los Olivos Beach Resort', 'Calle París N1', 'Adeje'),
  ('Duque Nest Hotel', 'Avenida Jardines del Duque N33', 'Adeje'),
  ('Palm Beach Tenerife', 'Avenida V Centenario N11', 'Adeje'),
  ('Hotel Riu Buenavista', 'Calle El Horno N35', 'Adeje'),
  ('The Ritz', 'Calle Maria Zambrano N2', 'Guia de Isora'),
  ('Hotel Rural El Navio', 'Prolongacion Avenida Los Pescadores SN', 'Guia de Isora'),
  ('Hotel La Casona del Patio', 'Avenida de la Iglesia N68', 'Santiago del Teide'),
  ('Casa Weyler', 'Calle Sabino Berthelot N2-6', 'Santa Cruz de Tenerife'),
  ('Atlantis Park Resort', 'Calle Oceano Artico N1', 'La Laguna'),
  ('Albergue Montes de Anaga', 'Carretera General Chamorga', 'Santa Cruz de Tenerife'),
  ('Lotus Yurt', 'Camino los Alamos n8', 'Tegueste'),
  ('Hotel Emblematico Casa Casilda', 'Calle del Calvario N53', 'Tacoronte'),
  ('Bodegas Linaje del Pago', 'Calle Herrera N85', 'El Sauzal'),
  ('Parador de Cañadas del Teide', 'Las Cañadas del Tiede', 'La Orotava'),
  ('Ecohotel El Agua', 'Calle Veinticinco de Julio N4', 'Arico'),
  ('Hotel Rural Senderos de Abona', 'Calle de la Iglesia N5', 'Granadilla'),
  ('Apartamentos Estrella del Norte', 'Calle El Amparo', 'Icod de los Vinos');

INSERT INTO transporte(ciudad_origen, ciudad_destino, transporte_tipo)
VALUES
  ('Santiago del Teide', 'Puerto de la Cruz', 'Bus'),
  ('Santa Cruz de Tenerife', 'La Laguna', 'Tranvia'),
  ('Anaga', 'La Laguna', 'Bus'),
  ('Puerto de la Cruz', 'Punta del Hidalgo', 'Taxi'),
  ('Punta del Hidalgo', 'La Laguna', 'Bus'),
  ('Santiago del Teide', 'Anaga', 'Taxi'),
  ('La Laguna', 'Santa Cruz de Tenerife', 'Tranvia'),
  ('Puerto de la Cruz', 'Icod de los Vinos', 'Bus'),
  ('Puerto de la Cruz', 'Icod de los Vinos', 'Taxi'),
  ('Santa Cruz de Tenerife', 'Santiago del Teide', 'Alquiler de coche'),
  ('Santa Cruz de Tenerife', 'Costa Adeje', 'Bus'),
  ('Puerto de la Cruz', 'Costa Adeje', 'Taxi'),
  ('La Laguna', 'El Socorro', 'Bus'),
  ('Puerto de la Cruz', 'Los Realejos', 'Taxi'),
  ('La Laguna', 'Tacoronte', 'Bus'),
  ('Puerto de la Cruz', 'El Sauzal', 'Bus'),
  ('La Laguna', 'El Sauzal', 'Taxi'),
  ('Costa Adeje', 'El Sauzal', 'Alquiler de coche'),
  ('Santa Cruz de Tenerife', 'Las Cañadas del Teide', 'Alquiler de coche'),
  ('Santiago del Teide', 'Las Cañadas del Teide', 'Bus Privado'),
  ('Costa Adeje', 'Arico Viejo', 'Bus'),
  ('Costa Adeje', 'Granadilla', 'Taxi'),
  ('Santiago del Teide', 'Alcala', 'Bus'),
  ('Santiago del Teide', 'Icod de los Vinos', 'Bus'),
  ('Puerto de la Cruz', 'Icod de los Vinos', 'Taxi');

INSERT INTO actividad(actividad_tipo, ocio_nombre, ocio_descripcion, deporte_nombre, deporte_descripcion, deporte_tipo)
VALUES
  ('Ocio', 'Concierto Bossa Nova', 'Musica en vivo del género brasileño',null, null, null),
  ('Deporte', null, null, 'Explorando Anaga', 'Senderismos por las rutas menos conocidas de Anaga', 'Senderismo'),
  --('Ocio', null, null, null, null, null),
  --('Deporte', null, null, null, null, null),
  --('Error', null, null, null, null, null),
  ('Ocio', 'Fiesta de Carnaval en Acantilado de los Gigantes', 'Carnaval Santiago del Teide', null, null, null),
  ('Ocio', 'Romería de Tigaiga', 'Festividad local típica canaria', null, null, null),
  ('Deporte', null, null, 'XXXIX San Silvestre Lagunera', 'Prueba atlética', 'Carrera'),
  ('Ocio', 'Fardo', 'Actuación de Teatro', null, null, null),
  ('Ocio', 'Loro Parque', 'Parque Zoológico', null, null, null),
  ('Ocio', 'Complejo Costa Martinez', 'Complejo municipal con un lago artificial', null, null, null),
  ('Ocio', 'Shakespeare: Der Sturm', 'Obra de teatro alemana', null, null, null),
  ('Deporte', null, null, 'Ademi Tenerife Asociacion Deportiva', 'Centro de deporte para personas con discapacidad', 'Centro de Deporte'),
  ('Deporte', null, null, 'Club Apnea Sur', 'Escuela Municipal Formacon Acuatica Integral de Adeje', 'Actividades Acuaticas'),
  ('Deporte', null, null, 'CD Escuderia de Adeje Barranco del Infierno', 'Escuderia automovilistica', 'Automovilismo'),
  ('Ocio', 'Antigona', 'Obra de teatro', null, null, null),
  ('Deporte', null, null, 'Campeonato de surf', 'Circuito Canario de Surf en Punta Blanca', 'Actividades Acuaticas');

INSERT INTO contrata(cliente_id, destino_id)
VALUES
  (1, 13),
  (2, 2),
  (3, 6),
  (4, 9),
  (5, 3),
  (6, 11),
  (7, 1),
  (8, 5),
  (9, 7),
  (10, 14),
  (8, 12),
  (9, 11),
  (7, 9);

INSERT INTO tiene(destino_id, alojamiento_id, transporte_id)
VALUES
  (1, 2, 2),
  (1, 2, 5),
  (2, 12, 7),
  (3, 11, 10),
  (4, 3, 1),
  (5, 5, 11),
  (5, 6, 11),
  (5, 7, 11),
  (5, 8, 11),
  (5, 8, 12),
  (6, 15, 13),
  (7, 1, 14),
  (8, 16, 15),
  (9, 17, 16),
  (9, 17, 17),
  (9, 17, 18),
  (10, 18, 19),
  (10, 18, 20),
  (11, 19, 21),
  (12, 20, 22),
  (13, 9, 23),
  (13, 10, 23),
  (14, 21, 24),
  (14, 21, 25);

INSERT INTO ofrece_actividad(alojamiento_id, actividad_id)
VALUES
  (8, 1),
  (13, 2),
  (1, 4),
  (2, 5),
  (13, 6),
  (3, 7),
  (3, 8),
  (4, 8),
  (5, 9),
  (6, 10),
  (7, 11),
  (8, 12),
  (9, 13),
  (10, 14),
  (12, 1),
  (14, 2);

---------------------------------------------------------------
-- CONSULTAS BÁSICAS
---------------------------------------------------------------
SELECT * FROM oficina;
SELECT * FROM ubicacion;
SELECT * FROM empleado;
SELECT * FROM cliente;
SELECT * FROM telefono;
SELECT * FROM destino;
SELECT * FROM ofrece_destino;
SELECT * FROM contrata;
SELECT * FROM alojamiento;
SELECT * FROM transporte;
SELECT * FROM tiene;
SELECT * FROM actividad;
SELECT * FROM ofrece_actividad;


