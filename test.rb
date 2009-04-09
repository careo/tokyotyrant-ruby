#! /usr/bin/ruby

require 'rbconfig'

commands = [

            "tcrtest.rb write 127.0.0.1 10000",
            "tcrtest.rb read 127.0.0.1",
            "tcrtest.rb remove 127.0.0.1",
            "tcrtest.rb rcat 127.0.0.1 1000",
            "tcrtest.rb rcat -shl 10 127.0.0.1 1000",
            "tcrtest.rb rcat -dai 127.0.0.1 1000",
            "tcrtest.rb rcat -ext put 127.0.0.1 1000",
            "tcrtest.rb misc 127.0.0.1 1000",
           ]
rubycmd = Config::CONFIG["bindir"] + "/" + RbConfig::CONFIG['ruby_install_name']
num = 1
commands.each do |command|
  rv = system("#{rubycmd} #{command} >/dev/null")
  if rv
    printf("%03d/%03d: %s: ok\n", num, commands.size, command)
  else
    printf("%03d/%03d: %s: failed\n", num, commands.size, command)
    exit(1)
  end
  num += 1
end
printf("all ok\n")

system("rm -rf casket")
