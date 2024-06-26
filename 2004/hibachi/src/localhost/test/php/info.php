#!/usr/bin/php
<?
	// Bug #27026: header('HTTP/1.0 200 OK') never sent when explicitly
	// requested.
	// 
	// Send a 2xx status code not defined by RFC 2616. A 200 value would
	// be the correct value, but PHP/CGI refuses to send it when explicitly
	// set.
	//
	// This works for Opera 7, Mozilla 1.6, and IE 6.0 SP1.
	//
	header("HTTP/1.0 299 OK");
	phpinfo();
?>

