require_recipe "apt"
require_recipe "apache2"
require_recipe "build-essential"
require_recipe "git"
require_recipe "mysql::server"
require_recipe "openssl"

package "apache2-mpm-prefork"
package "apache2-prefork-dev"
package "libtidy-dev"
package "curl"
package "libcurl4-openssl-dev"
package "libcurl3"
package "libcurl3-gnutls"
package "zlib1g"
package "zlib1g-dev"
package "libxslt1-dev"
package "libzip-dev"
package "libzip1"
package "libxml2"
package "libsnmp-base"
package "libsnmp15"
package "libxml2-dev"
package "libsnmp-dev"
package "libjpeg62"
package "libjpeg62-dev"
package "libpng12-0"
package "libpng12-dev"
package "libfreetype6"
package "libfreetype6-dev"
package "libbz2-1.0"
package "libbz2-dev"
package "libxpm4"
package "libxpm-dev"
package "libmcrypt-dev"
package "libmcrypt4"
package "libgd2-xpm"
package "libgd2-xpm-dev"
package "libmhash2"
package "libmhash-dev"
package "unixodbc"
package "unixodbc-dev"
package "libpcre3"
package "libpcre3-dev"
package "libpcrecpp0"

directory "/usr/local/src" do
  group "admin"
  mode 0775
end

remote_file "/usr/local/src/php-5.3.1.tar.gz" do
  source "http://www.php.net/get/php-5.3.1.tar.gz/from/this/mirror"
  checksum "85b1eb191ac328052ce88159d7f791f370de0ecda155950cb3f4ca4112f35b10"
  mode 0644
end

bash "build-php" do
  configure_flags = %w(
    --prefix="/usr"
    --with-config-file-path="/etc"
    --with-config-file-scan-dir="/etc/php.d"
    --disable-debug
    --disable-all
    --enable-rpath
    --enable-inline-optimization
    --enable-libtool-lock
    --enable-pdo
    --enable-phar
    --enable-posix
    --enable-session
    --enable-short-tags
    --enable-tokenizer
    --enable-zend-multibyte
    --enable-bcmath
    --enable-calendar
    --enable-ctype
    --enable-dba
    --with-cdb
    --enable-inifile
    --enable-flatfile
    --enable-exif
    --enable-fileinfo
    --enable-filter
    --enable-hash
    --enable-json
    --enable-mbstring
    --enable-mbregex
    --enable-mbregex-backtrack
    --with-libmbfl
    --with-mysql=mysqlnd
    --with-pdo-mysql=mysqlnd
    --with-mysqli=mysqlnd
    --with-sqlite3
    --with-pdo-sqlite
    --enable-sqlite-utf8
    --with-apxs2=/usr/bin/apxs2
    --with-tidy=/usr
    --with-curl=/usr/bin
    --with-curlwrappers
    --with-openssl-dir=/usr
    --with-zlib-dir=/usr
    --with-xpm-dir=/usr
    --with-xsl=/usr
    --with-ldap
    --enable-xml
    --with-libxml-dir=/usr
    --enable-libxml
    --enable-dom
    --enable-simplexml
    --enable-xmlreader
    --enable-xmlwriter
    --with-iconv-dir=/usr
    --with-snmp=/usr
    --with-bz2=/usr
    --with-mcrypt=/usr
    --with-mhash=/usr
    --with-gd
    --with-jpeg-dir=/usr
    --with-png-dir=/usr
    --with-freetype-dir=/usr
    --enable-zip
    --with-pear
  ).join(' ')
  
  cwd "/usr/local/src"
  code <<-EOH
  tar xfz php-5.3.1.tar.gz
  rm php-5.3.1.tar.gz
  cd php-5.3.1 && ./configure #{configure_flags}
  make -j4
  EOH
  not_if { File.exists?("/usr/local/src/php-5.3.1/libs/libphp5.so") }
end

bash "install-php-files" do
  cwd "/usr/local/src/php-5.3.1"
  code "sudo make install-cli install-build install-headers install-programs install-pear install-pharcmd"
  not_if { File.exists?("/usr/bin/php") }
end

bash "install-php-apache-module" do
  code "sudo cp /usr/local/src/php-5.3.1/libs/libphp5.so /usr/lib/apache2/modules/libphp5.so"
  not_if { File.exists?("/usr/lib/apache2/modules/libphp5.so") }
end

file "/usr/lib/apache2/modules/libphp5.so" do
  owner node[:apache][:user]
  mode 0644
end

remote_file "/etc/php.ini" do
  source "php53.ini"
  owner "root"
  group "root"
  mode 0644
  notifies :restart, resources(:service => "apache2"), :delayed
end

template "#{node[:apache][:dir]}/mods-available/php53.load" do
  source "mods/php53.load.erb"
  owner "root"
  group "root"
  mode 0644
end

apache_module 'php53' do
  conf true
end

execute "disable-default-site" do
  command "sudo a2dissite default"
  notifies :restart, resources(:service => "apache2")
end

web_app "application" do
  template "application.conf.erb"
  notifies :restart, resources(:service => "apache2")
end
