#--
# Pure Ruby interface of Tokyo Cabinet
#                                                       Copyright (C) 2006-2008 Mikio Hirabayashi
#  This file is part of Tokyo Cabinet.
#  Tokyo Cabinet is free software; you can redistribute it and/or modify it under the terms of
#  the GNU Lesser General Public License as published by the Free Software Foundation; either
#  version 2.1 of the License or any later version.  Tokyo Cabinet is distributed in the hope
#  that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Lesser General Public
#  License for more details.
#  You should have received a copy of the GNU Lesser General Public License along with Tokyo
#  Cabinet; if not, write to the Free Software Foundation, Inc., 59 Temple Place, Suite 330,
#  Boston, MA 02111-1307 USA.
#++
#:include:overview.rd


require "socket"


module TokyoTyrant
  # Remote database is a set of interfaces to use an abstract database of Tokyo Cabinet, mediated by a server of Tokyo Tyrant.  Before operations to store or retrieve records, it is necessary to connect the remote database object to the server.  The method `open' is used to open a database connection and the method `close' is used to close the connection.%%
  class RDB
    #--------------------------------
    # constants
    #--------------------------------
    public
    # error code: success
    ESUCCESS = 0
    # error code: invalid operation
    EINVALID = 1
    # error code: host not found
    ENOHOST = 2
    # error code: connection refused
    EREFUSED = 3
    # error code: send error
    ESEND = 4
    # error code: recv error
    ERECV = 5
    # error code: existing record
    EKEEP = 6
    # error code: no record found
    ENOREC = 7
    # error code: miscellaneous error
    EMISC = 9999
    # scripting extension option: record locking
    XOLCKREC = 1 << 0
    # scripting extension option: global locking
    XOLCKGLB = 1 << 1
    # versatile function option: omission of the update log
    MONOULOG = 1 << 0
    #--------------------------------
    # public methods
    #--------------------------------
    public
    # Create a remote database object.%%
    # The return value is the new remote database object.%%
    def initialize()
      @ecode = ESUCCESS
      @sock = nil
    end
    # Get the message string corresponding to an error code.%%
    # `<i>ecode</i>' specifies the error code.  If it is not defined or negative, the last happened error code is specified.%%
    # The return value is the message string of the error code.%%
    def errmsg(ecode = nil)
      ecode = @ecode if !ecode
      if ecode == ESUCCESS
        return "success"
      elsif ecode == EINVALID
        return "invalid operation"
      elsif ecode == ENOHOST
        return "host not found"
      elsif ecode == EREFUSED
        return "connection refused"
      elsif ecode == ESEND
        return "send error"
      elsif ecode == ERECV
        return "recv error"
      elsif ecode == EKEEP
        return "existing record"
      elsif ecode == ENOREC
        return "no record found"
      elsif ecode == EMISC
        return "miscellaneous error"
      end
      return "unknown"
    end
    # Get the last happened error code.%%
    # The return value is the last happened error code.%%
    # The following error code is defined: `TokyoTyrant::RDB::ESUCCESS' for success, `TokyoTyrant::RDB::EINVALID' for invalid operation, `TokyoTyrant::RDB::ENOHOST' for host not found, `TokyoTyrant::RDB::EREFUSED' for connection refused, `TokyoTyrant::RDB::ESEND' for send error, `TokyoTyrant::RDB::ERECV' for recv error, `TokyoTyrant::RDB::EKEEP' for existing record, `TokyoTyrant::RDB::ENOREC' for no record found, `TokyoTyrant::RDB::EMISC' for miscellaneous error.%%
    def ecode()
      return @ecode
    end
    # Open a remote database connection.%%
    # `<i>host</i>' specifies the name or the address of the server.%%
    # `<i>port</i>' specifies the port number.  If it is not defined or not more than 0, UNIX domain socket is used and the path of the socket file is specified by the host parameter.%%
    # If successful, the return value is true, else, it is false.%%
    def open(host, port = 0)
      host = _argstr(host)
      port = _argnum(port)
      if @sock
        @ecode = EINVALID
        return false
      end
      if port > 0
        begin
          info = TCPSocket.gethostbyname(host)
        rescue Exception
          @ecode = ENOHOST
          return false
        end
        begin
          sock = TCPSocket.open(info[3], port)
        rescue Exception
          @ecode = EREFUSED
          return false
        end
      else
        begin
          sock = UNIXSocket.open(host)
        rescue Exception
          @ecode = EREFUSED
          return false
        end
      end
      @sock = sock
      return true
    end
    # Close the database connection.%%
    # If successful, the return value is true, else, it is false.%%
    def close()
      if !@sock
        @ecode = EINVALID
        return false
      end
      begin
        @sock.close
      rescue Exception
        @ecode = EMISC
        @sock = nil
        return false
      end
      @sock = nil
      return true
    end
    # Store a record.%%
    # `<i>key</i>' specifies the key.%%
    # `<i>value</i>' specifies the value.%%
    # If successful, the return value is true, else, it is false.%%
    # If a record with the same key exists in the database, it is overwritten.%%
    def put(key, value)
      key = _argstr(key)
      value = _argstr(value)
      if !@sock
        @ecode = EINVALID
        return false
      end
      sbuf = [0xC8, 0x10, key.length, value.length].pack("CCNN")
      sbuf += key + value
      if !_send(sbuf)
        @ecode = ESEND
        return false
      end
      code = _recvcode
      if code == -1
        @ecode = ERECV
        return false
      end
      if code != 0
        @ecode = EMISC
        return false
      end
      return true
    end
    # Store a new record.%%
    # `<i>key</i>' specifies the key.%%
    # `<i>value</i>' specifies the value.%%
    # If successful, the return value is true, else, it is false.%%
    # If a record with the same key exists in the database, this method has no effect.%%
    def putkeep(key, value)
      key = _argstr(key)
      value = _argstr(value)
      if !@sock
        @ecode = EINVALID
        return false
      end
      sbuf = [0xC8, 0x11, key.length, value.length].pack("CCNN")
      sbuf += key + value
      if !_send(sbuf)
        @ecode = ESEND
        return false
      end
      code = _recvcode
      if code == -1
        @ecode = ERECV
        return false
      end
      if code != 0
        @ecode = EKEEP
        return false
      end
      return true
    end
    # Concatenate a value at the end of the existing record.%%
    # `<i>key</i>' specifies the key.%%
    # `<i>value</i>' specifies the value.%%
    # If successful, the return value is true, else, it is false.%%
    # If there is no corresponding record, a new record is created.%%
    def putcat(key, value)
      key = _argstr(key)
      value = _argstr(value)
      if !@sock
        @ecode = EINVALID
        return false
      end
      sbuf = [0xC8, 0x12, key.length, value.length].pack("CCNN")
      sbuf += key + value
      if !_send(sbuf)
        @ecode = ESEND
        return false
      end
      code = _recvcode
      if code == -1
        @ecode = ERECV
        return false
      end
      if code != 0
        @ecode = EMISC
        return false
      end
      return true
    end
    # Concatenate a value at the end of the existing record and shift it to the left.%%
    # `<i>key</i>' specifies the key.%%
    # `<i>value</i>' specifies the value.%%
    # `<i>width</i>' specifies the width of the record.%%
    # If successful, the return value is true, else, it is false.%%
    # If there is no corresponding record, a new record is created.%%
    def putshl(key, value, width = 0)
      key = _argstr(key)
      value = _argstr(value)
      width = _argnum(width)
      if !@sock
        @ecode = EINVALID
        return false
      end
      sbuf = [0xC8, 0x13, key.length, value.length, width].pack("CCNNN")
      sbuf += key + value
      if !_send(sbuf)
        @ecode = ESEND
        return false
      end
      code = _recvcode
      if code == -1
        @ecode = ERECV
        return false
      end
      if code != 0
        @ecode = EMISC
        return false
      end
      return true
    end
    # Store a record without response from the server.%%
    # `<i>key</i>' specifies the key.%%
    # `<i>value</i>' specifies the value.%%
    # If successful, the return value is true, else, it is false.%%
    # If a record with the same key exists in the database, it is overwritten.%%
    def putnr(key, value)
      key = _argstr(key)
      value = _argstr(value)
      if !@sock
        @ecode = EINVALID
        return false
      end
      sbuf = [0xC8, 0x18, key.length, value.length].pack("CCNN")
      sbuf += key + value
      if !_send(sbuf)
        @ecode = ESEND
        return false
      end
      return true
    end
    # Remove a record.%%
    # `<i>key</i>' specifies the key.%%
    # If successful, the return value is true, else, it is false.%%
    def out(key)
      key = _argstr(key)
      if !@sock
        @ecode = EINVALID
        return false
      end
      sbuf = [0xC8, 0x20, key.length].pack("CCN")
      sbuf += key
      if !_send(sbuf)
        @ecode = ESEND
        return false
      end
      code = _recvcode
      if code == -1
        @ecode = ERECV
        return false
      end
      if code != 0
        @ecode = ENOREC
        return false
      end
      return true
    end
    # Retrieve a record.%%
    # `<i>key</i>' specifies the key.%%
    # If successful, the return value is the value of the corresponding record.  `nil' is returned if no record corresponds.%%
    def get(key)
      key = _argstr(key)
      sbuf = [0xC8, 0x30, key.length].pack("CCN")
      sbuf += key
      if !_send(sbuf)
        @ecode = ESEND
        return nil
      end
      code = _recvcode
      if code == -1
        @ecode = ERECV
        return nil
      end
      if code != 0
        @ecode = ENOREC
        return nil
      end
      vsiz = _recvint32
      if vsiz < 0
        @ecode = ERECV
        return nil
      end
      vbuf = _recv(vsiz)
      if !vbuf
        @ecode = ERECV
        return nil
      end
      return vbuf
    end
    # Retrieve records.%%
    # `<i>recs</i>' specifies a hash containing the retrieval keys.  As a result of this method, keys existing in the database have the corresponding values and keys not existing in the database are removed.%%
    # If successful, the return value is the number of retrieved records or -1 on failure.%%
    def mget(recs)
      raise ArgumentError if !recs.is_a?(Hash)
      if !@sock
        @ecode = EINVALID
        return -1
      end
      rnum = 0
      sbuf = ""
      recs.each_pair do |key, value|
        key = _argstr(key)
        sbuf += [key.length].pack("N") + key
        rnum += 1
      end
      sbuf = [0xC8, 0x31, rnum].pack("CCN") + sbuf
      if !_send(sbuf)
        @ecode = ESEND
        return -1
      end
      code = _recvcode
      rnum = _recvint32
      if code == -1
        @ecode = ERECV
        return -1
      end
      if code != 0
        @ecode = ENOREC
        return -1
      end
      if rnum < 0
        @ecode = ERECV
        return -1
      end
      recs.clear
      for i in 1..rnum
        ksiz = _recvint32()
        vsiz = _recvint32()
        if ksiz < 0 || vsiz < 0
          @ecode = ERECV
          return -1
        end
        kbuf = _recv(ksiz)
        vbuf = _recv(vsiz)
        if !kbuf || !vbuf
          @ecode = ERECV
          return -1
        end
        recs[kbuf] = vbuf
      end
      return rnum
    end
    # Get the size of the value of a record.%%
    # `<i>key</i>' specifies the key.%%
    # If successful, the return value is the size of the value of the corresponding record, else, it is -1.%%
    def vsiz(key)
      key = _argstr(key)
      if !@sock
        @ecode = EINVALID
        return -1
      end
      sbuf = [0xC8, 0x38, key.length].pack("CCN")
      sbuf += key
      if !_send(sbuf)
        @ecode = ESEND
        return -1
      end
      code = _recvcode
      if code == -1
        @ecode = ERECV
        return -1
      end
      if code != 0
        @ecode = ENOREC
        return -1
      end
      return _recvint32
    end
    # Initialize the iterator.%%
    # If successful, the return value is true, else, it is false.%%
    # The iterator is used in order to access the key of every record stored in a database.%%
    def iterinit()
      if !@sock
        @ecode = EINVALID
        return false
      end
      sbuf = [0xC8, 0x50].pack("CC")
      if !_send(sbuf)
        @ecode = ESEND
        return false
      end
      code = _recvcode
      if code == -1
        @ecode = ERECV
        return false
      end
      if code != 0
        @ecode = EMISC
        return false
      end
      return true
    end
    # Get the next key of the iterator.%%
    # If successful, the return value is the next key, else, it is `nil'.  `nil' is returned when no record is to be get out of the iterator.%%
    # It is possible to access every record by iteration of calling this method.  It is allowed to update or remove records whose keys are fetched while the iteration.  However, it is not assured if updating the database is occurred while the iteration.  Besides, the order of this traversal access method is arbitrary, so it is not assured that the order of storing matches the one of the traversal access.%%
    def iternext()
      if !@sock
        @ecode = EINVALID
        return nil
      end
      sbuf = [0xC8, 0x51].pack("CC")
      if !_send(sbuf)
        @ecode = ESEND
        return nil
      end
      code = _recvcode
      if code == -1
        @ecode = ERECV
        return nil
      end
      if code != 0
        @ecode = ENOREC
        return nil
      end
      vsiz = _recvint32
      if vsiz < 0
        @ecode = ERECV
        return nil
      end
      vbuf = _recv(vsiz)
      if !vbuf
        @ecode = ERECV
        return nil
      end
      return vbuf
    end
    # Get forward matching keys.%%
    # `<i>prefix</i>' specifies the prefix of the corresponding keys.%%
    # `<i>max</i>' specifies the maximum number of keys to be fetched.  If it is not defined or negative, no limit is specified.%%
    # The return value is an array of the keys of the corresponding records.  This method does never fail and return an empty array even if no record corresponds.%%
    # Note that this method may be very slow because every key in the database is scanned.%%
    def fwmkeys(prefix, max = -1)
      prefix = _argstr(prefix)
      max = _argnum(max)
      if !@sock
        @ecode = EINVALID
        return Array.new
      end
      sbuf = [0xC8, 0x58, prefix.length, max].pack("CCNN")
      sbuf += prefix
      if !_send(sbuf)
        @ecode = ESEND
        return Array.new
      end
      code = _recvcode
      if code == -1
        @ecode = ERECV
        return Array.new
      end
      if code != 0
        @ecode = ENOREC
        return Array.new
      end
      knum = _recvint32
      if knum < 0
        @ecode = ERECV
        return Array.new
      end
      keys = Array.new
      for i in 1..knum
        ksiz = _recvint32()
        if ksiz < 0
          @ecode = ERECV
          return Array.new
        end
        kbuf = _recv(ksiz)
        if !kbuf
          @ecode = ERECV
          return Array.new
        end
        keys.push(kbuf)
      end
      return keys
    end
    # Add an integer to a record.%%
    # `<i>key</i>' specifies the key.%%
    # `<i>num</i>' specifies the additional value.  If it is not defined, 0 is specified.%%
    # If successful, the return value is the summation value, else, it is `nil'.%%
    # If the corresponding record exists, the value is treated as an integer and is added to.  If no record corresponds, a new record of the additional value is stored.  Because records are stored in binary format, they should be processed with the `unpack' function with the `i' operator after retrieval.%%
    def addint(key, num = 0)
      key = _argstr(key)
      num = _argnum(num)
      if !@sock
        @ecode = EINVALID
        return nil
      end
      sbuf = [0xC8, 0x60, key.length, num].pack("CCNN")
      sbuf += key
      if !_send(sbuf)
        @ecode = ESEND
        return nil
      end
      code = _recvcode
      if code == -1
        @ecode = ERECV
        return nil
      end
      if code != 0
        @ecode = EKEEP
        return nil
      end
      return _recvint32
    end
    # Add a real number to a record.%%
    # `<i>key</i>' specifies the key.%%
    # `<i>num</i>' specifies the additional value.  If it is not defined, 0 is specified.%%
    # If successful, the return value is the summation value, else, it is `nil'.%%
    # If the corresponding record exists, the value is treated as a real number and is added to.  If no record corresponds, a new record of the additional value is stored.  Because records are stored in binary format, they should be processed with the `unpack' function with the `d' operator after retrieval.%%
    def adddouble(key, num)
      key = _argstr(key)
      num = _argnum(num)
      if !@sock
        @ecode = EINVALID
        return nil
      end
      integ = num.truncate
      fract = ((num - integ) * 1000000000000).truncate
      sbuf = [0xC8, 0x61, key.length].pack("CCN")
      sbuf += _packquad(integ) + _packquad(fract) + key
      if !_send(sbuf)
        @ecode = ESEND
        return nil
      end
      code = _recvcode
      if code == -1
        @ecode = ERECV
        return nil
      end
      if code != 0
        @ecode = EKEEP
        return nil
      end
      integ = _recvint64()
      fract = _recvint64()
      return integ + fract / 1000000000000.0
    end
    # Call a function of the script language extension.%%
    # `<i>name</i>' specifies the function name.%%
    # `<i>key</i>' specifies the key.  If it is not defined, an empty string is specified.%%
    # `<i>value</i>' specifies the value.  If it is not defined, an empty string is specified.%%
    # `<i>opts</i>' specifies options by bitwise or: `TokyoTyrant::RDB::XOLCKREC' for record locking, `TokyoTyrant::RDB::XOLCKGLB' for global locking.  If it is not defined, no option is specified.%%
    # If successful, the return value is the value of the response or `nil' on failure.%%
    def ext(name, key = "", value = "", opts = 0)
      name = _argstr(name)
      key = _argstr(key)
      value = _argstr(value)
      opts = _argnum(opts)
      if !@sock
        @ecode = EINVALID
        return nil
      end
      sbuf = [0xC8, 0x68, name.length, opts, key.length, value.length].pack("CCNNNN")
      sbuf += name + key + value
      if !_send(sbuf)
        @ecode = ESEND
        return nil
      end
      code = _recvcode
      if code == -1
        @ecode = ERECV
        return nil
      end
      if code != 0
        @ecode = EMISC
        return nil
      end
      vsiz = _recvint32
      if vsiz < 0
        @ecode = ERECV
        return nil
      end
      vbuf = _recv(vsiz)
      if !vbuf
        @ecode = ERECV
        return nil
      end
      return vbuf
    end
    # Synchronize updated contents with the file and the device.%%
    # If successful, the return value is true, else, it is false.%%
    def sync()
      if !@sock
        @ecode = EINVALID
        return false
      end
      sbuf = [0xC8, 0x70].pack("CC")
      if !_send(sbuf)
        @ecode = ESEND
        return false
      end
      code = _recvcode
      if code == -1
        @ecode = ERECV
        return false
      end
      if code != 0
        @ecode = EMISC
        return false
      end
      return true
    end
    # Remove all records.%%
    # If successful, the return value is true, else, it is false.%%
    def vanish()
      if !@sock
        @ecode = EINVALID
        return false
      end
      sbuf = [0xC8, 0x71].pack("CC")
      if !_send(sbuf)
        @ecode = ESEND
        return false
      end
      code = _recvcode
      if code == -1
        @ecode = ERECV
        return false
      end
      if code != 0
        @ecode = EMISC
        return false
      end
      return true
    end
    # Copy the database file.%%
    # `<i>path</i>' specifies the path of the destination file.  If it begins with `@', the trailing substring is executed as a command line.%%
    # If successful, the return value is true, else, it is false.  False is returned if the executed command returns non-zero code.%%
    # The database file is assured to be kept synchronized and not modified while the copying or executing operation is in progress.  So, this method is useful to create a backup file of the database file.%%
    def copy(path)
      path = _argstr(path)
      if !@sock
        @ecode = EINVALID
        return false
      end
      sbuf = [0xC8, 0x72, path.length].pack("CCN")
      sbuf += path
      if !_send(sbuf)
        @ecode = ESEND
        return false
      end
      code = _recvcode
      if code == -1
        @ecode = ERECV
        return false
      end
      if code != 0
        @ecode = EMISC
        return false
      end
      return true
    end
    # Get the number of records.%%
    # The return value is the number of records or 0 if the object does not connect to any database server.%%
    def rnum()
      if !@sock
        @ecode = EINVALID
        return 0
      end
      sbuf = [0xC8, 0x80].pack("CC")
      if !_send(sbuf)
        @ecode = ESEND
        return 0
      end
      code = _recvcode
      if code == -1
        @ecode = ERECV
        return 0
      end
      if code != 0
        @ecode = EMISC
        return 0
      end
      return _recvint64
    end
    # Get the size of the database.%%
    # The return value is the size of the database or 0 if the object does not connect to any database server.%%
    def size()
      if !@sock
        @ecode = EINVALID
        return 0
      end
      sbuf = [0xC8, 0x81].pack("CC")
      if !_send(sbuf)
        @ecode = ESEND
        return 0
      end
      code = _recvcode
      if code == -1
        @ecode = ERECV
        return 0
      end
      if code != 0
        @ecode = EMISC
        return 0
      end
      return _recvint64
    end
    # Get the status string of the database server.%%
    # The return value is the status message of the database or `nil' if the object does not connect to any database server.  The message format is TSV.  The first field of each line means the parameter name and the second field means the value.%%
    def stat()
      if !@sock
        @ecode = EINVALID
        return nil
      end
      sbuf = [0xC8, 0x88].pack("CC")
      if !_send(sbuf)
        @ecode = ESEND
        return nil
      end
      code = _recvcode
      if code == -1
        @ecode = ERECV
        return nil
      end
      if code != 0
        @ecode = ENOREC
        return nil
      end
      ssiz = _recvint32
      if ssiz < 0
        @ecode = ERECV
        return nil
      end
      sbuf = _recv(ssiz)
      if !sbuf
        @ecode = ERECV
        return nil
      end
      return sbuf
    end
    # Call a versatile function for miscellaneous operations.%%
    # `<i>name</i>' specifies the name of the function.  All databases support "putlist", "outlist", and "getlist".  "putlist" is to store records.  It receives keys and values one after the other, and returns an empty list.  "outlist" is to remove records.  It receives keys, and returns an empty array.  "getlist" is to retrieve records.  It receives keys, and returns keys and values of corresponding records one after the other.  Table database supports "setindex", "search", and "genuid".%%
    # `<i>args</i>' specifies an array containing arguments.  If it is not defined, no argument is specified.%%
    # `<i>opts</i>' specifies options by bitwise or: `TokyoTyrant::RDB::MONOULOG' for omission of the update log.  If it is not defined, no option is specified.%%
    # If successful, the return value is an array of the result.  `nil' is returned on failure.%%
    def misc(name, args = [], opts = 0)
      name = _argstr(name)
      args = Array.new if !args.is_a?(Array)
      opts = _argnum(opts)
      if !@sock
        @ecode = EINVALID
        return nil
      end
      sbuf = [0xC8, 0x90, name.length, opts, args.size].pack("CCNNN")
      sbuf += name
      args.each do |arg|
        arg = _argstr(arg)
        sbuf += [arg.length].pack("N") + arg
      end
      if !_send(sbuf)
        @ecode = ESEND
        return nil
      end
      code = _recvcode
      rnum = _recvint32
      if code == -1
        @ecode = ERECV
        return nil
      end
      if code != 0
        @ecode = EMISC
        return nil
      end
      res = Array.new
      for i in 1..rnum
        esiz = _recvint32
        if esiz < 0
          @ecode = ERECV
          return nil
        end
        ebuf = _recv(esiz)
        if !ebuf
          @ecode = ERECV
          return nil
        end
        res.push(ebuf)
      end
      return res
    end
    #--------------------------------
    # aliases and iterators
    #--------------------------------
    public
    # Hash-compatible method.%%
    # Alias of `put'.%%
    def store(key, value)
      return put(key, value)
    end
    # Hash-compatible method.%%
    # Alias of `out'.%%
    def delete(key)
      return out(key)
    end
    # Hash-compatible method.%%
    # Alias of `get'.%%
    def fetch(key)
      return out(key)
    end
    # Hash-compatible method.%%
    # Check existence of a key.%%
    def has_key?(key)
      return vsiz(key) >= 0
    end
    # Hash-compatible method.%%
    # Check existence of a value.%%
    def has_value?(value)
      return nil if !iterinit
      while tkey = iternext
        tvalue = get(tkey)
        break if !tvalue
        return true if value == tvalue
      end
      return false
    end
    # Hash-compatible method.%%
    # Alias of `vanish'.%%
    def clear
      return vanish
    end
    # Hash-compatible method.%%
    # Alias of `rnum'.%%
    def length
      return rnum
    end
    # Hash-compatible method.%%
    # Alias of `rnum > 0'.%%
    def empty?
      return rnum > 0
    end
    # Hash-compatible method.%%
    # Alias of `put'.%%
    def []=(key, value)
      return put(key, value)
    end
    # Hash-compatible method.%%
    # Alias of `get'.%%
    def [](key)
      return get(key)
    end
    # Hash-compatible method.%%
    # Iterator of pairs of the key and the value.%%
    def each
      return nil if !iterinit
      while key = iternext
        value = get(key)
        break if !value
        yield(key, value)
      end
      return nil
    end
    alias each_pair each
    # Hash-compatible method.%%
    # Iterator of the keys.%%
    def each_keys
      return nil if !iterinit
      while key = iternext
        yield(key)
      end
      return nil
    end
    # Hash-compatible method.%%
    # Iterator of the values.%%
    def each_values
      return nil if !iterinit
      while key = iternext
        value = get(key)
        break if !value
        yield(value)
      end
      return nil
    end
    # Hash-compatible method.%%
    # Get an array of all keys.%%
    def keys
      tkeys = Array.new
      return tkeys if !iterinit
      while key = iternext
        tkeys.push(key)
      end
      return tkeys
    end
    # Hash-compatible method.%%
    # Get an array of all keys.%%
    def values
      tvals = Array.new
      return tvals if !iterinit
      while key = iternext
        value = get(key)
        break if !value
        tvals.push(value)
      end
      return tvals
    end
    #--------------------------------
    # private methods
    #--------------------------------
    private
    # Get a string argument.%%
    def _argstr(obj)
      return obj.to_s if obj.is_a?(Numeric)
      return obj if obj.is_a?(String)
      raise ArgumentError
    end
    # Get a numeric argument.%%
    def _argnum(obj)
      return obj.to_i if obj.is_a?(String)
      return obj if obj.is_a?(Numeric)
      raise ArgumentError
    end
    # Send a series of data.%%
    def _send(buf)
      begin
        @sock.send(buf, 0)
      rescue Exception
        return false
      end
      return true
    end
    # Receive a series of data.%%
    def _recv(len)
      return "" if len < 1
      begin
        str = @sock.recv(len, 0)
        len -= str.length
        while len > 0
          tstr = @sock.recv(len, 0)
          len -= tstr.length
          str += tstr
        end
        return str
      rescue Exception
        return nil
      end
    end
    # Receive a byte code.%%
    def _recvcode()
      rbuf = _recv(1)
      return -1 if !rbuf
      return rbuf.unpack("C")[0]
    end
    # Receive an int32 number.%%
    def _recvint32()
      rbuf = _recv(4)
      return -1 if !rbuf
      num = rbuf.unpack("N")[0]
      return [num].pack("l").unpack("l")[0]
    end
    # Receive an int64 number.%%
    def _recvint64()
      rbuf = _recv(8)
      return -1 if !rbuf
      high, low = rbuf.unpack("NN")
      num = (high << 32) + low
      return [num].pack("q").unpack("q")[0]
    end
    # Pack an int64 value.%%
    def _packquad(num)
      high = (num / (1 << 32)).truncate
      low = num % (1 << 32)
      return [high, low].pack("NN")
    end
  end
  # This class inherits the class "TokyoTyrant::RDB".  All methods are specific to servers of the table database.%%
  class RDBTBL < RDB
    #--------------------------------
    # constants
    #--------------------------------
    public
    # index type: lexical string
    ITLEXICAL = 0
    # index type: decimal string
    ITDECIMAL = 1
    # index type: void
    ITVOID = 9999
    # index type: keep existing index
    ITKEEP = 1 << 24
    #--------------------------------
    # public methods
    #--------------------------------
    public
    # Store a record.%%
    # `<i>pkey</i>' specifies the primary key.%%
    # `<i>cols</i>' specifies a hash containing columns.%%
    # If successful, the return value is true, else, it is false.%%
    # If a record with the same key exists in the database, it is overwritten.%%
    def put(pkey, cols)
      pkey = _argstr(pkey)
      raise ArgumentError if !cols.is_a?(Hash)
      args = Array.new
      args.push(pkey)
      cols.each do |ckey, cvalue|
        args.push(ckey)
        args.push(cvalue)
      end
      rv = misc("put", args, 0)
      return rv ? true : false
    end
    # Store a new record.%%
    # `<i>pkey</i>' specifies the primary key.%%
    # `<i>cols</i>' specifies a hash containing columns.%%
    # If successful, the return value is true, else, it is false.%%
    # If a record with the same key exists in the database, this method has no effect.%%
    def putkeep(pkey, cols)
      pkey = _argstr(pkey)
      raise ArgumentError if !cols.is_a?(Hash)
      args = Array.new
      args.push(pkey)
      cols.each do |ckey, cvalue|
        args.push(ckey)
        args.push(cvalue)
      end
      rv = misc("putkeep", args, 0)
      return rv ? true : false
    end
    # Concatenate columns of the existing record.%%
    # `<i>pkey</i>' specifies the primary key.%%
    # `<i>cols</i>' specifies a hash containing columns.%%
    # If successful, the return value is true, else, it is false.%%
    # If there is no corresponding record, a new record is created.%%
    def putcat(pkey, cols)
      pkey = _argstr(pkey)
      raise ArgumentError if !cols.is_a?(Hash)
      args = Array.new
      args.push(pkey)
      cols.each do |ckey, cvalue|
        args.push(ckey)
        args.push(cvalue)
      end
      rv = misc("putcat", args, 0)
      return rv ? true : false
    end
    # Remove a record.%%
    # `<i>pkey</i>' specifies the primary key.%%
    # If successful, the return value is true, else, it is false.%%
    def out(pkey)
      pkey = _argstr(pkey)
      return super(pkey)
    end
    # Retrieve a record.%%
    # `<i>pkey</i>' specifies the primary key.%%
    # If successful, the return value is a hash of the columns of the corresponding record.  `nil' is returned if no record corresponds.%%
    def get(pkey)
      pkey = _argstr(pkey)
      args = Array.new
      args.push(pkey)
      rv = misc("get", args)
      return nil if !rv
      cols = Hash.new()
      cnum = rv.length
      cnum -= 1
      i = 0
      while i < cnum
        cols[rv[i]] = rv[i+1]
        i += 2
      end
      return cols
    end
    # Retrieve records.%%
    # `<i>recs</i>' specifies a hash containing the retrieval keys.  As a result of this method, keys existing in the database have the corresponding columns and keys not existing in the database are removed.%%
    # If successful, the return value is the number of retrieved records or -1 on failure.%%
    # Due to the protocol restriction, this method can not handle records with binary columns including the "\0" chracter.%%
    def mget(recs)
      rv = super(recs)
      return -1 if rv < 0
      recs.each do |pkey, value|
        cols = Hash.new
        cary = value.split("\0")
        cnum = cary.size - 1
        i = 0
        while i < cnum
          cols[cary[i]] = cary[i+1]
          i += 2
        end
        recs[pkey] = cols
      end
      return rv
    end
    # Set a column index.%%
    # `<i>name</i>' specifies the name of a column.  If the name of an existing index is specified, the index is rebuilt.  An empty string means the primary key.%%
    # `<i>type</i>' specifies the index type: `TokyoCabinet::RDBTBL::ITLEXICAL' for lexical string, `TokyoCabinet::RDBTBL::ITDECIMAL' for decimal string.  If it is `TokyoCabinet::RDBTBL::ITVOID', the index is removed.  If `TokyoCabinet::RDBTBL::ITKEEP' is added by bitwise or and the index exists, this method merely returns failure.%%
    # If successful, the return value is true, else, it is false.%%
    def setindex(name, type)
      name = _argstr(name)
      type = _argnum(type)
      args = Array.new
      args.push(name)
      args.push(type)
      rv = misc("setindex", args, 0)
      return rv ? true : false
    end
    # Generate a unique ID number.%%
    # The return value is the new unique ID number or -1 on failure.%%
    def genuid()
      rv = misc("genuid", Array.new, 0)
      return -1 if !rv
      return rv[0]
    end
  end
  # This class is a helper for the class "TokyoTyrant::RDBTBL".%%
  class RDBQRY
    # query condition: string is equal to
    QCSTREQ = 0
    # query condition: string is included in
    QCSTRINC = 1
    # query condition: string begins with
    QCSTRBW = 2
    # query condition: string ends with
    QCSTREW = 3
    # query condition: string includes all tokens in
    QCSTRAND = 4
    # query condition: string includes at least one token in
    QCSTROR = 5
    # query condition: string is equal to at least one token in
    QCSTROREQ = 6
    # query condition: string matches regular expressions of
    QCSTRRX = 7
    # query condition: number is equal to
    QCNUMEQ = 8
    # query condition: number is greater than
    QCNUMGT = 9
    # query condition: number is greater than or equal to
    QCNUMGE = 10
    # query condition: number is less than
    QCNUMLT = 11
    # query condition: number is less than or equal to
    QCNUMLE = 12
    # query condition: number is between two tokens of
    QCNUMBT = 13
    # query condition: number is equal to at least one token in
    QCNUMOREQ = 14
    # query condition: negation flag
    QCNEGATE = 1 << 24
    # query condition: no index flag
    QCNOIDX = 1 << 25
    # order type: string ascending
    QOSTRASC = 0
    # order type: string descending
    QOSTRDESC = 1
    # order type: number ascending
    QONUMASC = 2
    # order type: number descending
    QONUMDESC = 3
    # Create a query object.%%
    # `<i>rdb</i>' specifies the remote database object.%%
    # The return value is the new query object.%%
    def initialize(rdb)
      raise ArgumentError if !rdb.is_a?(TokyoTyrant::RDBTBL)
      @rdb = rdb
      @args = Array.new
    end
    # Add a narrowing condition.%%
    # `<i>name</i>' specifies the name of a column.  An empty string means the primary key.%%
    # `<i>op</i>' specifies an operation type: `TokyoCabinet::RDBQRY::QCSTREQ' for string which is equal to the expression, `TokyoCabinet::RDBQRY::QCSTRINC' for string which is included in the expression, `TokyoCabinet::RDBQRY::QCSTRBW' for string which begins with the expression, `TokyoCabinet::RDBQRY::QCSTREW' for string which ends with the expression, `TokyoCabinet::RDBQRY::QCSTRAND' for string which includes all tokens in the expression, `TokyoCabinet::RDBQRY::QCSTROR' for string which includes at least one token in the expression, `TokyoCabinet::RDBQRY::QCSTROREQ' for string which is equal to at least one token in the expression, `TokyoCabinet::RDBQRY::QCSTRRX' for string which matches regular expressions of the expression, `TokyoCabinet::RDBQRY::QCNUMEQ' for number which is equal to the expression, `TokyoCabinet::RDBQRY::QCNUMGT' for number which is greater than the expression, `TokyoCabinet::RDBQRY::QCNUMGE' for number which is greater than or equal to the expression, `TokyoCabinet::RDBQRY::QCNUMLT' for number which is less than the expression, `TokyoCabinet::RDBQRY::QCNUMLE' for number which is less than or equal to the expression, `TokyoCabinet::RDBQRY::QCNUMBT' for number which is between two tokens of the expression, `TokyoCabinet::RDBQRY::QCNUMOREQ' for number which is equal to at least one token in the expression.  All operations can be flagged by bitwise or: `TokyoCabinet::RDBQRY::QCNEGATE' for negation, `TokyoCabinet::RDBQRY::QCNOIDX' for using no index.%%
    # `<i>expr</i>' specifies an operand exression.%%
    # The return value is always `nil'.%%
    def addcond(name, op, expr)
      @args.push("addcond" + "\0" + name + "\0" + op.to_s + "\0" + expr)
      return nil
    end
    # Set the order of the result.%%
    # `<i>name</i>' specifies the name of a column.  An empty string means the primary key.%%
    # `<i>type</i>' specifies the order type: `TokyoCabinet::RDBQRY::QOSTRASC' for string ascending, `TokyoCabinet::RDBQRY::QOSTRDESC' for string descending, `TokyoCabinet::RDBQRY::QONUMASC' for number ascending, `TokyoCabinet::RDBQRY::QONUMDESC' for number descending.%%
    # The return value is always `nil'.%%
    def setorder(name, type)
      @args.push("setorder" + "\0" + name + "\0" + type.to_s)
      return nil
    end
    # Set the maximum number of records of the result.%%
    # `<i>max</i>' specifies the maximum number of records of the result.%%
    # The return value is always `nil'.%%
    def setmax(max)
      @args.push("setmax" + "\0" + max.to_s)
      return nil
    end
    # Execute the search.%%
    # The return value is an array of the primary keys of the corresponding records.  This method does never fail and return an empty array even if no record corresponds.%%
    def search()
      rv = @rdb.misc("search", @args, RDB::MONOULOG)
      return rv ? rv : Array.new
    end
    # Remove each corresponding record.%%
    # If successful, the return value is true, else, it is false.%%
    def searchout()
      args = Array.new(@args)
      args.push("out")
      rv = @rdb.misc("search", args, 0)
      return rv ? true : false
    end
    # Get records corresponding to the search.%%
    # `<i>names</i>' specifies an array of column names to be fetched.  An empty string means the primary key.  If it is not defined, every column is fetched.%%
    # The return value is an array of column hashes of the corresponding records.  This method does never fail and return an empty list even if no record corresponds.%%
    # Due to the protocol restriction, this method can not handle records with binary columns including the "\0" chracter.%%
    def searchget(names = nil)
      raise ArgumentError if names && !names.is_a?(Array)
      args = Array.new(@args)
      if names
        args.push("get\0" + names.join("\0"))
      else
        args.push("get")
      end
      rv = @rdb.misc("search", args, RDB::MONOULOG)
      return Array.new if !rv
      for i in 0...rv.size
        cols = Hash.new
        cary = rv[i].split("\0")
        cnum = cary.size - 1
        j = 0
        while j < cnum
          cols[cary[j]] = cary[j+1]
          j += 2
        end
        rv[i] = cols
      end
      return rv
    end
  end
end



# END OF FILE
