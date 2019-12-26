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

###Examples:
- search
>elk -index "win" -action search -query '{"query": {"match_all": {}}}'
