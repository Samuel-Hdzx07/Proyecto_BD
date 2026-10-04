# Levantamiento del proyecto asignado: Sismos

- **Repositorio original:** https://github.com/gabrielhuav/Seismic-Data-Visualization-System
- **Fork:** https://github.com/Samuel-Hdzx07/Seismic-Data-Visualization-System
- **Commit con el que se puso en funcionamiento:** `8569667cf4f46fab640dba3f82a7b324ca7efaf7`
- **Fecha del levantamiento:** 26 de septiembre de 2026
- **Autor:** Hernandez Barrios Samuel Rodrigo (3CV4)

## 1. Requisitos

- Windows con Docker Desktop (plan Personal), con 16 CPUs y unos 7.4 GB de memoria disponibles para contenedores.
- Git.
- Navegador web (Chrome).
- Imágenes que descarga el proyecto: `postgres:17` (base de datos) y la imagen web del propio proyecto.
- Puertos publicados en el equipo: **80** (aplicación web) y **5433** (PostgreSQL, que escucha en el 5432 dentro del contenedor).

## 2. Pasos ejecutados (en orden)

1. Fork del repositorio original y clonación en el equipo:
```bash
   git clone https://github.com/Samuel-Hdzx07/Seismic-Data-Visualization-System
   cd Seismic-Data-Visualization-System
```
2. Arranque de los servicios con la definición de contenedores que trae el repositorio (Docker Compose), que crea el proyecto `seismic-data-visualization-system` con dos servicios, `db` y `web`:
```bash
   docker compose up -d
```
3. Verificación en Docker Desktop de que ambos contenedores están en ejecución:
   - `db-1`: imagen `postgres:17`, puertos `5433:5432`.
   - `web-1`: imagen del proyecto, puertos `80:80`.

   Captura: [arranque_docker.png](capturas/arranque_docker.png)
4. Apertura de la aplicación en el navegador: `http://localhost/vista.html`. La interfaz "Impacto de Sismos en México" muestra tres opciones en el panel lateral: Sismos en México, Población de México y Economía de México.

   Captura: [interfaz_web.png](capturas/interfaz_web.png)

## 3. Consulta directa sobre la base de datos

Desde Docker Desktop, en el contenedor `seismic-data-visualization-system-db-1`, pestaña **Exec**, se abrió una sesión de `psql` (versión 17.11) sobre la base `datawarehouse`:

```bash
psql -U postgres -d datawarehouse
```

```sql
SELECT * FROM dim_sismos LIMIT 5;
```

Resultado: 5 filas de la dimensión de sismos, con las columnas `id_sismo`, `magnitud`, `latitud`, `longitud`, `profundidad`, `referencia_de_localizacion`, `estado` y `nombre_estado`.

| id_sismo | magnitud | latitud | longitud | profundidad | referencia_de_localizacion | estado | nombre_estado |
|---|---|---|---|---|---|---|---|
| 0 | 7.4 | 20 | -105 | 33 | 71 km al NOROESTE de AUTLAN DE NAVARRO, JAL | JAL | Jalisco |
| 1 | 6.9 | 20 | -105 | 33 | 71 km al NOROESTE de AUTLAN DE NAVARRO, JAL | JAL | Jalisco |
| 2 | 6.9 | 25 | -110 | 33 | 100 km al NORESTE de LA PAZ, BCS | BCS | Baja California Sur |
| 3 | 7 | 26 | -110 | 33 | 83 km al OESTE de AHOME, SIN | SIN | Sinaloa |
| 4 | 7 | 17.62 | -99.72 | 33 | 21 km al OESTE de ZUMPANGO DEL RIO, GRO | GRO | Guerrero |

Captura: [consulta_sql.png](capturas/consulta_sql.png)

## 4. Errores encontrados y cómo se resolvieron

Durante el despliegue se presentaron problemas de configuración de contenedores y de puertos. Se resolvieron con apoyo de una herramienta de IA (declarada en el README) y ajustando los puertos publicados hasta que ambos servicios quedaron en ejecución: aplicación en el puerto 80 y base de datos en el 5433.

## 5. Observaciones

- La base de datos se llama `datawarehouse` y la tabla consultada, `dim_sismos`, guarda el estado dos veces: abreviado (`estado`) y con nombre completo (`nombre_estado`). Es la redundancia que señala la tabla de correspondencia con el modelo EER.
- En las cinco filas consultadas `profundidad` vale 33. Podría ser un valor por defecto o imputado; conviene revisarlo con una consulta sobre toda la tabla.
- Las tres opciones de la interfaz (sismos, población y economía) corresponden a las tres fuentes de datos que se modelan en el EER.
- En el mismo Docker Desktop sigue existiendo el contenedor de la Práctica 1 (`pg-practica1`, `postgres:16`, puerto 5454). Los puertos publicados de ambos proyectos no se solapan.