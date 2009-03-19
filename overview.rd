= Pure Ruby Interface of Tokyo Tyrant

Tokyo Tyrant: network interface of Tokyo Cabinet

== INTRODUCTION

This module implements the pure Ruby client which connects to the server of Tokyo Tyrant and speaks its original binary protocol.

Tokyo Tyrant is a package of network interface to the DBM called Tokyo Cabinet.  Though the DBM has high performance, you might bother in case that multiple processes share the same database, or remote processes access the database.  Thus, Tokyo Tyrant is provided for concurrent and remote connections to Tokyo Cabinet.  It is composed of the server process managing a database and its access library for client applications.

The server features high concurrency due to thread-pool modeled implementation and the epoll/kqueue mechanism of the modern Linux/*BSD kernel.  The server and its clients communicate with each other by simple binary protocol on TCP/IP.  Protocols compatible with memcached and HTTP/1.1 are also supported so that almost all principal platforms and programming languages can use Tokyo Tyrant.  High availability and high integrity are also featured due to such mechanisms as hot backup, update logging, and replication.  The server can embed Lua, a lightweight script language so that you can define arbitrary operations of the database.

Because the server uses the abstract API of Tokyo Cabinet, all of the six APIs: the on-memory hash database API, the on-memory tree database API, the hash API, the B+ tree database API, the fixed-length database API, and the table database API, are available from the client with the common interface.  Moreover, the table extension is provided to use specifidc features of the table database.

=== Setting

Get this package and extract it.

Enter the directory of the extracted package then perform installation.

 su
 ruby install.rb

The package `tokyotyrant' should be loaded in each source file of application programs.

 require 'tokyotyrant'

All symbols of Tokyo Tyrant are defined in the module `TokyoTyrant'.  You can access them without any prefix by including the module.

 include TokyoTyrant


= EXAMPLE

The following code is an example to use a remote database.

 require 'tokyotyrant'
 include TokyoTyrant
 
 # create the object
 rdb = RDB::new
 
 # connect to the server
 if !rdb.open("localhost", 1978)
   ecode = rdb.ecode
   STDERR.printf("open error: %s\n", rdb.errmsg(ecode))
 end
 
 # store records
 if !rdb.put("foo", "hop") ||
     !rdb.put("bar", "step") ||
     !rdb.put("baz", "jump")
   ecode = rdb.ecode
   STDERR.printf("put error: %s\n", rdb.errmsg(ecode))
 end
 
 # retrieve records
 value = rdb.get("foo")
 if value
     printf("%s\n", value)
 else
   ecode = rdb.ecode
   STDERR.printf("get error: %s\n", rdb.errmsg(ecode))
 end
 
 # traverse records
 rdb.iterinit
 while key = rdb.iternext
   value = rdb.get(key)
   if value
     printf("%s:%s\n", key, value)
   end
 end
 
 # hash-like usage
 rdb["quux"] = "touchdown"
 printf("%s\n", rdb["quux"])
 rdb.each do |key, value|
   printf("%s:%s\n", key, value)
 end
 
 # close the connection
 if !rdb.close
   ecode = rdb.ecode
   STDERR.printf("close error: %s\n", rdb.errmsg(ecode))
 end

The following code is an example to use a remote database with the table extension.

 require 'tokyotyrant'
 include TokyoTyrant
 
 # create the object
 rdb = RDBTBL::new
 
 # connect to the server
 if !rdb.open("localhost", 1978)
   ecode = rdb.ecode
   STDERR.printf("open error: %s\n", rdb.errmsg(ecode))
 end
 
 # store a record
 pkey = rdb.genuid
 cols = { "name" => "mikio", "age" => "30", "lang" => "ja,en,c" }
 if !rdb.put(pkey, cols)
   ecode = rdb.ecode
   STDERR.printf("put error: %s\n", rdb.errmsg(ecode))
 end
 
 # store another record
 cols = { "name" => "falcon", "age" => "31", "lang" => "ja", "skill" => "cook,blog" }
 if !rdb.put("x12345", cols)
   ecode = rdb.ecode
   STDERR.printf("put error: %s\n", rdb.errmsg(ecode))
 end
 
 # search for records
 qry = RDBQRY::new(rdb)
 qry.addcond("age", RDBQRY::QCNUMGE, "20")
 qry.addcond("lang", RDBQRY::QCSTROR, "ja,en")
 qry.setorder("name", RDBQRY::QOSTRASC)
 qry.setlimit(10)
 res = qry.search
 res.each do |rkey|
   rcols = rdb.get(rkey)
   printf("name:%s\n", rcols["name"])
 end
 
 # close the connection
 if !rdb.close
   ecode = rdb.ecode
   STDERR.printf("close error: %s\n", rdb.errmsg(ecode))
 end


== LICENSE

 Copyright (C) 2006-2008 Mikio Hirabayashi
 All rights reserved.

Tokyo Tyrant is free software; you can redistribute it and/or modify it under the terms of the GNU Lesser General Public License as published by the Free Software Foundation; either version 2.1 of the License or any later version.  Tokyo Tyrant is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Lesser General Public License for more details.  You should have received a copy of the GNU Lesser General Public License along with Tokyo Tyrant; if not, write to the Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA.
