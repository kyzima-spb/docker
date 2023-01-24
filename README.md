

```shell
$ wget -qO- https://kyzima-spb.github.io/docker-useful/mongodb.sh.tmpl | \
      sed \
          -e 's/%%COMPOSE_COMMAND%%/docker compose/' \
          -e 's/%%SERVICE_NAME%%/mongodb/' \
          > mongodb.sh

$ chmod +x mongodb.sh
```
