# ElasticPS
### PowerShell functions for worcking with ElasticSearch
##### Using the function you can:
- search
- search witch partition
- create index
- delete index
- insert (single)
- insert bulk
- delete by query
- custom

### Examples:
- search
```sh
elk -index "win" -action search -query '{"query": {"match_all": {}}}'
```
- search witch partition
```sh
elk -index "win" -action search_partition -partition 10 -ins_json_data '{"size": 0,"aggs": {"ip": {"terms": {"field": "ipaddress", "size":1000,"include": {"partition": 1,"num_partitions": 11 }},"aggregations": {"fqdn": {"terms": {"field": "fqdn"}}}}}}'
```
- create index
```sh
elk -index "name_create_index" -action index_create
```
- delete index
```sh
elk -index "name_create_index" -action index_delete
```
- insert (single)
```sh
$json = '{"name" : "user", "phone": "12345"}'
elk -index "users_index" -action insert_single -ins_json_data $json
```
- insert bulk
```sh
$json = '{"name" : "user", "phone": "12345"}','{"name" : "user1", "phone": "22225"}'
elk -index "users_index" -action insert_bulk -partition 1000 -ins_json_data $json
```
- delete by query
```sh
elk -index "users_index" -action delete_by_query -query '{"query": {"match_all": {}}}'
```
- custom
```sh
```
