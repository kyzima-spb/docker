

```shell
$ wget -qO- https://kyzima-spb.github.io/docker-useful/mongodb.sh.tmpl | sed 's/%%COMPOSE_COMMAND%%/docker compose/' > mongodb.sh
$ chmod +x mongo.sh
```
