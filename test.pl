#########################

###use Data::Dumper ; print Dumper( $XML->tree ) ;

use Test;
BEGIN { plan tests => 47 } ;
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
  
  my $XML = XML::Smart->new('<root><foo bar="x"/></root>' , 'XML::Smart::Parser') ;
  my $data = $XML->data(noheader => 1) ;
  
  $data =~ s/\s//gs ;
  ok($data,'<root><foobar="x"/></root>') ;
  
}
#########################
{
  
  my $XML = XML::Smart->new($DATA , 'XML::Smart::Parser') ;
  
  my $data = $XML->data(nometagen => 1) ;
  $data =~ s/\s//gs ;
  
  my $data_org = $DATA ;
  $data_org =~ s/\s//gs ;
  
  ok($data,$data_org) ;
    
}
#########################
{

  my $XML = XML::Smart->new('<root><foo bar="x"/></root>' , 'XML::Smart::HTMLParser') ;
  my $data = $XML->data(noheader => 1) ;
  $data =~ s/\s//gs ;
  ok($data,'<root><foobar="x"/></root>') ;
  
  my $XML = XML::Smart->new(q`
  <html><title>TITLE</title>
  <body bgcolor='#000000'>
    <foo1 baz="y1=name\" bar1=x1 > end" w=q>
    <foo2 bar2="" arg0 x=y>FOO2-DATA</foo2>
    <foo3 bar3=x3>
    <foo4 url=http://www.com/dir/file.x?query=value&x=y>
  </body>
  </html>
  ` , 'HTML') ;
  
  my $data = $XML->data(noheader => 1 , nospace => 1 ) ;
  ok($data,q`<html title="TITLE"><body bgcolor="#000000"><foo1 baz='y1=name\" bar1=x1 &gt; end' w="q"/><foo2 arg0="" bar2="" x="y">FOO2-DATA</foo2><foo3 bar3="x3"/><foo4 url="http://www.com/dir/file.x?query=value&amp;x=y"/></body></html>`) ;

  my $XML = XML::Smart->new(q`
  <html><title>TITLE</title>
  <body bgcolor='#000000'>
    <foo1 bar1=x1>
    <SCRIPT LANGUAGE="JavaScript"><!--
    function stopError() { return true; }
    window.onerror = stopError;
    document.writeln("some <tag> wirtten!");
    --></SCRIPT>
    <foo2 bar2=x2>
  </body></html>
  ` , 'HTML') ;
  
  my $data = $XML->data(noheader => 1 , nospace => 1 ) ;
  $data =~ s/\s//gs ;
  
  ok($data,q`<htmltitle="TITLE"><bodybgcolor="#000000"><SCRIPTLANGUAGE="JavaScript">&lt;!--functionstopError(){returntrue;}window.onerror=stopError;document.writeln("some&lt;tag&gt;wirtten!");--&gt;</SCRIPT><foo1bar1="x1"/><foo2bar2="x2"/></body></html>`);

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
  
  my $data = $XML->data(noheader => 1) ;
  $data =~ s/\s//gs ;
    
  my $dataok = q`<serveros="Linux"type="mandrake"version="8.9"><address>192.168.3.201</address><address>192.168.3.202</address></server>`;
  ok($data,$dataok) ;
}
#########################
{

  my $XML = XML::Smart->new('<foo port="80">ct<i>a</i><i>b</i></foo>' , 'XML::Smart::Parser') ;
  my $data = $XML->data(noheader => 1) ;
  $data =~ s/\s//gs ;
  
  my $dataok = qq`<fooport="80"><i>a</i><i>b</i>ct</foo>` ;
  
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
  noheader => 1 ,
  ) ;
  
  $data =~ s/\s//gs ;
  
  my $dataok = q`<HOSTS><SERVEROS="linux"TYPE="redhat"VERSION="8.0"><ADDRESS>192.168.0.1</ADDRESS><ADDRESS>192.168.0.2</ADDRESS></SERVER><SERVEROS="linux"TYPE="suse"VERSION="7.0"><ADDRESS>192.168.1.10</ADDRESS><ADDRESS>192.168.1.20</ADDRESS></SERVER><SERVERADDRESS="192.168.2.100"OS="linux"TYPE="conectiva"VERSION="9.0"/></HOSTS>`;

  ok($data,$dataok) ;
}
#########################
{

  my $XML = XML::Smart->new('' , 'XML::Smart::Parser') ;
  
  $XML->{data} = aaa ;
  $XML->{var} = 10 ;
  
  $XML->{addr} = [qw(1 2 3)] ;
  
  my $data = $XML->data(length => 1 , nometagen => 1 ) ;
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
  
  my $data = $XML->data(noheader => 1) ;
  $data =~ s/\s//gs ;
  
  $dataok = q`<hosts><serveros="lx"type="red"ver="123"/></hosts>`;
  
  ok($data,$dataok) ;
                       
  $XML->{hosts}[1]{server}[1] = {
  os => 'LX'  ,
  type => 'red'  ,
  ver => 123 ,
  } ;
  
  my $data = $XML->data(noheader => 1) ;
  $data =~ s/\s//gs ;
  
  $dataok = q`<root><hosts><serveros="lx"type="red"ver="123"/></hosts><hosts><serveros="LX"type="red"ver="123"/></hosts></root>`;
  
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
  
  my $data = $XML->data(noheader => 1) ;
  $data =~ s/\s//gs ;
  
  $dataok = q`<hosts><serveros="LX"type="red"ver="123"/></hosts>`;
  
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
  
  my $data = $XML->data(noheader => 1) ;
  $data =~ s/\s//gs ;
  
  $dataok = q`<root><hostsos="lx"type="red"ver="123"/><hostsXXXXXX="1"/></root>` ;
  
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
{

  my $XML = XML::Smart->new($DATA , 'XML::Smart::Parser') ;

  my @types = $XML->{hosts}{server}('[@]','type') ;
  ok("@types" , 'redhat suse conectiva') ;

  my @types = $XML->{hosts}{server}{type}('<@') ;
  ok("@types" , 'redhat suse conectiva') ;
  
}
#########################
{

  my $wild = pack("C", 127 ) ;

  $data = qq`<?xml version="1.0" encoding="iso-8859-1"?><code>$wild</code>`;

  my $XML = XML::Smart->new($data , 'XML::Smart::Parser') ;

  ok($XML->{code} , $wild) ;
  my $data = $XML->data() ;
  
  my $XML = XML::Smart->new($data , 'XML::Smart::Parser') ;

  ok($XML->{code} , $wild) ;
  
  my $data2 = $XML->data() ;
  ok($data , $data2) ;

}
#########################
{

  my $XML = XML::Smart->new($DATA , 'XML::Smart::Parser') ;
  
  my $addr1 = $XML->{hosts}{server}{address} ;
  
  my $XML2 = $XML->cut_root ;
  my $addr2 = $XML2->{server}{address} ;
  
  ok($addr1,$addr2) ;

}
#########################
{

  my $data = q`
  <root>
    <foo bar="x"> My Company &amp; Name + &lt;tag&gt; &quot; + &apos;...</foo>
  </root>
  `;

  my $XML = XML::Smart->new($data , 'XML::Smart::Parser') ;
  
  ok($XML->{root}{foo} , q` My Company & Name + <tag> " + '...`) ;
  
  my $data = $XML->data(nospace => 1 , noheader => 1 ) ;
  ok($data , q`<root><foo bar="x"> My Company &amp; Name + &lt;tag&gt; " + '...</foo></root>`) ;

}
#########################
{

  eval(q`use LWP::UserAgent`) ;
  if ( !$@ ) {
  
    my $url = 'http://www.perlmonks.org/index.pl?node_id=16046' ;
  
    print "\nURL: $url\n" ;
    print "Do you want to test XML::Smart with URL? (y|n*) " ;
    
    chomp( my $opt = <STDIN>);
    
    if ( $opt =~ /^\s*(?:y|s)/si ) {
      print "\nGetting URL... " ;
      
      my $XML = XML::Smart->new($url , 'XML::Smart::Parser') ;
      
      print "Test: " ;
      if ( $XML->{XPINFO}{INFO}{sitename} eq 'Perl Monks' ) { print "OK\n" ;}
      else {
        print "ERROR!\n" ;
        print "-----------------------------------------------\n" ;
        print "The XML of the URL:\n\n" ;
        print $XML->data ;
        print "-----------------------------------------------\n" ;
      }
    }
    else { print "Skipping URL test!\n" ;}
  }

}
#########################

print "\nTests ended! By!\n" ;

1 ;


