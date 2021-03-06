#!/bin/bash
# Copyright 2016 AT&T Intellectual Property, Inc
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -e

TEMP_DIR="/tmp"
PYTHON_FILE_SERVER_ROOT=${TEMP_DIR}/python-simple-http-webserver
PID_FILE="server.pid"

ctx logger info "Starting HTTP server from ${PYTHON_FILE_SERVER_ROOT}"

port=$(ctx node properties port)

cd ${PYTHON_FILE_SERVER_ROOT}
ctx logger info "Starting SimpleHTTPServer"
nohup python -m SimpleHTTPServer ${port} > /dev/null 2>&1 &
echo $! > ${PID_FILE}

ctx logger info "Waiting for server to launch on port ${port}"
url="http://localhost:${port}"

server_is_up() {
	if which wget >/dev/null; then
		if wget $url >/dev/null; then
			return 0
		fi
	elif which curl >/dev/null; then
		if curl $url >/dev/null; then
			return 0
		fi
	else
		ctx logger error "Both curl, wget were not found in path"
		exit 1
	fi
	return 1
}

STARTED=false
for i in $(seq 1 15)
do
	if server_is_up; then
		ctx logger info "Server is up."
		STARTED=true
    	break
	else
		ctx logger info "Server not up. waiting 1 second."
		sleep 1
	fi
done
if [ ${STARTED} = false ]; then
	ctx logger error "Failed starting web server in 15 seconds."
	exit 1
fi
