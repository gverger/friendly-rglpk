require 'mkmf'
require 'pathname'

ROOT_DIR = File.dirname(File.absolute_path(__FILE__))
PROG_NAME = "glpk-4.44"

TARBALL_NAME = "#{PROG_NAME}.tar.gz"
GLPK_DIR = "#{ROOT_DIR}/glpk"
# GLPK_INSTALL = "#{ROOT_DIR}/glpk_install"
# def install_glpk
#   # puts "Downloading glpk"
#   # system "curl http://ftp.gnu.org/gnu/glpk/glpk-4.44.tar.gz -O" 

#   puts "Unpacking glpk"
#   system "tar -xzf #{ROOT_DIR}/#{TARBALL_NAME}"
#   puts 
#   puts "Configuring..."

#   res = system "cd #{GLPK_DIR} && ./configure --prefix=#{GLPK_INSTALL} && make && make install"
#   if not res
#     puts "Failed to build GLPK, aborting"
#     exit 1
#   end
# end

# install_glpk
dir_config('glpk')
find_library("glpk", nil, "#{GLPK_DIR}/lib")
find_header("glpk.h", "#{GLPK_DIR}/include")

unless have_library("glpk")
  $stderr.puts "\nERROR: Cannot find the GLPK library, aborting."
  exit 1
end
unless have_header("glpk.h")
  $stderr.puts "\nERROR: Cannot find the GLPK header, aborting."
  exit 1
end
  
create_makefile('glpk_wrapper')
