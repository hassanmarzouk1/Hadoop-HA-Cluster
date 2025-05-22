#!/bin/bash
# Part 2: Business Access Patterns + Part 3: Implementation Tasks
# --------------------------------------------------------------

### Business Requirement 1: Content Management ###

# 1. Retrieve latest version of a page by URL (Task 3.1)
echo "Retrieving latest version of d0b1_com.example_explore_wp-content:"
echo "get 'webtable', 'd0b1_com.example_explore_wp-content'" | hbase shell

# 2. View historical versions (Task 3.4)
echo "Viewing historical versions (last 2):"
echo "get 'webtable', 'd0b1_com.example_explore_wp-content', {COLUMNS => ['cf_content:html'], VERSIONS => 2}" | hbase shell

# 3. List pages from domain "com.example" (Task 3.3)
echo "Listing com.example domain pages:"
echo "scan 'webtable', {ROWPREFIXFILTER => 'd0b1_com.example', LIMIT => 10}" | hbase shell

# 4. Pages modified between 2025-03-01 and 2025-03-30 (Task 3.2)
echo "Finding pages modified in March 2025:"
echo "scan 'webtable', {TIMERANGE => [1746136800000, 1748642400000]}" | hbase shell

### Business Requirement 2: SEO Analysis ###

# 1. Find pages linking to https://example.com/tags/app (Task 3.2)
echo "Finding inbound links to https://example.com/tags/app:"
echo "scan 'webtable', {FILTER => \"SingleColumnValueFilter('cf_outlinks', 'links', =, 'substring:https://example.com/tags/app')\", LIMIT => 5}" | hbase shell

# 2. Identify pages with no outbound links (Task 3.2)
echo "Finding pages with empty outbound links:"
echo "scan 'webtable', {FILTER => \"SingleColumnValueFilter('cf_outlinks', 'links', =, 'binary:')\"}" | hbase shell

# 3. List pages with most inbound links (Task 3.3)
echo "Listing popular pages (sorted by inlink count):"
echo "scan 'webtable', {COLUMNS => ['cf_inlinks:links'], LIMIT => 5}" | hbase shell

# 4. Find pages with "error" in title (Task 3.2)
echo "Searching for pages with 'error' in title:"
echo "scan 'webtable', {FILTER => \"SingleColumnValueFilter('cf_meta', 'title', =, 'substring:error')\"}" | hbase shell

### Business Requirement 3: Performance Optimization ###

# 1. Identify largest pages (>8000 bytes) (Task 3.2)
echo "Finding largest pages:"
echo "scan 'webtable', {FILTER => \"SingleColumnValueFilter('cf_meta', 'content_size', >=, 'binary:8000')\"}" | hbase shell

# 2. Find error pages (4xx/5xx) (Task 3.2)
echo "Listing error pages:"
echo "scan 'webtable', {FILTER => \"(SingleColumnValueFilter('cf_meta', 'status_code', >=, 'binary:400') AND SingleColumnValueFilter('cf_meta', 'status_code', <=, 'binary:599'))\"}" | hbase shell

# 3. Find outdated content (>30 days) (Task 3.4)
current_ts=$(date +%s%3N)
thirty_days_ago=$((current_ts - 2592000000))
echo "Finding content older than 30 days:"
echo "scan 'webtable', {TIMERANGE => [0, $thirty_days_ago]}" | hbase shell

### Implementation Task 3.3: Pagination ###

# 1. Paginated domain scan (5 records/page)
echo "Paginating through com.example domain:"
echo "scan 'webtable', {ROWPREFIXFILTER => 'd0b1_com.example', LIMIT => 5}" | hbase shell
echo "Next page:"
echo "scan 'webtable', {STARTROW => 'LAST_RETURNED_ROWKEY', ROWPREFIXFILTER => 'd0b1_com.example', LIMIT => 5}" | hbase shell

### Implementation Task 3.4: Time-Based Operations ###

# 1. Create TTL table (90 days retention)
echo "Creating TTL-enabled table:"
echo "create 'webtable_ttl', {NAME => 'cf_content', TTL => 7776000}, {NAME => 'cf_meta', TTL => 7776000}, {NAME => 'cf_inlinks', TTL => 7776000}, {NAME => 'cf_outlinks', TTL => 7776000}" | hbase shell

# 2. Manual purge of old versions
echo "Purging versions older than 2025:"
echo "delete 'webtable', 'd0b1_com.example_explore_wp-content', 'cf_content:html', 1742853600000" | hbase shell