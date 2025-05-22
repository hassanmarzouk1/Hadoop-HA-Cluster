from faker import Faker
import random
import hashlib
from datetime import datetime, timedelta

fake = Faker()
random.seed(42)

# Generate 5 domains and precompute their reverse + hash prefixes
domains = ["example.com", "test.org", "sample.net", "demo.co", "web.app"]
domain_info = {}
for domain in domains:
    reverse_domain = '.'.join(reversed(domain.split('.')))  # e.g., "com.example"
    hash_prefix = hashlib.md5(reverse_domain.encode()).hexdigest()[:4]
    domain_info[domain] = {
        "reverse": reverse_domain,
        "hash_prefix": hash_prefix
    }

# Generate 20 pages with URLs and creation dates
pages = []
all_urls = []

for _ in range(20):
    domain = random.choice(domains)
    url_path = fake.uri_path().strip('/')  # e.g., "/blog/post1"
    full_url = f"https://{domain}/{url_path}"
    all_urls.append(full_url)
    
    # Get domain-specific hash and reverse domain
    reverse_domain = domain_info[domain]["reverse"]
    hash_prefix = domain_info[domain]["hash_prefix"]
    
    # Generate row key: [hash]_[reverse_domain]_[url]
    row_key = f"{hash_prefix}_{reverse_domain}_{url_path.replace('/', '_')}"
    
    # Simulate creation dates (some old, some recent)
    creation_date = fake.date_between(start_date='-180d', end_date='today')
    creation_datetime = datetime.combine(creation_date, datetime.min.time())
    timestamp = int(creation_datetime.timestamp() * 1000)  # HBase uses milliseconds
    
    # Generate metadata
    status_code = random.choice([200, 404, 500])
    content_size = random.randint(1000, 10000)  # 1KB to 10KB
    
    pages.append({
        "row_key": row_key,
        "domain": domain,
        "url": full_url,
        "timestamp": timestamp,
        "cf_content:html": f"<html>{fake.text(2000)}</html>",
        "cf_meta:title": fake.sentence(),
        "cf_meta:status_code": str(status_code),
        "cf_meta:content_size": str(content_size),
        "cf_meta:creation_date": creation_date.strftime("%Y-%m-%d"),
        "cf_outlinks:links": []  # Populated later
    })

# Generate outlinks by randomly linking to other pages
for page in pages:
    # Select 3-5 random URLs (excluding self)
    eligible_urls = [url for url in all_urls if url != page["url"]]
    outlinks = random.sample(eligible_urls, k=random.randint(3, 5))
    page["cf_outlinks:links"] = outlinks

# Map URLs to row keys for inlink resolution
url_to_rowkey = {page["url"]: page["row_key"] for page in pages}

# Populate inlinks by processing outlinks
for page in pages:
    for outlink in page["cf_outlinks:links"]:
        target_rowkey = url_to_rowkey.get(outlink)
        if target_rowkey:
            # Add inlink to the target page
            target_page = next(p for p in pages if p["row_key"] == target_rowkey)
            target_page.setdefault("cf_inlinks:links", []).append(page["row_key"])

# Generate HBase shell commands
hbase_script = []
for page in pages:
    row_key = page["row_key"]
    timestamp = page["timestamp"]
    
    # Insert content, metadata, outlinks
    hbase_script.append(f"put 'webtable', '{row_key}', 'cf_content:html', '{page['cf_content:html']}', {timestamp}")
    hbase_script.append(f"put 'webtable', '{row_key}', 'cf_meta:title', '{page['cf_meta:title']}', {timestamp}")
    hbase_script.append(f"put 'webtable', '{row_key}', 'cf_meta:status_code', '{page['cf_meta:status_code']}', {timestamp}")
    hbase_script.append(f"put 'webtable', '{row_key}', 'cf_meta:content_size', '{page['cf_meta:content_size']}', {timestamp}")
    hbase_script.append(f"put 'webtable', '{row_key}', 'cf_meta:creation_date', '{page['cf_meta:creation_date']}', {timestamp}")
    
    # Insert outlinks
    outlinks = ",".join(page["cf_outlinks:links"])
    hbase_script.append(f"put 'webtable', '{row_key}', 'cf_outlinks:links', '{outlinks}', {timestamp}")
    
    # Insert inlinks (if any)
    inlinks = page.get("cf_inlinks:links", [])
    if inlinks:
        inlinks_str = ",".join(inlinks)
        hbase_script.append(f"put 'webtable', '{row_key}', 'cf_inlinks:links', '{inlinks_str}', {timestamp}")

# Write to file
with open("hbase_data_ingest.sh", "w") as f:
    f.write("#!/bin/bash\n")
    f.write("\n".join(hbase_script))

print("Generated 20 pages with interlinked structures, hash-prefixed row keys, and timestamps.")