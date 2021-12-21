# docker-qgis-server

Basisimage für QGIS-Server, damit a) das Erstellen des ÖREB-QGIS-Server Images schneller geht und b) eine `linux/arm64`-Variante zur Verfügung steht.

**Achtung**: Das `linux/arm64`-Image verwendet QGIS 3.10 aus dem Ubuntu-Repo. Im Ubuntugis-Repo gibt es keine `linux/arm64`-Pakete.

## Usage
`docker run -p 8083:80 -e QGIS_FCGI_MIN_PROCESSES=2 -e QGIS_FCGI_MAX_PROCESSES=2 sogis/qgis-server:3.16`

Das Setzen der Min/Max-Env-Variablen ist notwendig, da sonst nach circa 10 Minuten der Server hängen bleibt. Im `error.log` steht "Im error.log steht dann "can't apply process slot for /usr/lib/cgi-bin/qgis_mapserv.fcgi"."
