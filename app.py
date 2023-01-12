import os
import psycopg2
from flask import Flask, render_template, request, url_for, redirect
from psycopg2 import sql

SELECT_OFICINA_ID = """SELECT * FROM oficina WHERE oficina_id = (%s);"""
INSERT_OFICINA_RETURN_ID = """INSERT INTO public.oficina (oficina_nombre) VALUES (%s) RETURNING oficina_id;"""
INSERT_CLIENTE_RETURN_ID = """INSERT INTO cliente (empleado_id, cliente_nombre, cliente_apellidos, cliente_fecha_nacimiento, cliente_direccion) VALUES (%s, %s, %s, %s, %s) RETURNING cliente_id;"""
INSERT_UBICACION = ("INSERT INTO ubicacion (oficina_id, municipio, direccion, latitud, longitud) VALUES (%s,%s,%s,%s,%s);")
INSERT_EMPLEADO = ("INSERT INTO empleado (oficina_id, empleado_nombre, empleado_apellidos, empleado_fecha_nacimiento, empleado_direccion) VALUES (%s,%s,%s,%s,%s) RETURNING empleado_id;")
INSERT_DESTINO = ("INSERT INTO destino (municipio) VALUES (%s) RETURNING destino_id")
INSERT_TRANSPORTE = ("INSERT INTO transporte (ciudad_origen, ciudad_destino, transporte_tipo) VALUES (%s,%s,%s) RETURNING transporte_id")
INSERT_ALOJAMIENTO = ("INSERT INTO alojamiento (direccion, nombre, municipio) VALUES (%s,%s,%s) RETURNING alojamiento_id")
INSERT_ACTIVIDAD = ("INSERT INTO actividad (actividad_tipo, ocio_nombre, ocio_descripcion, deporte_nombre, deporte_descripcion, deporte_tipo) VALUES (%s,%s,%s,%s,%s,%s) RETURNING actividad_id")
INSERT_CONTRATA = """INSERT INTO contrata (cliente_id, destino_id) VALUES (%s,%s) RETURNING fecha_contratacion"""

UPDATE_OFICINA = ("UPDATE oficina SET oficina_nombre = %s WHERE oficina_id = %s")
UPDATE_EMPLEADO = """UPDATE empleado SET oficina_id = %s, empleado_nombre = %s, empleado_apellidos = %s, empleado_fecha_nacimiento = %s, empleado_direccion = %s WHERE empleado_id = %s;"""
UPDATE_UBICACION = ("UPDATE ubicacion SET oficina_id = %s, municipio = %s, direccion = %s, latitud = %s, longitud = %s WHERE oficina_id = %s")
UPDATE_CLIENTE = """UPDATE cliente SET empleado_id = %s, cliente_nombre = %s, cliente_apellidos = %s, cliente_fecha_nacimiento = %s, cliente_direccion = %s WHERE cliente_id = %s;"""
UPDATE_DESTINO = """UPDATE destino SET municipio = %s WHERE destino_id = %s;"""
UPDATE_TRANSPORTE = """UPDATE transporte SET ciudad_origen = %s, ciudad_destino = %s, transporte_tipo = %s WHERE transporte_id = %s;"""
UPDATE_ALOJAMIENTO = """UPDATE alojamiento SET alojamiento_nombre = %s, alojamiento_direccion = %s, alojamiento_municipio = %s WHERE alojamiento_id = %s;"""
UPDATE_CONTRATA = ("UPDATE contrata SET cliente_id = %s, destino_id = %s WHERE cliente_id = %s RETURNING fecha_contratacion")
UPDATE_ACTIVIDAD = """UPDATE actividad SET actividad_tipo = %s, ocio_nombre = %s, ocio_descripcion = %s, deporte_nombre = %s, deporte_descripcion = %s, deporte_tipo = %s WHERE actividad_id = %s;""" 

app = Flask(__name__)

def get_db_connection():
  conn = psycopg2.connect(host='localhost', database='turismo',user="postgres",password="password")
  return conn

########################################################
### GET ###
########################################################

@app.get("/")
def home():
  return 'Base de datos: OFICINAS DE TURISMO DE TENERIFE'

@app.route('/read', methods=['GET'])
def index():
  if request.method == 'GET':
    data = request.get_json()
    tabla = data["tabla"]
    identi = data["id"]
    conn = get_db_connection()
    cur = conn.cursor()
    cur.execute('SELECT COLUMN_NAME FROM information_schema.columns WHERE table_name=%s',(tabla,))
    columna = [row[0] for row in cur]
    cur.execute(sql.SQL('SELECT * FROM {} WHERE {} = %s').format(sql.Identifier(tabla),sql.Identifier(columna[0])),(identi,))
    row = cur.fetchall()
    cur.close()
    conn.close()
    return row

@app.route('/read/all', methods=['GET'])
def read_all():
  if request.method == 'GET':
    data = request.get_json()
    tabla = data["tabla"]
    conn = get_db_connection()
    cur = conn.cursor()
    cur.execute(sql.SQL('SELECT * FROM {}').format(sql.Identifier(tabla)))
    row = cur.fetchall()
    cur.close()
    conn.close()
    return row

@app.get("/oficina/<int:oficina_id>")
def get_oficina(oficina_id):
  conn = get_db_connection()
  cursor = conn.cursor()
  cursor.execute(SELECT_OFICINA_ID, (oficina_id,))
  id = cursor.fetchone()[0]
  name = cursor.fetchone()[1]
  cursor.close()
  conn.close()
  return {"id": id, "oficina_nombre": name}

########################################################
### POST ###
########################################################

@app.post("/create/oficina")
def add_oficina():
  data = request.get_json()
  name = data["oficina_nombre"]
  conn = get_db_connection()
  cursor = conn.cursor()
  cursor.execute(INSERT_OFICINA_RETURN_ID, (name,))
  id = cursor.fetchone()[0]
  conn.commit()
  cursor.close()
  conn.close()
  return {"id": id, "message": f"Oficina {name} created."}, 201

@app.post("/create/ubicacion")
def add_ubicacion():
  data = request.get_json()
  municipio = data["municipio"]
  id = data["id"]
  direccion = data["direccion"]
  latitud = data["latitud"]
  longitud = data["longitud"]
  conn = get_db_connection()
  cursor = conn.cursor()
  cursor.execute(INSERT_UBICACION, (id,municipio,direccion,latitud,longitud))
  conn.commit()
  cursor.close()
  conn.close()
  return {"message": f"Ubicacion {direccion} created."}, 201

@app.post("/create/empleado")
def add_empleado():
  data = request.get_json()
  oficina_id = data["id"]
  direccion = data["direccion"]
  nombre = data["nombre"]
  apellidos = data["apellidos"]
  fecha_nacimiento = data["fecha_nacimiento"]
  conn = get_db_connection()
  cursor = conn.cursor()
  cursor.execute(INSERT_EMPLEADO, (oficina_id,nombre,apellidos,fecha_nacimiento,direccion))
  empleado_id = cursor.fetchone()[0]
  conn.commit()
  cursor.close()
  conn.close()
  return {"empleado_id": empleado_id, "message": f"Empleado {nombre, apellidos} created."}, 201

@app.post("/create/cliente")
def add_cliente():
  data = request.get_json()
  empleado_id = data["id"]
  cliente_nombre = data["nombre"]
  cliente_apellidos = data["apellidos"]
  cliente_fecha_nacimiento = data["fecha_nacimiento"]
  cliente_direccion = data["direccion"]
  conn = get_db_connection()
  cursor = conn.cursor()
  cursor.execute(INSERT_CLIENTE_RETURN_ID, (empleado_id, cliente_nombre, cliente_apellidos, cliente_fecha_nacimiento, cliente_direccion))
  cliente_id = cursor.fetchone()[0]
  conn.commit()
  cursor.close()
  conn.close()
  return {"cliente_id": cliente_id, "message": f"Empleado {cliente_nombre} created."}, 201

@app.post("/create/destino")
def add_destino():
  data = request.get_json()
  municipio = data["municipio"]
  conn = get_db_connection()
  cursor = conn.cursor()
  cursor.execute(INSERT_DESTINO, (municipio))
  destino_id = cursor.fetchone()[0]
  conn.commit()
  cursor.close()
  conn.close()
  return {"destino_id": destino_id, "message": f"Destino {municipio} created."}, 201

@app.post("/create/transporte")
def add_transporte():
  data = request.get_json()
  ciudad_origen = data["origen"]
  ciudad_destino = data["destino"]
  transporte_tipo = data["tipo"]
  conn = get_db_connection()
  cursor = conn.cursor()
  cursor.execute(INSERT_TRANSPORTE, (ciudad_origen, ciudad_destino, transporte_tipo))
  transporte_id = cursor.fetchone()[0]
  conn.commit()
  cursor.close()
  conn.close()
  return {"transporte_id": transporte_id, "message": f"Transporte {ciudad_origen}-{ciudad_destino} created."}, 201

@app.post("/create/alojamiento")
def add_alojamiento():
  data = request.get_json()
  alojamiento_nombre = data["nombre"]
  direccion = data["direccion"]
  municipio = data["municipio"]
  conn = get_db_connection()
  cursor = conn.cursor()
  cursor.execute(INSERT_ALOJAMIENTO, (alojamiento_nombre, direccion, municipio))
  alojamiento_id = cursor.fetchone()[0]
  conn.commit()
  cursor.close()
  conn.close()
  return {"cliente_id": alojamiento_id, "message": f"Alojamiento {alojamiento_nombre} created."}, 201


@app.post("/create/actividad")
def add_actividad():
  data = request.get_json()
  actividad_tipo = data["actividad_tipo"]
  ocio_nombre = data["ocio_nombre"]
  ocio_descripcion = data["ocio_descripcion"]
  deporte_nombre = data["deporte_nombre"]
  deporte_descripcion = data["deporte_descripcion"]
  deporte_tipo = data["deporte_tipo"]
  conn = get_db_connection()
  cursor = conn.cursor()
  cursor.execute(INSERT_ACTIVIDAD, (actividad_tipo, ocio_nombre, ocio_descripcion, deporte_nombre, deporte_descripcion, deporte_tipo))
  actividad_id = cursor.fetchone()[0]
  conn.commit()
  cursor.close()
  conn.close()
  return {"actividad_id": actividad_id, "message": f"Actividad {actividad_tipo} created."}, 201

@app.post("/create/contrata")
def add_contrata():
  data = request.get_json()
  cliente_id = data["cliente_id"]
  destino_id = data["destino_id"]
  conn = get_db_connection()
  cursor = conn.cursor()
  cursor.execute(INSERT_CONTRATA, (cliente_id, destino_id))
  fecha_contratacion = cursor.fetchone()[0]
  conn.commit()
  cursor.close()
  conn.close()
  return {"fecha_contratacion": fecha_contratacion, "message": f"Contrata {cliente_id}-{destino_id} created."}, 201

########################################################
### UPDATE - PUT ###
########################################################

@app.put("/update/oficina/<int:oficina_id>")
def update_oficina(oficina_id):
  data = request.get_json()
  name = data["oficina_nombre"]
  conn = get_db_connection()
  cursor = conn.cursor()
  cursor.execute(UPDATE_OFICINA, (name,oficina_id))
  conn.commit()
  cursor.close()
  conn.close()
  return {"id": oficina_id, "message": f"Oficina {name} updated."}, 201

@app.put("/update/empleado/<int:empleado_id>")
def update_empleado(empleado_id):
  data = request.get_json()
  oficina_id = data["id"]
  direccion = data["direccion"]
  nombre = data["nombre"]
  apellidos = data["apellidos"]
  fecha_nacimiento = data["fecha_nacimiento"]
  conn = get_db_connection()
  cursor = conn.cursor()
  cursor.execute(UPDATE_EMPLEADO, (oficina_id,nombre,apellidos,fecha_nacimiento,direccion,empleado_id))
  conn.commit()
  cursor.close()
  conn.close()
  return {"empleado_id": empleado_id, "message": f"Empleado {nombre, apellidos} updated."}, 201

@app.put("/update/ubicacion/<int:ubicacion_id>")
def update_ubicacion(ubicacion_id):
  data = request.get_json()
  municipio = data["municipio"]
  id = data["id"]
  direccion = data["direccion"]
  latitud = data["latitud"]
  longitud = data["longitud"]
  conn = get_db_connection()
  cursor = conn.cursor()
  cursor.execute(UPDATE_UBICACION, (id,municipio,direccion,latitud,longitud,ubicacion_id))
  conn.commit()
  cursor.close()
  conn.close()
  return {"ubicacion_id": ubicacion_id, "message": f"Ubicacion {direccion} updated."}, 201

@app.put("/create/cliente/<int:cliente_id>")
def update_cliente(cliente_id):
  data = request.get_json()
  empleado_id = data["id"]
  cliente_nombre = data["nombre"]
  cliente_apellidos = data["apellidos"]
  cliente_fecha_nacimiento = data["fecha_nacimiento"]
  cliente_direccion = data["direccion"]
  conn = get_db_connection()
  cursor = conn.cursor()
  cursor.execute(UPDATE_CLIENTE, (empleado_id, cliente_nombre, cliente_apellidos, cliente_fecha_nacimiento, cliente_direccion, cliente_id))
  conn.commit()
  cursor.close()
  conn.close()
  return {"cliente_id": cliente_id, "message": f"Empleado {cliente_nombre} updated."}, 201

@app.put("/create/destino/<int:destino_id>")
def update_destino(destino_id):
  data = request.get_json()
  municipio = data["municipio"]
  conn = get_db_connection()
  cursor = conn.cursor()
  cursor.execute(UPDATE_DESTINO, (municipio, destino_id))
  conn.commit()
  cursor.close()
  conn.close()
  return {"destino_id": destino_id, "message": f"Destino {municipio} updated."}, 201

@app.put("/create/transporte/<int:transporte_id>")
def update_transporte(transporte_id):
  data = request.get_json()
  ciudad_origen = data["origen"]
  ciudad_destino = data["destino"]
  transporte_tipo = data["tipo"]
  conn = get_db_connection()
  cursor = conn.cursor()
  cursor.execute(UPDATE_TRANSPORTE, (ciudad_origen, ciudad_destino, transporte_tipo, transporte_id))
  conn.commit()
  cursor.close()
  conn.close()
  return {"transporte_id": transporte_id, "message": f"Transporte {ciudad_origen}-{ciudad_destino} updated."}, 201

@app.put("/create/alojamiento/<int:alojamiento_id>")
def update_alojamiento(alojamiento_id):
  data = request.get_json()
  alojamiento_nombre = data["nombre"]
  direccion = data["direccion"]
  municipio = data["municipio"]
  conn = get_db_connection()
  cursor = conn.cursor()
  cursor.execute(UPDATE_ALOJAMIENTO, (alojamiento_nombre, direccion, municipio, alojamiento_id))
  conn.commit()
  cursor.close()
  conn.close()
  return {"cliente_id": alojamiento_id, "message": f"Alojamiento {alojamiento_nombre} updated."}, 201

@app.put("/update/contrata/<int:cliente_id>")
def update_contrata(cliente_id):
  data = request.get_json()
  cliente_id_new = data["cliente_id"]
  destino_id = data["destino_id"]
  conn = get_db_connection()
  cursor = conn.cursor()
  cursor.execute(UPDATE_CONTRATA, (cliente_id_new, destino_id, cliente_id))
  fecha_contratacion = cursor.fetchone()[0]
  conn.commit()
  cursor.close()
  conn.close()
  return {"fecha_contratacion": fecha_contratacion, "message": f"Contrata {cliente_id}-{destino_id} created."}, 201

@app.put("/update/actividad/<int:actividad_id>")
def update_actividad(actividad_id):
  data = request.get_json()
  actividad_tipo = data["actividad_tipo"]
  ocio_nombre = data["ocio_nombre"]
  ocio_descripcion = data["ocio_descripcion"]
  deporte_nombre = data["deporte_nombre"]
  deporte_descripcion = data["deporte_descripcion"]
  deporte_tipo = data["deporte_tipo"]
  conn = get_db_connection()
  cursor = conn.cursor()
  cursor.execute(UPDATE_ACTIVIDAD, (actividad_tipo, ocio_nombre, ocio_descripcion, deporte_nombre, deporte_descripcion, deporte_tipo, actividad_id))
  conn.commit()
  cursor.close()
  conn.close()
  return {"actividad_id": actividad_id, "message": f"Actividad {actividad_tipo} updated."}, 201

########################################################
### DELETE ###
########################################################

@app.delete('/delete')
def delete():
  data = request.get_json()
  id = data["id"]
  tabla = data["tabla"]

  conn = get_db_connection()
  cur = conn.cursor()
  cur.execute('SELECT COLUMN_NAME FROM information_schema.columns WHERE table_name=%s',(tabla,))
  columna = [row[0] for row in cur]
  cur.execute(sql.SQL('DELETE FROM {} WHERE {} = %s').format(sql.Identifier(tabla),sql.Identifier(columna[0])),(id,))
  conn.commit()
  cur.close()
  conn.close()
  return {"message": f"Row with ID: {id} deleted from table {tabla}"}