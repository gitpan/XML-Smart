#########################

###use Data::Dumper ; print Dumper( $XML->tree ) ;

use Test;
BEGIN { plan tests => 84 } ;
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
    <server address="192.168.3.30" os="bsd" type="freebsd" version="9.0"/>
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
  ok($data,q`<html><title>TITLE</title><body bgcolor="#000000"><foo1 baz='y1=name\" bar1=x1 &gt; end' w="q"/><foo2 bar2="" arg0="" x="y">FOO2-DATA</foo2><foo3 bar3="x3"/><foo4 url="http://www.com/dir/file.x?query=value&amp;x=y"/></body></html>`) ;

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
  
  my $data = $XML->data(noheader => 1 , nospace => 1) ;
  $data =~ s/\s//gs ;
  
  ok($data,q`<html><title>TITLE</title><bodybgcolor="#000000"><foo1bar1="x1"/><SCRIPTLANGUAGE="JavaScript"><_-->functionstopError(){returntrue;}window.onerror=stopError;document.writeln("some&lt;tag&gt;wirtten!");</_--></SCRIPT><foo2bar2="x2"/></body></html>`);

}
#########################
{
  my $XML = XML::Smart->new(q`
  <root>
    <foo name='x' *>
      <.sub1 arg="1" x=1 />
      <.sub2 arg="2"/>
      <bar size="100,50" +>
      content
      </bar>
    </foo>
  </root>
  ` , 'XML::Smart::HTMLParser') ;
  
  my $data = $XML->data(noheader => 1 , wild => 1) ;
  
  ok($data , q`<root>
  <foo name="x" *>
    <.sub1 arg="1" x="1"/>
    <.sub2 arg="2"/>
    <bar size="100,50" +>
      content
      </bar>
  </foo>
</root>

`);

}
#########################
{
  my $XML0 = XML::Smart->new(q`<root><foo1 name='x'/></root>` , 'XML::Smart::Parser') ;
  my $XML1 = XML::Smart->new(q`<root><foo2 name='y'/></root>` , 'XML::Smart::Parser') ;
  
  my $XML = XML::Smart->new() ;
  
  $XML->{sub}{sub2} = $XML0 ;
  push(@{$XML->{sub}{sub2}} , $XML1 ) ;
  
  my $data = $XML->data(noheader => 1) ;
  
  $data =~ s/\s//gs ;
  ok($data,'<sub><sub2><root><foo1name="x"/></root></sub2><sub2><root><foo2name="y"/></root></sub2></sub>') ;
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
  
  my $XML = XML::Smart->new(q`
  <users>
    <joe name="Joe X" email="joe@mail.com"/>
    <jonh name="JoH Y" email="jonh@mail.com"/>
    <jack name="Jack Z" email="jack@mail.com"/>
  </users>
  ` , 'XML::Smart::Parser') ;
  
  my @users = $XML->{users}('email','=~','^jo') ;
  
  ok( @users[0]->{name} , 'Joe X') ;
  ok( @users[1]->{name} , 'JoH Y') ;
  
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
  
  my $dataok = q`<HOSTS><SERVEROS="linux"TYPE="redhat"VERSION="8.0"><ADDRESS>192.168.0.1</ADDRESS><ADDRESS>192.168.0.2</ADDRESS></SERVER><SERVEROS="linux"TYPE="suse"VERSION="7.0"><ADDRESS>192.168.1.10</ADDRESS><ADDRESS>192.168.1.20</ADDRESS></SERVER><SERVERADDRESS="192.168.2.100"OS="linux"TYPE="conectiva"VERSION="9.0"/><SERVERADDRESS="192.168.3.30"OS="bsd"TYPE="freebsd"VERSION="9.0"/></HOSTS>`;
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
  
  my $dataok = q`<?xmlversion="1.0"encoding="iso-8859-1"length="88"?><rootdata="aaa"var="10"><addr>1</addr><addr>2</addr><addr>3</addr></root>`;

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
  ok("@types" , 'redhat suse conectiva freebsd') ;

  my @types = $XML->{hosts}{server}{type}('<@') ;
  ok("@types" , 'redhat suse conectiva freebsd') ;
  
}
#########################
{

  my $XML = XML::Smart->new($DATA , 'XML::Smart::Parser') ;

  my @srvs = $XML->{hosts}{server}('os','eq','linux') ;
  
  my @types ;
  foreach my $srvs_i ( @srvs ) { push(@types , $srvs_i->{type}) ;}
  ok("@types" , 'redhat suse conectiva') ;

  my @srvs = $XML->{hosts}{server}(['os','eq','linux'],['os','eq','bsd']) ;
  my @types ;
  foreach my $srvs_i ( @srvs ) { push(@types , $srvs_i->{type}) ;}
  ok("@types" , 'redhat suse conectiva freebsd') ;
  
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

  my $XML = XML::Smart->new(q`
  <root>
    <foo arg1="x" arg2="y">
      <bar arg='z'>cont</bar>
    </foo>
  </root>
  ` , 'XML::Smart::Parser') ;
  
  my @nodes = $XML->{root}{foo}->nodes ;
  
  ok($nodes[0]->{arg},'z');

  
  my @nodes = $XML->{root}{foo}->nodes_keys ;
  ok("@nodes",'bar');

  ok($XML->{root}{foo}{bar}->is_node) ;
  
  my @keys = $XML->{root}{foo}('@keys') ;
  ok("@keys",'arg1 arg2 bar');  

}
#########################
{

  my $data = qq`
  <root>
    <item arg1="x">
      <data><![CDATA[some CDATA code <non> <parsed> <tag> end]]></data>
    </item>
  </root>
  `;

  my $XML = XML::Smart->new($data , 'XML::Smart::Parser') ;
  
  ok( $XML->{root}{item}{data} , q`some CDATA code <non> <parsed> <tag> end`) ;

}
#########################
{

  my $XML = XML::Smart->new() ;
  
  $XML->{menu}{option}[0] = {
  name => "Help" ,
  level => {from => 1 , to => 99} ,
  } ;
  
  $XML->{menu}{option}[0]{sub}{option}[0] = {
  name => "Busca" ,
  level => {from => 1 , to => 99} ,
  } ;

  my $data = $XML->data(nospace => 1 , noheader => 1 ) ;
  
  ok($data , q`<menu><option name="Help"><level from="1" to="99"/><sub><option name="Busca"><level from="1" to="99"/></option></sub></option></menu>`) ;

}
#########################
{
  
  my $XML = XML::Smart->new() ;
  
  $XML->{menu}{arg1} = 123 ;
  $XML->{menu}{arg2} = 456 ;
  
  $XML->{menu}{arg2}{subarg} = 999 ;
  
  ok($XML->{menu}{arg1} , 123) ;
  ok($XML->{menu}{arg2} , 456) ;
  ok($XML->{menu}{arg2}{subarg} , 999) ;

  my $data = $XML->data(nospace => 1 , noheader => 1 ) ;
  ok($data , q`<menu arg1="123"><arg2 subarg="999">456</arg2></menu>`) ;

}
#########################
{
  
  my $XML = XML::Smart->new() ;
  
  $XML->{menu}{arg1} = [1,2,3] ;
  $XML->{menu}{arg2} = 4 ;
  
  my @arg1 = $XML->{menu}{arg1}('@') ;
  ok($#arg1 , 2) ;
  
  my @arg2 = $XML->{menu}{arg2}('@') ;
  ok($#arg2 , 0) ;
  
  my @arg3 = $XML->{menu}{arg3}('@') ;  
  ok($#arg3 , -1) ;  

}
#########################
{
  
  my $XML = XML::Smart->new() ;
  
  $XML->{menu}{arg2} = 456 ;
  $XML->{menu}{arg1} = 123 ;
  
  my $data = $XML->data(nospace => 1 , noheader => 1 ) ;
  ok($data , q`<menu arg2="456" arg1="123"/>`) ;

  $XML->{menu}{arg2}->set_node ;
  my $data = $XML->data(nospace => 1 , noheader => 1 ) ;
  ok($data , q`<menu arg1="123"><arg2>456</arg2></menu>`) ;
  

  $XML->{menu}{arg2}->set_node(0) ;
  my $data = $XML->data(nospace => 1 , noheader => 1 ) ;
  ok($data , q`<menu arg2="456" arg1="123"/>`) ;
  
  $XML->{menu}->set_order(arg1 , arg2) ;
  my $data = $XML->data(nospace => 1 , noheader => 1 ) ;
  ok($data , q`<menu arg1="123" arg2="456"/>`) ;
  
  delete $XML->{menu}{arg2}[0] ;

  my $data = $XML->data(nospace => 1 , noheader => 1 ) ;
  ok($data , q`<menu arg1="123"/>`) ;

}
#########################
{

  my $XML = XML::Smart->new($DATA , 'XML::Smart::Parser') ;
  $XML = $XML->{hosts} ;
  
  my $addr = $XML->{server}('type','eq','suse'){address} ;
  
  ok($addr->path , '/hosts/server[1]/address') ;
  
  my $addr0 = $XML->{server}('type','eq','suse'){address}[0] ;
  
  ok($addr0->path , '/hosts/server[1]/address[0]') ;
  ok($addr0->path_as_xpath , '/hosts/server[2]/address') ;
  
  my $addr1 = $XML->{server}('type','eq','suse'){address}[1] ;
  
  my $type = $XML->{server}('version','>=','9'){type} ;

  ok($type->path , '/hosts/server[2]/type') ;
  
  my $addr = $XML->{server}('version','>=','9'){address} ;

  ok($addr->path , '/hosts/server[2]/address') ;
  
  my $addr0 = $XML->{server}('version','>=','9'){address}[0] ;

  ok($addr0->path , '/hosts/server[2]/address[0]') ;
  ok($addr0->path_as_xpath , '/hosts/server[3]/@address') ;
  
  my $type = $XML->{server}('version','>=','9'){type} ;
  
  ok($type->path , '/hosts/server[2]/type') ;
  ok($type->path_as_xpath , '/hosts/server[3]/@type') ;
    
}
#########################
{
  
  my $html = q`
  <html>
  <p id="$s->{supply}->shift">foo</p>
   </html>
  `;
  
  my @tag ;

  my $p = XML::Smart::HTMLParser->new(
  Start => sub { shift; push(@tag , @_) ;},
  Char => sub {},
  End => sub {},
  );

  $p->parse($html) ;

  ok(@tag[-1] , '$s->{supply}->shift') ;  

}
#########################
{
  eval(q`use XML::XPath`) ;
  if ( !$@ ) {
    my $XML = XML::Smart->new($DATA , 'XML::Smart::Parser') ;
    
    my $xp1 = $XML->XPath ;
    my $xp2 = $XML->XPath ;
    ok($xp1,$xp2) ;
    
    my $xp1 = $XML->XPath ;
    $XML->{hosts}{tmp} = 123 ;
    my $xp2 = $XML->XPath ;
    
   ## Test cache of the XPath object:
    ok(1) if $xp1 != $xp2 ;
  
    delete $XML->{hosts}{tmp} ;
  
    my $data = $XML->XPath->findnodes_as_string('/') ;
    
    ok($data , q`<hosts><server os="linux" type="redhat" version="8.0"><address>192.168.0.1</address><address>192.168.0.2</address></server><server os="linux" type="suse" version="7.0"><address>192.168.1.10</address><address>192.168.1.20</address></server><server address="192.168.2.100" os="linux" type="conectiva" version="9.0" /><server address="192.168.3.30" os="bsd" type="freebsd" version="9.0" /></hosts>`) ;
  }
}
#########################
{

  eval(q`use LWP::UserAgent`) ;
  if ( !$@ ) {
  
    my $url = 'http://www.perlmonks.org/index.pl?node_id=16046' ;
  
    print "\nURL: $url\n" ;
    print "Do you want to test XML::Smart with an URL? (y|n*) " ;
    
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

print "\nThe End! By!\n" ;

1 ;



