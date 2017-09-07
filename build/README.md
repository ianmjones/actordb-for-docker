# ActorDB for Docker
[![Docker Automated build](https://img.shields.io/docker/automated/bytepixie/actordb.svg?maxAge=2592000)](https://github.com/bytepixie/actordb-for-docker/tree/master/build/) [![](https://images.microbadger.com/badges/image/bytepixie/actordb.svg)](https://microbadger.com/images/bytepixie/actordb "Get your own image badge on microbadger.com")

**PLEASE NOTE:** *This is an unofficial package, [go badger Biokoda](https://github.com/biokoda/actordb/issues) for an official [ActorDB](http://www.actordb.com) image if that is of concern!*

## Supported Tags and Respective Dockerfile Links
* 0.10.25-1, latest - [Dockerfile](https://github.com/bytepixie/actordb-for-docker/blob/master/build/Dockerfile)
* 0.10.25 - [Dockerfile](https://github.com/bytepixie/actordb-for-docker/blob/0.10.25/build/Dockerfile)
* 0.10.24 - [Dockerfile](https://github.com/bytepixie/actordb-for-docker/blob/0.10.24/build/Dockerfile)
* 0.10.22 - [Dockerfile](https://github.com/bytepixie/actordb-for-docker/blob/0.10.22/build/Dockerfile)

## What is ActorDB?
[ActorDB](http://www.actordb.com) is a ...

"Distributed SQL database with linear scalability.

ActorDB is strongly consistent, distributed and horizontally scalable.

Based on an industry-proven reliable database engine."

Please visit the [ActorDB project's site](http://www.actordb.com) for a full run-down and [documentation](http://www.actordb.com/docs-about.html).

## Usage
You can use this image to start up an ActorDB node. You'll want to specify a host volume for where the data should be persisted between runs, and ports to connect to.

    $ docker run -d -v /opt/actordb/data:/var/lib/actordb -p 33306:33306 -p 33307:33307 --name actordb bytepixie/actordb

The above starts up ActorDB in detached mode, with data stored locally in `/opt/actordb/data`, and ports 33306 and 33307 made available locally. It'll use the default `app.config` and `vm.args` [installed by the .deb package](https://github.com/biokoda/actordb/tree/master/etc).

You can also use the example schema setup to have a play...

    $ docker exec -it actordb actordb_console -f /etc/actordb/init.example.sql
    Config updated.
    Config updated.
    Schema updated.

... and then run some of the examples from the [Get Started doc](http://www.actordb.com/docs-getstarted.html)...

    $ docker exec -it actordb actordb_console -u myuser -pw mypass
    *******************************************************************
    Databases:
    use config (use c)  initialize/add nodes and user account management
    use schema (use s)  set schema
    use actordb (use a) (default) run queries on database
    *******************************************************************
    Commands:
    open         (windows only) open and execute .sql file
    q            exit
    h            print this header
    commit (c)   execute transaction
    rollback (r) abort transaction
    print (p)    print transaction
    show (s)     show schema
    show status  show database status
    show queries show currently running queries
    show shards  show shards on node
    *******************************************************************

    actordb> ACTOR type1(music) CREATE; 
    actordb (1)> INSERT INTO tab (i,txt) VALUES (42,"this is our first run");
    actordb (2)> c
    Rowid: 1, Rows changed: 1
    actordb> ACTOR type1(music); SELECT * FROM tab;
    actordb (1)> c
    *****************************
    i  id txt                   |
    -----------------------------
    42 1  this is our first run |
    -----------------------------
    actordb> ACTOR type1(sport) CREATE;
    actordb (1)> INSERT INTO tab (i,txt) VALUES (1,"Insert into sport.");
    actordb (2)> ACTOR type1(reading) CREATE;
    actordb (3)> INSERT INTO tab (i,txt) VALUES (2,"Insert into reading.");
    actordb (4)> ACTOR type1(paint) CREATE;
    actordb (5)> INSERT INTO tab (i,txt) VALUES (3,"Insert into paint.");
    actordb (6)> c
    Rowid: 0, Rows changed: 3
    actordb> ACTOR type1(sport,reading,paint);
    actordb (1)> INSERT INTO tab (i,txt) VALUES (2,"Insert into three type1 actors.");
    actordb (2)> c
    Rowid: 0, Rows changed: 3
    actordb> actor type1(*); {{RESULT}}select * from tab;
    actordb (1)> c
    ***********************************************
    actor   i  id txt                             |
    -----------------------------------------------
    sport   1  1  Insert into sport.              |
    sport   2  2  Insert into three type1 actors. |
    music   42 1  this is our first run           |
    paint   3  1  Insert into paint.              |
    paint   2  2  Insert into three type1 actors. |
    reading 2  1  Insert into reading.            |
    reading 2  2  Insert into three type1 actors. |
    -----------------------------------------------
    actordb> q
    Bye!

Use the MySQL client to connect.

    $ mysql -umyuser -pmypass -h127.0.0.1 -P33307
    Warning: Using a password on the command line interface can be insecure.
    Welcome to the MySQL monitor.  Commands end with ; or \g.
    Your MySQL connection id is 0
    Server version: 5.5.0-myactor-proto 5.5.0-myactor-proto

    Copyright (c) 2000, 2015, Oracle and/or its affiliates. All rights reserved.

    Oracle is a registered trademark of Oracle Corporation and/or its
    affiliates. Other names may be trademarks of their respective
    owners.

    Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

    mysql> ACTOR type1(sport); SELECT * FROM tab;
    Query OK, 0 rows affected (0.00 sec)

    +------+---------------------------------+------+
    | id   | txt                             | i    |
    +------+---------------------------------+------+
    |    1 | Insert into sport.              |    1 |
    |    2 | Insert into three type1 actors. |    2 |
    +------+---------------------------------+------+
    2 rows in set (0.00 sec)

    mysql> exit;
    Bye

## Configuration
### Ports
By default the image exposes two ports:

* 33306: Thrift client interface.
* 33307: MySQL client interface.

### Volumes
By default the image exposes three volumes:

* /var/lib/actordb: Data files.
* /etc/actordb: Configuration files.
* /var/log/actordb: Log files.

You probably want to mount at least the data and logs volumes in order to persist your data and inspect the logs. If the config volume isn't mounted then a default config is used, but if mounted you'll need to supply an `app.config` and `vm.args` file.

### Environment Variables

#### `NEW_UID`
Set the user ID that the `actordb` user should use, great for ensuring that data is created with the same UID as the host user running the container and therefore more manageable on the host.

#### `NEW_GID`
Set the group ID that the `actordb` user should use, great for ensuring that data is created with the same GID as the host user running the container and therefore more manageable on the host.

#### `ACTORDB_NODE`
Overrides the `-name` setting from the vm.args file to give the node a new name when the container is first started. If not used then the node name from the /etc/actordb/vm.args file is used (default is actordb@actordb.local).

### User
The default user is root, but the actordb process runs as an "actordb" user.

## ActorDB Configuration Notes
Some things to remember when configuring ActorDB.

Each node you bring up *must* have a unique `-name` in its vm.args file. This means the part *before* the "@".

When using Docker, you can use the `--name` you give the container after the "@" in the `-name` setting of vm.args (also see the `ACTORDB_NODE` environment variable).
When using Docker Compose, you can use the service name after the "@" in the `-name` setting of vm.args to ensure the nodes can chat.

You *must* remember to add each node that makes up a cluster into the nodes table. In the example `init.example.sql` it only inserts the current node's name, but you'll want to add the others.

    use config
    insert into groups values ('grp1','cluster')
    -- localnode() is whatever is in vm.args (-name ....) for node we are connected to.
    insert into nodes values (localnode(),'grp1')
    insert into nodes values ('node2@actordb-server-2','grp1')
    insert into nodes values ('node3@actordb-server-3','grp1')
    CREATE USER 'root' IDENTIFIED BY 'rootpass'
    commit

The above is taken from an [updated `init.example.sql`](https://github.com/bytepixie/actordb-for-docker/blob/master/node1/etc/init.example.sql) that is used for a very simple (and not very good) [example Docker Compose setup](https://github.com/bytepixie/actordb-for-docker/blob/master/docker-compose.yml).

## Contributing & Issues
If you have problems with or questions about this image, please raise an issue on the [GitHub repo](https://github.com/bytepixie/actordb-for-docker/issues).
Pull requests are even better!
