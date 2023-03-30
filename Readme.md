# radius2elasticsearch

Tool that receives radius accounting packets and stores them in an elasticsearch database

## Quickstart

Requres Go 1.18 or higher

```bash
# Generate the executable
git clone https://github.com/francistor/radius2elasticsearch.git
go build

# Launch
radius2elasticsearch/radius2elasticsearch -elasticurl <url-of-the-elasticsearch-server> &
```

## Configuration

Normally you need to tweak at least the file `resources/elasticFormat.json`

The default configuration is like this

```
{
	"attributeMap": {
		"MSISDN": "User-Name",
		"SessionId": "Acct-Session-Id",
		"SessionTime": "Acct-Session-Time!Acct-Delay-Time",
		"Status": "Acct-Status-Type",
		"IPAddress": "Framed-IP-Address",
		"NASIPAddress": "NAS-IP-Address",
		"Timestamp": "Event-Timestamp"
	},
	"indexName": "sessions",
	"indexType": "fixed",
	"idFields": ["Framed-IP-Address"],
	"versionField": "Event-Timestamp",
  "separator": ","
}
```

The first section, `attributeMap`, defines the mapping between the Radius attributes and the fields in the JSON document. If there are multiple AVP matching
that name, they are separated using the character specified as "separator". Multiple fields my be specified to generate the output property, with the following conventions
* ":" means write the first non null AVP. For instance "NAS-IP-Address:NAS-Identifier" will write the NAS-IP-Address, or the NAS-Identifier if the first is not present
* "!" means substraction
* "+" means adding the specified attributes
* "<" Add the second attribute multiplied by 2^32 (for Gigawords)"
 
The `indexName` specifies the input for the index to write to. This value is interpreted depending on the specification for the `indexType`. If `fixed`, the index name is taken as it is. If the `indexType` is `field`, then the index name is the concatenation of the `indexName` plus the value of the specified radius attribute that, if it of type date, will be formated using the `indexDateFormat` specification (go format). If the `indexType` is `currentDate`, the index name will be the value for `indexName` appended with the value of the insertion date, formatted also using `indexDateFormat` specification.

If `idFields` is specified, the `_id` will not be autogenerated, but calculated as the concatenantion of the specified radius attributes. The ElasticSearch version of the document will be the current timestamp or the value of the specified attribute. An additional offset is added for Interim-Updates and for Stops to ensure that Radius rules are followed (e.g. an Stop will always have a higher version than an Interim-Update).

`versionField` must be empty or assigned to a Time radius attribute, to make sure that newer events overrite older ones. Internally, it is converted to a number of seconds since the Epoch, and a "fake" offset is added to interim and stop events to make sure that stops override any interims, and interims override any starts.

### Session storage or CDR storage

There are two modes of operation, depending on the configuration. 

The first one is intended for storage of current sessions. In this case, the _id field has a re-usable value, such as an IP-Address or a User-Name. A new session with the same attribute will override the previous entry. Typically, the Acct-Status-Type will indicate whether the session is active (values `Start` or `Interim-Update`) or is finished (value `Stop`). This index will not grow indefinetely with time.

The second one is intended for storage of event records. In this case, the _id field has a value that represents an individual session, such as an `Accounting-Session-Id` or an `Accounting-Session-Id` plus `NAS-IP-Address`, to warantee uniqueness. The record may be overriten as updates in the form of interim accounting or stops are coming, but is not overriden by other events for the same IP-Address, line or user. 


### Elasticsearch requires some time for the inserted data to be readable

Elasitsearch will require a few seconds in order for the just inserted information to be available. This parameter is configurable in Elasticsearch.


### Listening ports

Use the following environment variables
* `IGOR_METRICS_PORT` The default is 29090
* `IGOR_AUTH_PORT` the default is 21812
* `IGOR_ACCT_PORT` the default is 21813

### Advanced

There is a number of files in the `resources` directory

* `diamterServer.json` should be always left as it is
* `log.json` is in `uber/zap` format. Use it to change the log level or the location of the logs instead of the standard output
* `metrics.json` to change the metrics export port
* `radiusServer.json` to change the radius listen ports
* `radiusServers.json` should be left as it is
* `searchRules.json` should be left as it is

You may change the contents of `dictionary` and the files inside `freeradius_dictionaries` to add or change radius attributes definitions

## Running in Docker

The image is published as `francistor/radius2elasticsearch:<tag>`

Launch attached with to the terminal, with removal on exit, with

```bash
docker run --name The image is published as `francistor/radius2elasticsearch:<tag>` --rm -it -p 21812:21812 -p 21813:21813 francistor/radius2elasticsearch:0.2
``` 

Or detached

```
docker run --name radius2elasticsearch -p 21812:21812 -p 21813:21813 -d francistor/radius2elasticsearch:0.2
```

For customization of the configuration, you may mount a volume with the configuration files (that includes the dictionaries)

```
docker run --rm -it -p 21812:21812 -p 21813:21813 -p 18080:18080 -v <radius2elasticsearch-location>/resources:/radius2elasticsearch/resources --name radius2elasticsearch francistor/radius2elasticsearch:0.2
```





