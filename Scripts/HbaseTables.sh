# Create table with column families and settings
create 'webtable',
  {NAME => 'cf_content', VERSIONS => 3, TTL => 7776000},  # 90 days in seconds
  {NAME => 'cf_meta', VERSIONS => 1},
  {NAME => 'cf_outlinks', VERSIONS => 2, TTL => 15552000}, # 180 days
  {NAME => 'cf_inlinks', VERSIONS => 2, TTL => 15552000},
  {COMPRESSION => 'SNAPPY', BLOCKSIZE => 65536}
