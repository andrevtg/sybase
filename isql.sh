#!/bin/bash
docker exec -ti sybase bash -c "source /opt/sybase/SYBASE.sh && isql -Usa -P$MYPASSWORD -SMYSYBASE"
