#!/usr/bin/perl
# serve-panel.pl - tiny dependency-free HTTP front-end for the Bash CGI panel
use strict; use warnings; use Socket;
my $port=8080;
socket(my $S,PF_INET,SOCK_STREAM,getprotobyname('tcp')) or die "socket: $!";
setsockopt($S,SOL_SOCKET,SO_REUSEADDR,1);
bind($S,sockaddr_in($port,INADDR_ANY)) or die "bind: $!";
listen($S,20) or die "listen: $!";
$SIG{CHLD}='IGNORE';
print "openducky web on :$port\n";
while(accept(my $C,$S)){
  my $pid=fork;
  if(defined $pid && $pid==0){
    close $S;
    my $req=<$C>//'';
    my $clen=0;
    while(my $h=<$C>){ last if $h=~/^\r?\n/; $clen=$1 if $h=~/^content-length:\s*(\d+)/i; }
    my ($method,$uri)=$req=~/^(\S+)\s+(\S+)/; $method//='GET'; $uri//='/';
    my ($path,$qs)=split/\?/,$uri,2; $qs//='';
    my $body=''; read($C,$body,$clen) if $clen>0;
    if($path=~m{panel\.cgi}){
      my $tmp="/tmp/ducky-post.$$"; open(my $t,'>',$tmp); print $t $body; close $t;
      local $ENV{REQUEST_METHOD}=$method; local $ENV{CONTENT_LENGTH}=length($body); local $ENV{QUERY_STRING}=$qs;
      my $out=`/opt/ducky/web/cgi-bin/panel.cgi < $tmp 2>/dev/null`;
      unlink $tmp;
      print $C "HTTP/1.0 200 OK\r\n$out";
    } else {
      print $C "HTTP/1.0 302 Found\r\nLocation: /cgi-bin/panel.cgi\r\nContent-Length: 0\r\n\r\n";
    }
    close $C; exit 0;
  }
  close $C;
}
