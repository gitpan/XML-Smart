#########################

use Test;
BEGIN { plan tests => 35 } ;
use XML::Smart ;

no warnings ;

my $DATA = q`<?xml version="1.0" encoding="iso-8859-1"?>
<hosts>
    <server os="linux" type="redhat" version="8.0">
      <address>192.168.0.1</address>
      <address>192.168.0.2</address>
    </server>
    <server os="linux" type="suse" version="7.0">
      <address>192.168.1.10</address>
      <address>192.168.1.20</address>
    </server>
    <server address="192.168.2.100" os="linux" type="conectiva" version="9.0"/>
</hosts>
`;

#########################
{
  
  my $XML = XML::Smart->new($DATA , 'XML::Smart::Parser') ;
  
  my $data = $XML->data ;
  $data =~ s/\s//gs ;
  
  my $data_org = $DATA ;
  $data_org =~ s/\s//gs ;
  
  ok($data,$data_org) ;
    
}
#########################
{
  my $XML = XML::Smart->new($DATA , 'XML::Smart::Parser') ;
  $XML = $XML->{hosts} ;
  
  my $addr = $XML->{server}[0]{address} ;
  ok($addr,'192.168.0.1') ;
  
  my $addr0 = $XML->{server}[0]{address}[0] ;
  ok($addr,$addr0);
  
  my $addr1 = $XML->{server}{address}[1] ;
  ok($addr1,'192.168.0.2') ;
  
  my $addr01 = $XML->{server}[0]{address}[1] ;
  ok($addr1,$addr01);
  
  my @addrs = @{$XML->{server}{address}} ;
  
  ok(@addrs[0],$addr0);
  ok(@addrs[1],$addr1);
  
  my @addrs = @{$XML->{server}[0]{address}} ;
  
  ok(@addrs[0],$addr0);
  ok(@addrs[1],$addr1);
}
#########################
{

  my $XML = XML::Smart->new($DATA , 'XML::Smart::Parser') ;
  $XML = $XML->{hosts} ;
  
  my $addr = $XML->{server}('type','eq','suse'){address} ;
  ok($addr,'192.168.1.10') ;
  
  my $addr0 = $XML->{server}('type','eq','suse'){address}[0] ;
  ok($addr,$addr0) ;
  
  my $addr1 = $XML->{server}('type','eq','suse'){address}[1] ;
  ok($addr1,'192.168.1.20') ;
  
  my $type = $XML->{server}('version','>=','9'){type} ;
  ok($type,'conectiva') ;
  
  my $addr = $XML->{server}('version','>=','9'){address} ;
  ok($addr,'192.168.2.100') ;
  
  my $addr0 = $XML->{server}('version','>=','9'){address}[0] ;
  ok($addr0,$addr) ;
    
}
#########################
{

  my $XML = XML::Smart->new($DATA , 'XML::Smart::Parser') ;
  $XML = $XML->{hosts} ;

  my $newsrv = {
  os => 'Linux' ,
  type => 'mandrake' ,
  version => 8.9 ,
  address => '192.168.3.201' ,
  } ;

  push(@{$XML->{server}} , $newsrv) ;
  
  my $addr0 = $XML->{server}('type','eq','mandrake'){address}[0] ;
  ok($addr0,'192.168.3.201') ;
  
  $XML->{server}('type','eq','mandrake'){address}[1] = '192.168.3.202' ;

  my $addr1 = $XML->{server}('type','eq','mandrake'){address}[1] ;
  ok($addr1,'192.168.3.202') ;
  
  push(@{$XML->{server}('type','eq','conectiva'){address}} , '192.168.2.101') ;

  my $addr1 = $XML->{server}('type','eq','conectiva'){address}[1] ;
  ok($addr1,'192.168.2.101') ;
  
  my $addr1 = $XML->{server}[2]{address}[1] ;
  ok($addr1,'192.168.2.101') ;
  
}
#########################
{
  my $XML = XML::Smart->new() ;
  
  $XML->{server} = {
  os => 'Linux' ,
  type => 'mandrake' ,
  version => 8.9 ,
  address => '192.168.3.201' ,
  } ;

  $XML->{server}{address}[1] = '192.168.3.202' ;
  
  my $data = $XML->data ;
  $data =~ s/\s//gs ;
    
  my $dataok = q`<?xmlversion="1.0"encoding="iso-8859-1"?><serveros="Linux"type="mandrake"version="8.9"><address>192.168.3.201</address><address>192.168.3.202</address></server>`;
  ok($data,$dataok) ;
}
#########################
{

  my $XML = XML::Smart->new('<foo port="80">ct<i>a</i><i>b</i></foo>' , 'XML::Smart::Parser') ;
  my $data = $XML->data ;
  $data =~ s/\s//gs ;
  
  my $dataok = qq`<?xmlversion="1.0"encoding="iso-8859-1"?><fooport="80"><i>a</i><i>b</i>ct</foo>` ;
  
  ok($data,$dataok) ;

}
#########################
{

  my $XML = XML::Smart->new($DATA , 'XML::Smart::Parser') ;
  
  $XML->{hosts}{server}('type','eq','conectiva'){address}[1] = '' ;
  
  my $data = $XML->data(
  noident => 1 ,
  nospace => 1 ,
  lowtag => 1 ,
  upertag => 1 ,
  uperarg => 1 ,
  ) ;
  
  $data =~ s/\s//gs ;
  
  my $dataok = q`<?xmlversion="1.0"encoding="iso-8859-1"?><HOSTS><SERVEROS="linux"TYPE="redhat"VERSION="8.0"><ADDRESS>192.168.0.1</ADDRESS><ADDRESS>192.168.0.2</ADDRESS></SERVER><SERVEROS="linux"TYPE="suse"VERSION="7.0"><ADDRESS>192.168.1.10</ADDRESS><ADDRESS>192.168.1.20</ADDRESS></SERVER><SERVERADDRESS="192.168.2.100"OS="linux"TYPE="conectiva"VERSION="9.0"/></HOSTS>`;

  ok($data,$dataok) ;
}
#########################
{

  my $XML = XML::Smart->new('' , 'XML::Smart::Parser') ;
  
  $XML->{data} = aaa ;
  $XML->{var} = 10 ;
  
  $XML->{addr} = [qw(1 2 3)] ;
  
  my $data = $XML->data(length => 1) ;
  $data =~ s/\s//gs ;
  
  my $dataok = q`<?xmlversion="1.0"encoding="iso-8859-1"length="87"?><rootdata="aaa"var="10"><addr>1</addr><addr>2</addr><addr>3</addr></root>`;

  ok($data,$dataok) ;
}
#########################
{

  my $XML = XML::Smart->new('' , 'XML::Smart::Parser') ;
  
  $XML->{hosts}{server} = {
  os => 'lx'  ,
  type => 'red'  ,
  ver => 123 ,
  } ;
  
  my $data = $XML->data() ;
  $data =~ s/\s//gs ;
  
  $dataok = q`<?xmlversion="1.0"encoding="iso-8859-1"?><hosts><serveros="lx"type="red"ver="123"/></hosts>`;
  
  ok($data,$dataok) ;
                       
  $XML->{hosts}[1]{server}[1] = {
  os => 'LX'  ,
  type => 'red'  ,
  ver => 123 ,
  } ;
  
  my $data = $XML->data() ;
  $data =~ s/\s//gs ;
  
  $dataok = q`<?xmlversion="1.0"encoding="iso-8859-1"?><root><hosts><serveros="lx"type="red"ver="123"/></hosts><hosts><serveros="LX"type="red"ver="123"/></hosts></root>`;
  
  ok($data,$dataok) ;
  
}

#########################
{

  my $XML = XML::Smart->new('' , 'XML::Smart::Parser') ;
                          
  $XML->{hosts}[1]{server}[1] = {
  os => 'LX'  ,
  type => 'red'  ,
  ver => 123 ,
  } ;
  
  my $data = $XML->data() ;
  $data =~ s/\s//gs ;
  
  $dataok = q`<?xmlversion="1.0"encoding="iso-8859-1"?><hosts><serveros="LX"type="red"ver="123"/></hosts>`;
  
  ok($data,$dataok) ;
  
}
#########################
{

  my $XML = XML::Smart->new('' , 'XML::Smart::Parser') ;
                          
  my $srv = {
  os => 'lx'  ,
  type => 'red'  ,
  ver => 123 ,
  } ;

  push( @{$XML->{hosts}} , {XXXXXX => 1}) ;
  unshift( @{$XML->{hosts}{x}}  , $srv) ;
  
  my $data = $XML->data() ;
  $data =~ s/\s//gs ;
  
  $dataok = q`<?xmlversion="1.0"encoding="iso-8859-1"?><root><hostsos="lx"type="red"ver="123"/><hostsXXXXXX="1"/></root>` ;
  
  ok($data,$dataok) ;

}
#########################
{

  my $XML = XML::Smart->new('' , 'XML::Smart::Parser') ;
  
  $XML->{hosts}{server} = [
  { os => lx , type => a , ver => 1 ,} ,
  { os => lx , type => b , ver => 2 ,} ,
  ];
  
  ok( $XML->{hosts}{server}{type} , 'a') ;
  
  my $srv0 = shift( @{$XML->{hosts}{server}} ) ;
  ok( $$srv0{type} , 'a') ;
  
  ok( $XML->{hosts}{server}{type} , 'b') ;
  ok( $XML->{hosts}{server}{type}[0] , 'b') ;
  ok( $XML->{hosts}{server}[0]{type}[0] , 'b') ;
  ok( $XML->{hosts}[0]{server}[0]{type}[0] , 'b') ;
  
  my $srv1 = pop( @{$XML->{hosts}{server}} ) ;
  ok( $$srv1{type} , 'b') ;
  
  my $data = $XML->data(noheader => 1) ;
  ok($data , '') ;

}
#########################

1 ;


