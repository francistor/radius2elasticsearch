#!/bin/bash

# The first steps are not really necesary. Added only for documentation purposes

# Delete the index
curl -X DELETE http://localhost:9200/sessions

# Delete the index templates
curl -H "Content-Type: application/json" -X DELETE http://localhost:9200/_index_template/cdr_index_template 
curl -H "Content-Type: application/json" -X DELETE http://localhost:9200/_component_template/cdr_component_template

# Delete the elasticsearch container
docker stop elasticsearch
docker rm elasticsearch
