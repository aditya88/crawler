CREATE TYPE download_state AS ENUM ('error', 'fetching', 'pending', 'queued', 'success');    
CREATE TYPE download_type  AS ENUM ('archival_only','content');    

create table downloads (
    downloads_id        serial          primary key,
    parent              int             null,
    url                 varchar(1024)   not null,
    location            varchar(1024)   null,
    host                varchar(1024)   not null,
    download_time       timestamp       not null,
    type                download_type   not null,
    state               download_state  not null,
    priority            int             null,
    path                text            null,
    error_message       text            null,
    sequence            int             not null,
    extracted           boolean         not null default 'f',
    md5_hash            varchar(32)     not null       
);

CREATE VIEW downloads_sites as select regexp_replace(host, $q$^(.)*?([^.]+)\.([^.]+)$$q$ ,E'\\2.\\3') as site, * from downloads;

CREATE UNIQUE INDEX hash ON downloads (md5_hash) ;
CREATE INDEX index_location ON downloads (location) ;
