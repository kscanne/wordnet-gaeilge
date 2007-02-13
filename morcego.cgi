#!/usr/bin/perl -wT

use strict;
use CGI;
use utf8;
use Encode qw(decode encode);

sub bail_out
{
	print '<HTML><META HTTP-EQUIV="REFRESH" CONTENT="0;URL=http://www.aimsigh.com"></HTML>';
	exit 0;
}

# prepare query for inclusion as postdata
sub encode_URL
{
	(my $str) = @_;
	$str =~ s/ /+/g;
	$str =~ s/"/%22/g;
	$str =~ s/'/%27/g;
	$str =~ s/\(/%28/g;
	$str =~ s/\)/%29/g;
	return $str;
}

# inverse of previous; call right when ionchur is read from CGI
sub decode_URL
{
	(my $str) = @_;
	$str =~ s/\+/ /g;   # not really necessary since this is the default
	$str =~ s/%22/"/g;
	$str =~ s/%27/'/g;
	$str =~ s/%28/(/g;
	$str =~ s/%29/)/g;
	return $str;
}

sub generate_html_header {

	( my $pristine ) = @_;

	# should probably also do > ASCII chars as 
	# &#XXXX; though FF and IE seem ok with them
	# for use in URLs (succeeding pages linked at bottom of results page)
	$pristine =~ s/"/&quot;/g;
	print <<HEADER;
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN"
        "http://www.w3.org/TR/html4/strict.dtd">
<html lang="ga">
  <head>
    <title>$pristine - Cuardach aimsigh.com</title>
    <meta http-equiv="Content-Language" content="ga">
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
    <meta name="author" content="aimsigh.com">
    <link rel="stylesheet" href="http://www.aimsigh.com/aimsigh/aimsigh.css" type="text/css">
    <link rel="shortcut icon" href="http://www.aimsigh.com/aimsigh/favicon.ico" type="image/x-icon">
  </head>
  <body onLoad="focus();priomh.ionchur.focus()" class="laraithe">
    <form action="/cgi-bin/lsg.cgi" method="GET" name="priomh">
      <div><img src="http://www.aimsigh.com/aimsigh/aimsigh.png" alt="aimsigh.com"></div>
      <div>
        <input type="text" size="30" name="ionchur"><br>
        <input type="submit" name="foirm" value="Aimsigh é">
      </div>
    </form>

    <div class="anbheag">Cóipcheart © 2005, 2006, 2007 <a href="http://borel.slu.edu/index.html" target="_top">Kevin P. Scannell</a>. Gach ceart ar cosnamh.  Déan teagmháil linn ag <a href="mailto:eolas\@aimsigh.com">eolas\@aimsigh.com</a>.</p>
	<p></p>
    <hr>
HEADER
}

sub generate_html_footer {
	print <<FOOTER;
  </body>
</html>
FOOTER
}

sub generate_html_output {

	( my $ionchur ) = @_;

	print '    <applet codebase="http://borel.slu.edu/lsg/" archive="morcego-0.4.0.jar" code="br.arca.morcego.Morcego" width="800" height="300">'."\n";
	print '    <param name="serverUrl" value="http://borel.slu.edu:8080/RPC2">'."\n";
	print "    <param name=\"startNode\" value=\"$ionchur\">\n";
	print <<MORCEGO;
      <param name="windowWidth" value="800">
      <param name="windowHeight" value="300">
      <param name="viewWidth" value="800">
      <param name="viewHeight" value="300">
      <param name="navigationDepth" value="1">
      <param name="feedAnimationInterval" value="100">
      <param name="controlWindowName" value="wiki">

      <param name="showArcaLogo" value="false">
      <param name="showMorcegoLogo" value="false">

      <param name="loadPageOnCenter" value="true">

      <param name="cameraDistance" value="200">
      <param name="adjustCameraPosition" value="true">

      <param name="fieldOfView" value="250">
      <param name="nodeSize" value="15">
      <param name="textSize" value="25">

      <param name="frictionConstant" value="0.4f">
      <param name="elasticConstant" value="0.5f">
      <param name="eletrostaticConstant" value="1000f">
      <param name="springSize" value="100">
      <param name="nodeMass" value="5">
      <param name="nodeCharge" value="1">
    </applet>
MORCEGO
}


sub get_cgi_data {

	$CGI::DISABLE_UPLOADS = 1;
	$CGI::POST_MAX        = 1024;
	$ENV{PATH}="/bin:/usr/bin";
	delete @ENV{ 'IFS', 'CDPATH', 'ENV', 'BASH_ENV' };

	my $q = new CGI;
	# http headers, not html headers!  needed before first "bail_out"
	print $q->header(-type=>"text/html", -charset=>'utf-8');

	bail_out unless (defined($q->param( "ionchur" )));
	my( $ionchur ) = $q->param( "ionchur" ) =~ /^(.+)$/;
	bail_out unless ($ionchur);
	$ionchur = decode("UTF-8", $ionchur);  # utf-8 from CGI, convert to perl string
	$ionchur = decode_URL($ionchur);   # if inputs were post data

	$ionchur =~ s/ /+/g; # temporarily
	# important in particular to kill chars that are special to 
	# swish-e search that we don't want to support: *,= esp.
	# also stuff like shell metachars for safety (even though we're now
	# not using any external programs!)   ISO-8859-1 ONLY!
	$ionchur =~ s/[^0-9a-zA-ZàáâãäåæçèéêëìíîïðñòóôõöøùúûüýþÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖØÙÚÛÜÝÞ \+"'-]/ /g;

	return $ionchur;
}

sub priomh {
	binmode STDOUT, ":utf8";

	my $ionchur = get_cgi_data();

	generate_html_header($ionchur);
#	$ionchur =~ s/'/\'/g;
	generate_html_output($ionchur);
	generate_html_footer();
}

priomh();
exit 0;
