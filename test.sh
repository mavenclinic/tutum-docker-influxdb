#!/usr/bin/env bash
#
###################
INFLUX_HOST="127.0.0.1"

sudo docker stop influx-test
sudo docker rm influx-test

# start the server; expose http and udp api, create db
sudo docker run --name influx-test -d -p 8083:8083 --expose 8099 --expose 8090 -p 5454:4444/udp -p 8086:8086 -e PRE_CREATE_DB='test' -e UDP_DATABASE='test' nickjacob/influx
sudo docker ps a

sleep 2


influx-http()
{
  local data="$2"
  curl -X POST 'http://127.0.0.1:8086/db/test/series?u=root&p=root' -d $data
}

influx-udp()
{
  python -c "import socket; sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM); sock.sendto('$1', ('127.0.0.1', 5454))"
}

echo "waiting for server to start listening..."
#sleep 10

echo "testing http api"
curl -X POST 'http://127.0.0.1:8086/db/test/series?u=root&p=root' -d '{"name":"http_test", "columns": ["value"], "points":[[1]]}'

echo "testing udp api"
influx-udp '[{"name":"udp_test", "columns": ["value"], "points":[[1]]}]'

curl -G 'http://127.0.0.1:8086/db/test/series?u=root&p=root' --data-urlencode 'q=list series'
