# Uso responsable

Este laboratorio existe para aprender. *No* es un parque para atacar
sistemas que no controlas.

## Que esta bien

- Ejecutarlo en tu maquina personal, en una VM o en una red de laboratorio.
- Compartirlo con companeros que tambien quieran practicar y entiendan que
  es vulnerable a proposito.
- Modificarlo para anadir nuevos retos o quitar los que ya dominas.

## Que NO esta bien

- Exponerlo a internet, a la VPN del trabajo, a la red WiFi de la facultad
  o a cualquier red en la que haya gente ajena al ejercicio.
- Aplicar las mismas tecnicas contra sistemas que no son tuyos o para los
  que no tienes autorizacion **escrita y especifica**.
- Reutilizar las contrasenas, hashes o tokens "demo" que aparecen en el
  laboratorio en sistemas reales: aunque parezcan inocentes, se han usado
  publicamente y estan en cualquier lista de wordlists.

## Antes de levantarlo

1. Comprueba que tu cortafuegos local no expone los puertos `8080-8088`
   hacia la red.
2. Si usas WSL, Docker Desktop o un Mac con file sharing, verifica que el
   puerto solo se publica en `127.0.0.1` (puedes cambiar la seccion
   `ports:` para forzar `127.0.0.1:8080:80`).
3. Apagalo cuando termines (`make down`).

## Si encuentras una vulnerabilidad real

Las vulnerabilidades de las imagenes upstream (DVWA, Juice Shop, phpMyAdmin,
MariaDB, Nginx) deben reportarse a **sus** proyectos, no aqui. Este
repositorio solo provee orquestacion y configuracion didactica.

## Marco legal

En Espana / LATAM / UE, el acceso no autorizado a sistemas informaticos
esta tipificado (p. ej. Codigo Penal espanol art. 197 bis y art. 264;
LFPDPPP en Mexico; CFAA en EE. UU.). El "uso educativo" no exime de
responsabilidad si afecta sistemas de terceros.

> En resumen: prueba, rompe y aprende **dentro de tu laboratorio**.
