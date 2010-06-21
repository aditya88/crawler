CREATE TYPE download_state AS ENUM ('error', 'fetching', 'pending', 'queued', 'success');    
CREATE TYPE download_type  AS ENUM ('archival_only','content');    
CREATE TYPE download_status  AS ENUM ('done','error','new','ready');
create table downloads (
    downloads_id        	serial          	primary key,
    parent              	int             	null,
    url                 	varchar(1024)   	not null,
    location            	varchar(1024)   	null,
    host                	varchar(1024)   	not null,
    download_time       	timestamp       	not null,
    type                	download_type   	not null,
    state               	download_state  	not null,
    priority            	int             	null,
    path                	text            	null,
    error_message       	text            	null,
    sequence            	int             	not null,
    extracted           	boolean         	not null default 'f',
    mm_hash_url         	varchar(10)     	null,
    mm_hash_location            varchar(10)     	null,
    download_id_of_old_copy     int			null       
);

create table requests (
request_id			serial			primary key,
client_id			int			not null,
download_type			download_type		not null default 'archival_only',
refresh_rate			int			not null default '86400',
depth_of_search			int			not null default '3',
allowed_content			text			not null default 'text/html'
);

create table downloads_queue (
url_id                          serial                  primary key,
request_id			int			not null references requests(request_id),
url				varchar(1024)		not null,
status				download_status		not null		
);


CREATE VIEW downloads_sites as select regexp_replace(host, $q$^(.)*?([^.]+)\.([^.]+)$$q$ ,E'\\2.\\3') as site, * from downloads;

CREATE INDEX hash_url ON downloads (mm_hash_url) ;
CREATE INDEX hash_location ON downloads (mm_hash_location) ;
CREATE INDEX index_location ON downloads (location) ;
