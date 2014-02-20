#!/usr/bin/perl

$| = 1;

my $topaste = shift;

if ($topaste eq 'string')
{
local $/;
open (FILE,"<",'temp.txt');
$topaste = <FILE>; 
close (FILE);
}

use LWP::UserAgent; 
my $ua = new LWP::UserAgent; 

#Code to use pastebin API - comment out because they limit the amount of transactions per day. 
=pod
my $response = $ua->post( 'http://pastebin.com/api/api_post.php', 
{ 'api_dev_key' => 'ce975e1ce5992a77253cfa80b900af77', 
'api_option' => 'paste', 
'api_paste_code' => "$topaste", 
'api_paste_name' => 'fitBot Results', 
'api_paste_private' => 1, 
'api_paste_expire_date'=> '1H' } );
=cut


my $response = $ua->post( 'http://tny.cz/api/create.xml.json', 
{ 
'api_option' => 'paste', 
'paste' => "$topaste", 
'title' => 'fitBot Results', 
'is_private' => 1 } );

#cut the response open from XML
my $content = $response->content; 
my $begin = index($content,'<response>')+10;
my $myurl = substr($content,$begin);
my $end = index($myurl,'</response>');
my $theurl = substr($myurl,0,$end);
my $f_url = "http://tny.cz/$theurl";

print STDOUT "PaSteBiN: $f_url \n";

exit;
