#############################################################################
## Name:        Data.pm
## Purpose:     XML::Smart::Data - Generate XML data.
## Author:      Graciliano M. P.
## Modified by:
## Created:     28/09/2003
## RCS-ID:      
## Copyright:   (c) 2003 Graciliano M. P.
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################

package XML::Smart::Data ;

our ($VERSION , @ISA) ;
$VERSION = '0.01' ;

require Exporter ;
@ISA = qw(Exporter) ;

our @EXPORT = qw(data) ;
our @EXPORT_OK = @EXPORT ;

use strict ;
no warnings ;

########
# DATA #
########

sub data {
  my $this = shift ;
  my ( %args ) = @_ ;
  
  my $tree ;
  
  if ( $args{tree} ) { $tree = $args{tree} ;}
  else { $tree = $this->tree ;}
  
  {
    my $addroot ;

    if ( ref $tree ne 'HASH' ) { $addroot = 1 ;}
    else {
      my $ks = keys %$tree ;
      my $n = 1 ;
      if (ref $$tree{'/nodes'} eq 'HASH')  { ++$n if (keys %{$$tree{'/nodes'}}) ;}
      if (ref $$tree{'/order'} eq 'ARRAY') { ++$n if @{$$tree{'/order'}} ;}

      if ($ks > $n) { $addroot = 1 ;}
      else {
        my $k = (keys %$tree)[0] ;
        if (ref $$tree{$k} eq 'ARRAY' && $#{$$tree{$k}} > 0) {
          my ($c,$ok) ;
          foreach my $i ( @{$$tree{$k}} ) {
            if ( $i && &is_valid_tree($i) ) { $c++ ; $ok = $i ;}
            if ($c > 1) { $addroot = 1 ; last ;}
          }
          if (!$addroot && $ok) { $$tree{$k} = $ok ;}
        }
        elsif (ref $$tree{$k} =~ /^(?:HASH|)$/) {$addroot = 1 ;}
      }
    }
    
    if ($addroot) {
      my $root = $args{root} || 'root' ;
      $tree = {$root => $tree} ;
    }
  }
  
  if ( $args{lowtag} ) { $args{lowtag} = 1 ;}
  if ( $args{upertag} ) { $args{lowtag} = 2 ;}
  
  if ( $args{lowarg} ) { $args{lowarg} = 1 ;}
  if ( $args{uperarg} ) { $args{lowarg} = 2 ;}

  my ($data,$unicode) ;
  {
    my $parsed = {} ;
    &_data(\$data,$tree,'',-1, {} , $parsed , $args{noident} , $args{nospace} , $args{lowtag} , $args{lowarg} , $args{wild} , $args{sortall} ) ;
    $data .= "\n" if !$args{nospace} ;
    if ( &_is_unicode($data) ) { $unicode = 1 ;}
  }

  my $enc = 'iso-8859-1' ;
  if ($unicode) { $enc = 'utf-8' ;}
    
  my $meta ;
  if ( $args{meta} ) {
    my @metas ;
    if (ref($args{meta}) eq 'ARRAY') { @metas = @{$args{meta}} ;}
    elsif (ref($args{meta}) eq 'HASH') { @metas = $args{meta} ;}
    else { @metas = $args{meta} ;}
    
    foreach my $metas_i ( @metas ) {
      if (ref($metas_i) eq 'HASH') {
        my $meta ;
        foreach my $Key (sort keys %$metas_i ) {
          $meta .= " $Key=" . &_add_quote($$metas_i{$Key}) ;
        }
        $metas_i = $meta ;
      }
    }
    
    foreach my $meta ( @metas ) {
      $meta =~ s/^[<\?\s*]//s ;
      $meta =~ s/[\s\?>]*$//s ;
      $meta =~ s/^meta\s+//s ;
      $meta = "<?meta $meta ?>" ;
    }
    
    $meta = "\n" . join ("\n", @metas) ;
  }
  
  my $wild = ' [format: wild]' if $args{wild} ;
  
  my $metagen = qq`\n<?meta name="GENERATOR" content="XML::Smart/$XML::Smart::VERSION$wild Perl/$] [$^O]" ?>` ;
  if ( $args{nometagen} ) { $metagen = '' ;}
  
  my $length ;
  if ( $args{length} ) {
    $length = ' length="' . (length($metagen) + length($meta) + length($data)) . '"' ;
  }
  
  my $xml = qq`<?xml version="1.0" encoding="$enc"$length ?>` ;
  
  if ( $args{noheader} ) { $xml = '' ; $metagen = '' if $args{nometagen} eq '' ;}
  
  $data = $xml . $metagen . $meta . $data ;
  
  if ($xml eq '') { $data =~ s/^\s+//gs ;}
  
  if (wantarray) { return($data , $unicode) ;}
  return($data) ;
}

#################
# IS_VALID_TREE #
#################

sub is_valid_tree {
  my ( $tree ) = @_ ;
  my $found ;
  if (ref($tree) eq 'HASH') {
    foreach my $Key (sort keys %$tree ) {
      if ($Key eq '' || $Key eq '/order' || $Key eq '/nodes') { next ;}
      if (ref($$tree{$Key})) { $found = &is_valid_tree($$tree{$Key}) ;}
      elsif ($$tree{$Key} ne '') { $found = 1 ;}
      if ($found) { last ;}
    }
  }
  elsif (ref($tree) eq 'ARRAY') {
    foreach my $value (@$tree) {
      if (ref($value)) { $found = &is_valid_tree($value) ;}
      elsif ($value ne '') { $found = 1 ;}
      if ($found) { last ;}      
    }
  }
  elsif (ref($tree) eq 'SCALAR' && $$tree ne '') { $found = 1 ;}
  
  return $found ;
}

###############
# _IS_UNICODE #
###############

sub _is_unicode {
  if ($] >= 5.8) {
    eval(q`
      if ( $data =~ /[\x{100}-\x{10FFFF}]/s) { return 1 ;}}
    `);
  }
  else {
    ## No Perl internal support for UTF-8! ;-/
    ## Is better to handle as Latin1.
    return undef ;
  }

  return undef ;
}

#########
# _DATA #
#########

sub _data {
  my ( $data , $tree , $tag , $level , $prev_tree , $parsed , @stat ) = @_ ;

  if (ref($tree) eq 'XML::Smart') { $tree = $$tree->{point} ;}
  
  if ($$parsed{"$tree"}) { return ;}
  $$parsed{"$tree"}++ ;
  
  my $ident = "\n" ;
  $ident .= '  ' x $level if !$stat[0] ;
  
  if ($stat[1]) { $ident = '' ;}
  
  my $tag_org = $tag ;
  $tag = $stat[4] ? $tag : &_check_tag($tag) ;
  if    ($stat[2] == 1) { $tag = "\L$tag\E" ;}
  elsif ($stat[2] == 2) { $tag = "\U$tag\E" ;}

  if (ref($tree) eq 'HASH') {
    my ($args,$args_end,$tags,$cont) ;
    
    my @all_keys ;
    
    if ( !$stat[5] && $tree->{'/order'} ) {
      my %keys ;
      foreach my $keys_i ( @{$tree->{'/order'}} , sort keys %$tree ) {
        if ( !$keys{$keys_i} && exists $$tree{$keys_i} ) {
          push(@all_keys , $keys_i) ;
          $keys{$keys_i} = 1 ;
        }
      }
    }
    else { @all_keys = sort keys %$tree ;}
    
    ##print "*** $tree->{'/order'} >> @all_keys\n" ;
    
    #if ( (defined $$tree{CONTENT} && $$tree{CONTENT} ne '') || (defined $$tree{content} && $$tree{content} ne '')) { $stat[0] = 1 ; $ident = '' ;}
    
    foreach my $Key ( @all_keys ) {
      if ($Key eq '' || $Key eq '/order' || $Key eq '/nodes') { next ;}
      if (ref($$tree{$Key})) {
        my $k = $$tree{$Key} ;
        if (ref $k eq 'XML::Smart') { $k = ${$$tree{$Key}}->{point} ;}
        $args .= &_data(\$tags,$k,$Key, $level+1 , $tree , $parsed , @stat) ;
      }
      elsif ( $$tree{'/nodes'}{$Key} ) {
        my $k = [$$tree{$Key}] ;
        $args .= &_data(\$tags,$k,$Key, $level+1 , $tree , $parsed , @stat) ;
      }
      elsif ("\L$Key\E" eq 'content') { $cont .= $$tree{$Key} ;}
      elsif ( $Key eq '!--' && (!ref($$tree{$Key}) || ( ref($$tree{$Key}) eq 'HASH' && keys %{$$tree{$Key}} == 1 && (defined $$tree{$Key}{CONTENT} || defined $$tree{$Key}{content}) ) ) ) {
        my $ct = $$tree{$Key} ;
        if (ref $$tree{$Key}) { $ct = defined $$tree{$Key}{CONTENT} ? $$tree{$Key}{CONTENT} : $$tree{$Key}{content} ;} ;
        $cont .= '<!--' . $ct . '-->' ;
      }
      elsif ( $stat[4] && $$tree{$Key} eq '') { $args_end .= " $Key" ;}
      else {
        my $tp = _data_type($$tree{$Key}) ;
        if    ($tp == 1) {
          my $k = $stat[4] ? $Key : &_check_key($Key) ;
          if    ($stat[3] == 1) { $k = "\L$Key\E" ;}
          elsif ($stat[3] == 2) { $k = "\U$Key\E" ;}
          $args .= " $k=" . &_add_quote($$tree{$Key}) ;
        }
        else {
          my $k = $stat[4] ? $Key : &_check_key($Key) ;
          if    ($stat[2] == 1) { $k = "\L$Key\E" ;}
          elsif ($stat[2] == 2) { $k = "\U$Key\E" ;}

          if ($tp == 2) {
            my $cont = $$tree{$Key} ; &_add_basic_entity($cont) ;
            $tags .= qq`$ident<$k>$cont</$k>` ;
          }
          elsif ($tp == 3) { $tags .= qq`$ident<$k><![CDATA[$$tree{$Key}]]></$k>`;}
          elsif ($tp == 4) {
            require XML::Smart::Base64 ;
            my $base64 = &XML::Smart::Base64::encode_base64($$tree{$Key}) ;
            $base64 =~ s/\s$//s ;
            $tags .= qq`$ident<$k dt:dt="binary.base64">$base64</$k>`;
          }
        }
      }
    }
    
    &_add_basic_entity($cont) if $cont ne '' ;
    
    if ($args_end ne '') {
      $args .= $args_end ;
      $args_end = undef ;
    }
    
    #print "cont [$cont] $tags , $args , $cont\n" ;
    
    if ($args ne '' && $tags ne '') {
      $$data .= qq`$ident<$tag$args>` if $tag ne '' ;
      $$data .= $tags ;
      $$data .= $cont ;
      $$data .= $ident if $cont eq '' ;
      $$data .= qq`</$tag>` if $tag ne '' ;
    }
    elsif ($args ne '' && $cont ne '') {
      $$data .= qq`$ident<$tag$args>` if $tag ne '' ;
      $$data .= $cont ;
      $$data .= $ident if $cont eq '' ;
      $$data .= qq`</$tag>` if $tag ne '' ;
    }
    elsif ($args ne '') {
      $$data .= qq`$ident<$tag$args/>`;
    }
    elsif ($tags ne '') {
      $$data .= qq`$ident<$tag>` if $tag ne '' ;
      $$data .= $tags ;
      $$data .= $cont ;
      $$data .= $ident if $cont eq '' ;
      $$data .= qq`</$tag>` if $tag ne '' ;
    }
    elsif ($cont ne '') {
      $$data .= qq`$ident<$tag>` if $tag ne '' ;
      $$data .= $cont ;
      $$data .= qq`</$tag>` if $tag ne '' ;
    }
  }
  elsif (ref($tree) eq 'ARRAY') {
    my ($c,$v,$tags) ;
    
    foreach my $value_i (@$tree) {
      my $value = $value_i ;
      if (ref $value_i eq 'XML::Smart') { $value = $$value_i->{point} ;}
      
      my $do_val = 1 ;
      if ( $tag_org eq '!--' && ( !ref($value) || ( ref($value) eq 'HASH' && keys %{$value} == 1 && (defined $$value{CONTENT} || defined $$value{content}) ) ) ) {
        $c++ ;
        my $ct = $value ;
        if (ref $value) { $ct = defined $$value{CONTENT} ? $$value{CONTENT} : $$value{content} ;} ;
        $tags .= $ident . '<!--' . $ct . '-->' ;
        $v = $ct if $c == 1 ;
        $do_val = 0 ;
      }
      elsif (ref($value)) {
        if (ref($value) eq 'HASH') {
          $c = 2 ;
          &_data(\$tags,$value,$tag,$level, $tree , $parsed , @stat) ;
          $do_val = 0 ;
        }
        elsif (ref($value) eq 'SCALAR') { $value = $$value ;}
        elsif (ref($value) ne 'ARRAY') { $value = "$value" ;}
      }
      if ( $do_val && $value ne '') {
        my $tp = _data_type($value) ;
        if ($tp <= 2) {
          $c++ ;
          my $cont = $value ; &_add_basic_entity($value) ;
          &_add_basic_entity($cont) ;
          $tags .= qq`$ident<$tag>$cont</$tag>`;
          $v = $cont if $c == 1 ;
        }
        elsif ($tp == 3) {
          $c++ ;
          $tags .= qq`$ident<$tag><![CDATA[$value]]></$tag>`;
          $v = $value if $c == 1 ;
        }
        elsif ($tp == 4) {
          $c++ ;
          require XML::Smart::Base64 ;
          my $base64 = &XML::Smart::Base64::encode_base64($value) ;
          $base64 =~ s/\s$//s ;
          $tags .= qq`$ident<$tag dt:dt="binary.base64">$base64</$tag>`;
          $v = $value if $c == 1 ;
        }
      }
    }

    if ($c <= 1  && ! $$prev_tree{'/nodes'}{$tag}) {
      my $k = $stat[4] ? $tag : &_check_key($tag) ;
      if    ($stat[3] == 1) { $k = "\L$k\E" ;}
      elsif ($stat[3] == 2) { $k = "\U$k\E" ;}
      delete $$parsed{"$tree"} ;
      return " $k=" . &_add_quote($v) ;
    }
    else { $$data .= $tags ;}
  }
  elsif (ref($tree) eq 'SCALAR') {
    my $k = $stat[4] ? $tag : &_check_key($tag) ;
    if    ($stat[3] == 1) { $k = "\L$k\E" ;}
    elsif ($stat[3] == 2) { $k = "\U$k\E" ;}
    delete $$parsed{"$tree"} ;
    return " $k=" . &_add_quote($$tree) ;
  }
  elsif (ref($tree)) {
    my $k = $stat[4] ? $tag : &_check_key($tag) ;
    if    ($stat[3] == 1) { $k = "\L$k\E" ;}
    elsif ($stat[3] == 2) { $k = "\U$k\E" ;}
    delete $$parsed{"$tree"} ;
    return " $k=" . &_add_quote("$tree") ;
  }

  delete $$parsed{"$tree"} ;
  return ;
}

##############
# _DATA_TYPE #
##############

sub _data_type {
  return 4 if ($_[0] =~ /[^\w\d\s!"#\$\%&'\(\)\*\+,\-\.\/:;<=>\?\@\[\\\]\^\`\{\|}~€‚ƒ„…†‡ˆ‰Š‹ŒŽ‘’“”•–—˜™š›œžŸ¡¢£¤¥¦§¨©ª«¬­®¯°±²³´µ¶·¸¹º»¼½¾¿ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜÝÞßàáâãäåæçèéêëìíîïðñòóôõö÷øùúûüýþÿ]/s) ;
  return 3 if ($_[0] =~ /<.*?>/s) ;
  return 2 if ($_[0] =~ /[\r\n\t]/s) ;
  return 1 ;
}

##############
# _CHECK_TAG #
##############

sub _check_tag { &_check_key ;}

##############
# _CHECK_KEY #
##############

sub _check_key {
  if ($_[0] =~ /(?:^[.:-]|[^\w\:\.\-])/s) {
    my $k = $_[0] ;
    $k =~ s/^[.:-]+//s ;
    $k =~ s/[^\w\:\.\-]+/_/gs ;
    return( $k ) ;
  }
  return( $_[0] ) ;
}

#######################
# _PARSE_BASIC_ENTITY #
#######################

sub _parse_basic_entity {
  $_[0] =~ s/&lt;/</gs ;
  $_[0] =~ s/&gt;/>/gs ;
  $_[0] =~ s/&amp;/&/gs ;
  $_[0] =~ s/&apos;/'/gs ;
  $_[0] =~ s/&quot;/"/gs ;
  
  $_[0] =~ s/&#(\d+);/ $1 > 255 ? pack("U",$1) : pack("C",$1)/egs ;
  $_[0] =~ s/&#x([a-fA-F\d]+);/pack("U",hex($1))/egs ;
  
  return( $_[0] ) ;
}

#####################
# _ADD_BASIC_ENTITY #
#####################

sub _add_basic_entity {
  $_[0] =~ s/(&(?:\w+;)?)/{_is_amp($1) or $1}/sgex ;
  $_[0] =~ s/</&lt;/gs ;
  $_[0] =~ s/>/&gt;/gs ;
  return( $_[0] ) ;
}

###########
# _IS_AMP #
###########

sub _is_amp {
  if ($_[0] eq '&') { return( '&amp;' ) ;}
  return( undef ) ;
}

##############
# _ADD_QUOTE #
##############

sub _add_quote {
  my ($data) = @_ ;
  $data =~ s/\\$/\\\\/s ;
  
  &_add_basic_entity($data) ;
  
  my $q1 = 1 if $data =~ /"/s ;
  my $q2 = 1 if $data =~ /'/s ;
  
  if (!$q1 && !$q2) { return( qq`"$data"` ) ;}
  
  if ($q1 && $q2) {
    $data =~ s/"/&quot;/gs ;
    return( qq`"$data"` ) ;
  }
  
  if ($q1) { return( qq`'$data'` ) ;}
  if ($q2) { return( qq`"$data"` ) ;}

  return( qq`"$data"` ) ;
}

#######
# END #
#######

1;


