## Run Elasticsearch docker container

Use the following command, where we are disabling security, so we can use http and not authenticate

```
# Security disabled
docker run -d --name elasticsearch -p 9200:9200 -p 9300:9300 -e "discovery.type=single-node" -e xpack.security.enabled=false elasticsearch:8.6.2
```

Check health with curl `http://localhost:9200`

## Create the component and index templates

Create a component template

```
curl -H "Content-Type: application/json" -X PUT http://localhost:9200/_component_template/cdr_component_template -d '
{
    "template": {
        "settings": {
            "number_of_shards": 1
        },
        "mappings": {
            "_source": {
                "enabled": true
            },
            "properties": {
                "EventDate": {
                    "type": "date"
                },
                "AcctStatusType": {
                    "type": "keyword"
                },
                "AcctSessionId": {
                    "type": "keyword"
                },
                "AcctSessionTime": {
                    "type": "long"
                },
                "BytesDown": {
                    "type": "long"
                },
                "BytesUp": {
                    "type": "long"
                },
                "PacketsDown": {
                    "type": "long"
                },
                "PacketsUp": {
                    "type": "long"
                },
                "NASIdentifier": {
                    "type": "keyword"
                },
                "NASIPAddress": {
                    "type": "ip"
                },
                "NASPort": {
                    "type": "long"
                },
                "ClientId": {
                    "type": "keyword"
                },
                "AccessType": {
                    "type": "long"
                },
                "UserName": {
                    "type": "keyword"
                },
                "CallingStationId": {
                    "type": "keyword"
                },
                "CircuitId": {
                    "type": "keyword"
                },
                "RemoteId": {
                    "type": "keyword"
                },
                "IPAddress": {
                    "type": "ip"
                },
                "ConnectInfo": {
                    "type": "keyword"
                },
                "TerminateCause": {
                    "type": "keyword"
                },
                "NATStartPort": {
                    "type": "keyword"
                },
                "NATEndPort": {
                    "type": "keyword"
                },
                "NATIPAddress": {
                    "type": "ip"
                },
                "MACAddress": {
                    "type": "keyword"
                },
                "ChargeableUserIdentity": {
                    "type": "keyword"
                },
                "IPv6DelegatedPrefix": {
                    "type": "keyword"
                },
                "IPv6BytesDown": {
                    "type": "long"
                },
                "IPv6BytesUp": {
                    "type": "long"
                },
                "IPv6PacketsDown": {
                    "type": "long"
                },
                "IPv6PacketsUp": {
                    "type": "long"
                },
                "AccessNode": {
                    "type": "keyword"
                },
                "Class": {
                    "type": "keyword"
                },
                "RadiusHost": {
                    "type": "keyword"
                }
            }
        }
    }
}'
```

Check that it is created with `curl http://localhost:9200/_component_template/cdr_component_template` or with
`http://localhost:9200/_cat/component_templates`

Create an index template with

```
curl -H "Content-Type: application/json" -X PUT http://localhost:9200/_index_template/cdr_index_template -d '
{
  "index_patterns": ["cdr*", "sessions"],
  "composed_of": ["cdr_component_template"]
}'
```

Check that it is created with `curl http://localhost:9200/_index_template/cdr_index_template` or with `http://localhost:9200/_cat/templates`


## Cleanup of component and index templates

Delete index template and component template

```
curl -H "Content-Type: application/json" -X DELETE http://localhost:9200/_index_template/cdr_index_template 
curl -H "Content-Type: application/json" -X DELETE http://localhost:9200/_component_template/cdr_component_template
```

## Insert some documents


## List the indices

```
curl http://localhost:9200/_cat/indices
```

## Delete the index

```
# Deleting the "sessions" index
curl -X DELETE http://localhost:9200/sessions
```


