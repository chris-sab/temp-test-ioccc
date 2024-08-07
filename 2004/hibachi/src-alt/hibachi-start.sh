#!/bin/bash
#!/usr/bin/env -i /bin/sh
#!/bin/ksh
#!/bin/sh
#
# hibachi-start.sh
#
# Limited implementation of RFC 2616 and CGI/1.1.
#
# Public Domain 2002, 2004 by Anthony Howe.  All rights released.
#
# usage: 
#
#	hibachi-start.sh &
#

#######################################################################
# Do NOT modify the following section if you are security conscious.
#######################################################################

#
# Reset internal field separator to space, tab, newline.
# Not 100% effective if the environment we inherited has
# already played silly buggers with IFS like "IFS='S'".
#
# Use  #!/usr/bin/env -i /bin/sh on shells that support
# option passing and #! lines longer than 32 bytes to
# guarantee a clean environment.
#
IFS=' 	
'

SED=$(which sed)

#
# Get a clean environment to work with. This works for all
# Bourne like shells under Linux and Cygwin environments.
#
unset $(env | $SED -e 's/^\([^=]*\).*/\1/')

#
# Path of safe executables.
#
export PATH='/usr/local/bin:/usr/bin:/bin'

#
# Disable any environment file.
#
unset ENV

#
# Disable cd shortcuts.
#
unset CDPATH

#######################################################################
# Minimum required for serving static files.
#######################################################################

prefix=/usr/local
exec_prefix=${prefix}

datadir=${prefix}/share
sysconfdir=${prefix}/etc
sharedstatedir=${prefix}/com
localstatedir=/var
sbindir=${exec_prefix}/sbin
bindir=${exec_prefix}/bin

#
# The port to be used by the Hibachi web server.
#
# This is NOT normally a server parameter, but information about the
# client connection, but since Hibachi only listens on one port, we
# assume to know what the incoming port is and listen on that. Also
# for the purpose of demonstration, we can't bind to a privileged
# port.
#
export SERVER_PORT=8008

#
# The root of the Hibachi document tree. Virtual hosts
# are implemented as subdirectories from this location.
#
# For example, to setup virtual hosts by name or IP:
#
#	/usr/local/share/hibachi/
#		localhost/
#			index.html
#			...
#		127.0.0.1 -> localhost/
#
#		www.ioccc.org/
#			index.html
#			...
#		64.81.251.233 -> www.ioccc.org/
#
#export DOCUMENT_ROOT=${datadir}/hibachi
export DOCUMENT_ROOT=$(pwd)

#
# The executable.
#
#hibachi=${sbindir}/hibachi
hibachi=`dirname $0`/hibachi

#######################################################################
# Required for most CGI scripts.
#######################################################################

#
# Your host name or IP address. Ideally this should be the server-name
# used in self-referencing URLs.
#
export SERVER_NAME=127.0.0.1

#
# My web server name and version
#
export SERVER_SOFTWARE='hibachi/1.0'

#
# Predefined environment space for the request method.
#
export REQUEST_METHOD='1234'

#
# Predefined environment space for remote address of a request.
#
export REMOTE_ADDR='123.123.123.123'

#
# Predefined environment space for upload Content-Length.
#
export CONTENT_LENGTH='123456789.123456789.'

#
# Predefined environment space for upload Content-Type.
# Look at the Apache mime.types file, there are some long ones.
#
export CONTENT_TYPE='123456789.123456789.123456789.123456789.123456789.123456789.'

#
# Predefined environment space for cookies.  A single cookie can actually
# be a maximum of 4096 bytes in size, but here we only handle shorter ones.
#
export HTTP_COOKIE='123456789.123456789.123456789.123456789.123456789.123456789.123456789.123456789.'

#
# Predefined environment space for the absolute path of the script
# to be processed. Required by PHP/CGI in order to find the script.
# This variable is not part of the CGI/1.1 Specification. 
#
export SCRIPT_FILENAME='123456789.123456789.123456789.123456789.123456789.123456789.123456789.123456789.'

#
# Hibachi does support the entire CGI/1.1 specification.
#
export GATEWAY_INTERFACE='CGI/0.0'

#
# We cannot support the following common CGI environment variables
# as specified in the draft 3 of a proposed Internet Standard
# due to space limitations, but since the draft has expired and
# on hold, there is a lot of lee way:
#
#	AUTH_TYPE (MUST)            HTTP_ACCEPT (MAY)
#	HTTP_REFERER (MAY)          PATH_INFO (MUST)
#	PATH_TRANSLATED (SHOULD)    REMOTE_HOST (SHOULD)
#	REMOTE_IDENT (MAY)          REMOTE_USER (SHOULD)
#	SCRIPT_NAME	(MUST)          SERVER_PROTOCOL (MUST)
#

#######################################################################
# Nothing to configure below this point.
#######################################################################

#
# Start the web server.
#
exec ${hibachi}

#######################################################################
# Beyond here be dragons...
#######################################################################
