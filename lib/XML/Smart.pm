#############################################################################
## Name:        Smart.pm
## Purpose:     XML::Smart
## Author:      Graciliano M. P.
## Modified by:
## Created:     10/05/2003
## RCS-ID:      
## Copyright:   (c) 2003 Graciliano M. P.
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################

package XML::Smart ;
use 5.006 ;

no warnings ;

use Object::MultiType ;
use vars qw(@ISA) ;
@ISA = qw(Object::MultiType) ;

use XML::Smart::Tree ;

our ($VERSION) ;
$VERSION = '1.1' ;

#######
# NEW #
#######

sub new {
  my $class = shift ;
  my $file = shift ;
  my ( $parser ) = @_ ;
  
  my $this = Object::MultiType->new(
  scalarsub => \&content ,
  tiearray  => 'XML::Smart::TieArray' ,
  tiehash   => 'XML::Smart::TieHash' ,
  tieonuse  => 1 ,
  code      => \&find_arg , 
  ) ;
  
  my $parser = &XML::Smart::Tree::load($parser) ;
  
  if ($file eq '') { $$this->{tree} = {} ;}
  else { $$this->{tree} = &XML::Smart::Tree::parse($file,$parser) ;}

  $$this->{point} = $$this->{tree} ;
  
  bless($this,$class) ;
}

#########
# CLONE #
#########

sub clone {
  my $saver = shift ;
  
  my ($pointer , $back , $array , $key , $i , $null_clone) ;

  if ($#_ == 0 && !ref $_[0]) {
    my $nullkey = shift ;
    $pointer = {} ;
    $back = {} ;
    $null_clone = 1 ;
    
    ($i) = ( $nullkey =~ /(?:^|\/)\/\[(\d+)\]$/s );
    ($key) = ( $nullkey =~ /(.*?)(?:\/\/\[\d+\])?$/s );
    if ($key =~ /^\/\[\d+\]$/) { $key = undef ;}
  }

  else {
    $pointer = shift ;
    $back = shift ;
    $array = shift ;
    $key = shift ;
    $i = shift ;
  }

  my $clone = Object::MultiType->new(
  scalarsub => \&content ,
  tiearray  => 'XML::Smart::TieArray' ,
  tiehash   => 'XML::Smart::TieHash' ,
  tieonuse  => 1 ,
  code      => \&find_arg ,
  ) ;
  bless($clone,__PACKAGE__) ;  
  
  if ( !$saver->is_saver ) { $saver = $$saver ;}
  
  if (!$back) {
    if (!$pointer) { $back = $saver->{back} ;}
    else { $back = $saver->{point} ;}
  }
  
  if (!$array && !$pointer) { $array = $saver->{array} ;}

  my @keyprev ;

  if (defined $key) { @keyprev = $key ;}
  elsif (defined $i) { @keyprev = "[$i]" ;}

  if (!defined $key) { $key = $saver->{key} ;}
  if (!defined $i) { $i = $saver->{i} ;}
  
  if (!$pointer) { $pointer = $saver->{point} ;}
  
  #my @call = caller ;
  #print "CLONE>> $key , $i >> @{$saver->{keyprev}}\n" ;

  $$clone->{tree} = $saver->{tree} ;
  $$clone->{point} = $pointer ;
  $$clone->{back} = $back ;
  $$clone->{array} = $array ;
  $$clone->{key} = $key ;
  $$clone->{i} = $i ;
  
  if ( @keyprev ) {
    $$clone->{keyprev} = [@{$saver->{keyprev}}] ;
    push(@{$$clone->{keyprev}} , @keyprev) ;
  }
  
  if (defined $_[0]) { $$clone->{content} = \$_[0] ;}

  if ( $null_clone || defined $saver->{null} ) {
    $$clone->{null} = 1 ;
    ## $$clone->{self} = $clone ;
  }
  
  return( $clone ) ;
}

########
# TREE #
########

sub tree { return( ${$_[0]}->{tree} ) ;}

########
# FIND #
########

sub find { &find_arg } ;

############
# FIND_ARG #
############

sub find_arg {
  my $this = shift ;
  my ($name , $type , $value) = @_ ;
  $type =~ s/\s//gs ;

  my $key = $$this->{key} ;

  my @hashes ;
  
  if (ref($$this->{array})) {
    push(@hashes , @{$$this->{array}}) ;
  }
  else { push(@hashes , $$this->{point}) ;}

  my $i = -1 ;
  my (@hash , @i) ;
  my $notwant = !wantarray ;

  foreach my $hash_i ( @hashes ) {
    $i++ ;
    if    ($type eq 'eq'  && $$hash_i{$name} eq $value)     { push(@hash,$hash_i) ; push(@i,$i) ; last if $notwant ;}
    elsif ($type eq 'ne'  && $$hash_i{$name} ne $value)     { push(@hash,$hash_i) ; push(@i,$i) ; last if $notwant ;}
    elsif ($type eq '=='  && $$hash_i{$name} == $value)     { push(@hash,$hash_i) ; push(@i,$i) ; last if $notwant ;}
    elsif ($type eq '!='  && $$hash_i{$name} != $value)     { push(@hash,$hash_i) ; push(@i,$i) ; last if $notwant ;}
    elsif ($type eq '<='  && $$hash_i{$name} <= $value)     { push(@hash,$hash_i) ; push(@i,$i) ; last if $notwant ;}
    elsif ($type eq '>='  && $$hash_i{$name} >= $value)     { push(@hash,$hash_i) ; push(@i,$i) ; last if $notwant ;}
    elsif ($type eq '<'   && $$hash_i{$name} <  $value)     { push(@hash,$hash_i) ; push(@i,$i) ; last if $notwant ;}
    elsif ($type eq '>'   && $$hash_i{$name} >  $value)     { push(@hash,$hash_i) ; push(@i,$i) ; last if $notwant ;}
    elsif ($type eq '=~'  && $$hash_i{$name} =~ /$value/s)  { push(@hash,$hash_i) ; push(@i,$i) ; last if $notwant ;}
    elsif ($type eq '=~i' && $$hash_i{$name} =~ /$value/i)  { push(@hash,$hash_i) ; push(@i,$i) ; last if $notwant ;}
  }
                           
  my $back = $$this->{back} ;
  
  #print "FIND>> @{$$this->{keyprev}} >> $i\n" ;
  
  if (@hash) {
    if ($notwant) {
      return &XML::Smart::clone($this,$hash[0],$back,undef,undef, $i[0]) ;
    }
    else {
      my $c = -1 ;
      foreach my $hash_i ( @hash ) {
        $c++ ;
        $hash_i = &XML::Smart::clone($this,$hash_i,$back,undef,undef,$c) ;
      }
      return( @hash ) ;
    }
  }
  return &XML::Smart::clone($this,'') ;
}

###########
# CONTENT #
###########

sub content {
  my $this = shift ;
  
  if ( defined $$this->{content} ) {
    return ${$$this->{content}} ;
  }
  
  my $key = 'CONTENT' ;
  my $i = $$this->{i} ;
  
  if (ref($$this->{point}{$key}) eq 'ARRAY') {
    if ($i eq '') { $i = 0 ;}
    return $$this->{point}{$key}[$i] ;
  }
  elsif (defined $$this->{point}{$key}) {
    return $$this->{point}{$key} ;
  }
  
  return '' ;
}

########
# SAVE #
########

sub save {
  my $this = shift ;
  my ( $file ) = @_ ;
  
  if (-d $file || !-w $file) { return ;}
  
  my ($data,$unicode) = $this->data(@_) ;
  
  my $fh ;
  open ($fh,">$file") ; binmode($fh) if $unicode ;
  print $fh $data ;
  close ($fh) ;
  
  return( 1 ) ;
}

########
# DATA #
########

sub data {
  my $this = shift ;
  my ( %args ) = @_ ;
  
  my $tree = $this->tree ;
  
  {
    my $addroot ;
    
    if ( ref $tree ne 'HASH' ) { $addroot = 1 ;}
    else {
      my $ks = keys %$tree ;
      if ($ks > 1) { $addroot = 1 ;}
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
        elsif (ref $$tree{$k} ne 'HASH') { $addroot = 1 ;}
      }
    }
    
    if ($addroot) { $tree = {root => $tree} ;}  
  }
  
  if ( $args{lowtag} ) { $args{lowtag} = 1 ;}
  if ( $args{upertag} ) { $args{lowtag} = 2 ;}
  
  if ( $args{lowarg} ) { $args{lowarg} = 1 ;}
  if ( $args{uperarg} ) { $args{lowarg} = 2 ;}

  my ($data,$unicode) ;
  {
    my $parsed = {} ;
    $unicode = &_data(\$data,$tree,'',-1, $parsed , $args{noident} , $args{nospace} , $args{lowtag} , $args{lowarg} ) ;
    $data .= "\n" ;
  }

  my $enc = 'iso-8859-1' ;
  if ($unicode) { $enc = 'utf8' ;}
  
  my $length ;
  if ( $args{length} ) { $length = ' length="' . length($data) . '"' ;}
  
  my $xml = qq`<?xml version="1.0" encoding="$enc"$length?>` ;
  
  if ( $args{noheader} ) { $xml = '' ;}
  
  $data = $xml . $data ;
  
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
      if ($Key eq '') { next ;}
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

#########
# _DATA #
#########

sub _data {
  my ( $data , $tree , $tag , $level , $parsed , @stat ) = @_ ;
  
  if ($$parsed{"$tree"}) { return ;}
  $$parsed{"$tree"}++ ;
  
  my $ident = "\n" ;
  $ident .= '  ' x $level if !$stat[0] ;
  
  if ($stat[1]) { $ident = '' ;}
  
  if    ($stat[2] == 1) { $tag = "\L$tag\E" ;}
  elsif ($stat[2] == 2) { $tag = "\U$tag\E" ;}  
  
  if (ref($tree) eq 'HASH') {
    my ($args,$tags,$cont) ;
    
    if (defined $$tree{CONTENT}) { $cont = delete $$tree{CONTENT} ;}
    if (defined $$tree{content}) { $cont .= delete $$tree{content} ;}
    
    if ($cont ne '') { $stat[0] = 1 ; $ident = '' ;}
    
    foreach my $Key (sort keys %$tree ) {
      if ($Key eq '') { next ;}
      if (ref($$tree{$Key})) {
        $args .= &_data(\$tags,$$tree{$Key},$Key, $level+1 , $parsed , @stat) ;
      }
      elsif ("\L$Key\E" eq 'content') { $cont .= $$tree{$Key} ;}
      else {
        my $tp = _data_type($$tree{$Key}) ;
        if    ($tp == 1) {
          my $k = $Key ;
          if    ($stat[3] == 1) { $k = "\L$Key\E" ;}
          elsif ($stat[3] == 2) { $k = "\U$Key\E" ;}
          $args .= qq` $k="$$tree{$Key}"` ;
        }
        elsif ($tp == 2) {
          my $k = $Key ;
          if    ($stat[2] == 1) { $k = "\L$Key\E" ;}
          elsif ($stat[2] == 2) { $k = "\U$Key\E" ;}
          $tags .= qq`$ident <$k>$$tree{$Key}</$k>`;
        }
      }
    }
    
    if ($args ne '' && $tags ne '') {
      $$data .= qq`$ident<$tag$args>` if $tag ne '' ;
      $$data .= $tags ;
      $$data .= $cont ;
      $$data .= qq`$ident</$tag>` if $tag ne '' ;
    }
    elsif ($args ne '' && $cont ne '') {
      $$data .= qq`$ident<$tag$args>` if $tag ne '' ;
      $$data .= $cont ;
      $$data .= qq`$ident</$tag>` if $tag ne '' ;
    }
    elsif ($args ne '') {
      $$data .= qq`$ident<$tag$args/>`;
    }
    elsif ($tags ne '') {
      $$data .= qq`$ident<$tag>` if $tag ne '' ;
      $$data .= $tags ;
      $$data .= $cont ;
      $$data .= qq`$ident</$tag>` if $tag ne '' ;
    }
  }
  elsif (ref($tree) eq 'ARRAY') {
    my ($c,$v,$tags) ;
    foreach my $value (@$tree) {
      if (ref($value)) {
        if (ref($value) ne 'ARRAY') {
          $c = 2 ;
          &_data($data,$value,$tag,$level+1, $parsed , @stat) ;
        }
      }
      elsif ($value ne '') {
        my $tp = _data_type($value) ;
        if ($tp <= 2) {
          $c++ ;
          $tags .= qq`$ident<$tag>$value</$tag>`;
          $v = $value if $c == 1 ;
        }
      }
    }
    if ($c <= 1) {
      if    ($stat[3] == 1) { $tag = "\L$tag\E" ;}
      elsif ($stat[3] == 2) { $tag = "\U$tag\E" ;}
      delete $$parsed{"$tree"} ;
      return qq` $tag="$v"` ;
    }
    else { $$data .= $tags ;}
  }
  elsif (ref($tree) eq 'SCALAR') { delete $$parsed{"$tree"} ; return( $$tree ) ;}

  delete $$parsed{"$tree"} ;
  return ;
}

##############
# _DATA_TYPE #
##############

sub _data_type {
  if ($_[0] =~ /[\t\r\n\/]/s) {
    return 2 if ($_[0] =~ /[^\w\d\s\-\!"#\$%&'\(\)\*\+,\.:;=\?\@\[\\\]\^\{\|}~`ÀÁÂÃÄÇÈÉÊËÌÍÎÏÑÒÓÔÕÖÙÚÛÜÝàáâãäçèéêëìíîïñòóôõöùúûüýÿ€ƒ©]/s) ;
    return 2 ;
  }
  return 1 ;
}

######################
# _GENERATE_NULLTREE #
######################

sub _generate_nulltree {
  my $saver = shift ;
  my ( $K , $I ) = @_ ;
  if ( !$saver->{keyprev} ) { return ;}
  
  my @tree = @{$saver->{keyprev}} ;
  if ( $I > 0 ) { push(@tree , "[$I]") ;}
  
  #print ">> @tree >> $K , $I\n" ;
  
  my $tree = $saver->{tree} ;
  
  my ($keyprev , $treeprev , $array , $key , $i) ;
  foreach my $tree_i ( @tree ) {

    if (ref $tree ne 'HASH' && ref $tree ne 'ARRAY') {
      my $cont = $$treeprev{$keyprev} ;
      $$treeprev{$keyprev} = {} ;
      $$treeprev{$keyprev}{CONTENT} = $cont ;
    }
      
    if ($tree_i =~ /^\[(\d+)\]$/) {
      $i = $1 ;
      if (defined $$treeprev{$keyprev}) {
        if (ref $$treeprev{$keyprev} ne 'ARRAY') {
          my $prev = $$treeprev{$keyprev} ;
          $$treeprev{$keyprev} = [$prev] ;
        }
      }
      else { $$treeprev{$keyprev} = [] ;}
      
      if (!defined $$treeprev{$keyprev}[$i]) { $$treeprev{$keyprev}[$i] = {} ;}
      
      my $prev = $tree ;
      $tree = $$treeprev{$keyprev}[$i] ;
      $array = $$treeprev{$keyprev} ;
      $treeprev = $prev ;
    }
    elsif (ref $tree eq 'ARRAY') {
      my $prev = $tree ;
      $tree = $$treeprev{$keyprev}[0] ;
      $array = $$treeprev{$keyprev} ;
      $treeprev = $prev ;
    }
    else {
      if (defined $$tree{$tree_i}) {
        if (ref $$tree{$tree_i} ne 'HASH' && ref $$tree{$tree_i} ne 'ARRAY') {
          if ( $$tree{$tree_i} ne '' ) {
            my $cont = $$tree{$tree_i} ;
            $$tree{$tree_i} = {} ;
            $$tree{$tree_i}{CONTENT} = $cont ;
          }
          else { $$tree{$tree_i} = {} ;}
        }
      }
      else { $$tree{$tree_i} = {} ;}
      $keyprev = $tree_i ;
      $treeprev = $tree ;
      $tree = $$tree{$tree_i} ;
      $key = $tree_i ;
    }
  }
  
  $saver->{point} = $tree ;
  $saver->{back} = $treeprev ;
  $saver->{array} = $array ;
  $saver->{key} = $key ;
  $saver->{i} = $i ;

  $saver->{null} = 0 ;

  return( 1 ) ;
}

###########
# DESTROY #
###########

sub DESTROY {
  my $this = shift ;
  $$this->clean ;
}

########################
# XML::SMART::TIEARRAY #
########################

package XML::Smart::TieArray ;

sub TIEARRAY {
  my $class = shift ;
  my $saver = shift ;
  my $this = { saver => $saver } ;
  bless($this,$class) ;
}

sub FETCH {
  my $this = shift ;
  my ($i) = @_ ;
  my $key = $this->{saver}->{key} ;
  
  my $point = '' ;
  
  #print ">> @{$this->{saver}->{keyprev}}\n" ;
  
  if ($this->{saver}->{array}) {
    if (!defined $this->{saver}->{array}[$i] ) {
      return &XML::Smart::clone($this->{saver},"/[$i]") ;
    }
    $point = $this->{saver}->{array}[$i] ;
  }
  elsif (defined $this->{saver}->{back}{$key}) {
    if (ref $this->{saver}->{back}{$key} eq 'ARRAY') {
      $point = $this->{saver}->{back}{$key}[$i] ;
    }
    else {
      if ($i == 0) { $point = $this->{saver}->{back}{$key} ;}
      else { return &XML::Smart::clone($this->{saver},"/[$i]") ;}
    }
  }  
  else {
    return &XML::Smart::clone($this->{saver},"/[$i]") ;
  }
  
  if (ref $point) {
    return &XML::Smart::clone($this->{saver},$point,undef,undef,undef,$i) ;
  }
  else {
    return &XML::Smart::clone($this->{saver},    {},undef,undef,undef,$i,$point) ;
  }
}

sub STORE {
  my $this = shift ;
  my $i = shift ;
  my $key = $this->{saver}->{key} ;
  
  if ( $this->{saver}->{null} ) {
    &XML::Smart::_generate_nulltree($this->{saver},$key,$i) ;
  }
  
  if ($this->{saver}->{array}) {
    return $this->{saver}->{array}[$i] = $_[0] ;
  }
  elsif ($i == 0) {
    if (ref $this->{saver}->{back}{$key} eq 'ARRAY') {
      return $this->{saver}->{back}{$key}[0] = $_[0] ;
    }
    else {
      return $this->{saver}->{back}{$key} = $_[0] ;    
    }
  }
  else {
    if (defined $this->{saver}->{back}{$key}) {
      my $k = $this->{saver}->{back}{$key} ;
      $this->{saver}->{back}{$key} = [$k] ;
    }
    else { $this->{saver}->{back}{$key} = [] ;}
    $this->{saver}->{array} = $this->{saver}->{back}{$key} ;
    return $this->{saver}->{array}[$i] = $_[0] ;
  }

  return ;
}

sub FETCHSIZE {
  my $this = shift ;
  my $i = shift ;
  my $key = $this->{saver}->{key} ;
  
  my @call = caller ;

  if ($this->{saver}->{array}) {
    return( $#{$this->{saver}->{array}} + 1 ) ;
  }
  elsif ($i == 0 && defined $this->{saver}->{back}{$key}) { return 1 ;}

  ## Always return 1! Then when the FETCH(0) is made, it returns a NULL object.
  ## This will avoid warnings!
  return 1 ;
}

sub EXISTS {
  my $this = shift ;
  my $i = shift ;
  my $key = $this->{saver}->{key} ;
  
  if ($this->{saver}->{array}) {
    if (defined $this->{saver}->{array}[$i]) { return 1 ;}
  }
  elsif ($i == 0 && defined $this->{saver}->{back}{$key}) { return 1 ;}
  
  return ;
}

sub DELETE {
  my $this = shift ;
  my $i = shift ;
  my $key = $this->{saver}->{key} ;
                              
  if ($this->{saver}->{array}) {
    if (defined $this->{saver}->{array}[$i]) {
      return delete $this->{saver}->{array}[$i] ;
    }
  }
  elsif ($i == 0 && defined $this->{saver}->{back}{$key}) {
    my $k = $this->{saver}->{back}{$key} ;
    $this->{saver}->{back}{$key} = undef ;
    return $k ;
  }
  
  return ;
}

sub CLEAR {
  my $this = shift ;
  my $key = $this->{saver}->{key} ;
  
  if ($this->{saver}->{array}) {
    return @{$this->{saver}->{array}} = () ;
  }
  elsif (defined $this->{saver}->{back}{$key}) {
    return $this->{saver}->{back}{$key} = undef ;
  }
  
  return ;
}

sub PUSH {
  my $this = shift ;
  my $key = $this->{saver}->{key} ;

  #print "PUSH>> $key >> @{$this->{saver}->{keyprev}}\n" ;

  if ( $this->{saver}->{null} ) {
    &XML::Smart::_generate_nulltree($this->{saver},$key,$i) ;
  }

  if ( !$this->{saver}->{array} ) {
    if (defined $this->{saver}->{back}{$key}) {
      if ( ref $this->{saver}->{back}{$key} ne 'ARRAY' ) {
        my $k = $this->{saver}->{back}{$key} ;
        $this->{saver}->{back}{$key} = [$k] ;      
      }
    }
    else { $this->{saver}->{back}{$key} = [] ;}
    $this->{saver}->{array} = $this->{saver}->{back}{$key} ;
    $this->{saver}->{point} = $this->{saver}->{back}{$key}[0] ;
  }
  
  return push(@{$this->{saver}->{array}} , @_) ;
}

sub UNSHIFT {
  my $this = shift ;
  my $key = $this->{saver}->{key} ;

  if ( $this->{saver}->{null} ) {
    &XML::Smart::_generate_nulltree($this->{saver},$key,$i) ;
  }

  if ( !$this->{saver}->{array} ) {
    if (defined $this->{saver}->{back}{$key}) {
      if ( ref $this->{saver}->{back}{$key} ne 'ARRAY' ) {
        my $k = $this->{saver}->{back}{$key} ;
        $this->{saver}->{back}{$key} = [$k] ;      
      }
    }
    else { $this->{saver}->{back}{$key} = [] ;}
    $this->{saver}->{array} = $this->{saver}->{back}{$key} ;
    $this->{saver}->{point} = $this->{saver}->{back}{$key}[0] ;
  }
  
  return unshift(@{$this->{saver}->{array}} , @_) ;
}

sub SPLICE {
  my $this = shift ;
  my $offset = shift || 0 ;
  my $length = shift || $this->FETCHSIZE() - $offset ;
  
  my $key = $this->{saver}->{key} ;
  
  if ( $this->{saver}->{null} ) {
    &XML::Smart::_generate_nulltree($this->{saver},$key,$i) ;
  }

  if ( !$this->{saver}->{array} ) {
    if (defined $this->{saver}->{back}{$key}) {
      if ( ref $this->{saver}->{back}{$key} ne 'ARRAY' ) {
        my $k = $this->{saver}->{back}{$key} ;
        $this->{saver}->{back}{$key} = [$k] ;      
      }
    }
    else { $this->{saver}->{back}{$key} = [] ;}
    $this->{saver}->{array} = $this->{saver}->{back}{$key} ;
    $this->{saver}->{point} = $this->{saver}->{back}{$key}[0] ;
  }
  
  return splice(@{$this->{saver}->{array}} , $offset , $length , @_) ;
}

sub POP {
  my $this = shift ;
  my $key = $this->{saver}->{key} ;

  my $pop ;

  if (!$this->{saver}->{array} && defined $this->{saver}->{back}{$key}) {
    if ( ref $this->{saver}->{back}{$key} eq 'ARRAY' ) {
      $this->{saver}->{array} = $this->{saver}->{back}{$key} ;
      $this->{saver}->{point} = $this->{saver}->{back}{$key}[0] ;
    }
    else { $pop = delete $this->{saver}->{back}{$key} ;}
  }
  
  if ($this->{saver}->{array}) {
    $pop = pop( @{$this->{saver}->{array}} ) ;
    
    if ( $#{$this->{saver}->{array}} == 0 ) {
      $this->{saver}->{back}{$key} = $this->{saver}->{array}[0] ;
      $this->{saver}->{array} = undef ;
      $this->{saver}->{i} = undef ;
    }
    elsif ( $#{$this->{saver}->{array}} < 0 ) {
      $this->{saver}->{back}{$key} = undef ;
      $this->{saver}->{array} = undef ;
      $this->{saver}->{i} = undef ;
    }
  }
  
  return $pop ;
}

sub SHIFT {
  my $this = shift ;
  my $key = $this->{saver}->{key} ;

  my $shift ;

  if (!$this->{saver}->{array} && defined $this->{saver}->{back}{$key}) {
    if ( ref $this->{saver}->{back}{$key} eq 'ARRAY' ) {
      $this->{saver}->{array} = $this->{saver}->{back}{$key} ;
      $this->{saver}->{point} = $this->{saver}->{back}{$key}[0] ;
    }
    else { $shift = delete $this->{saver}->{back}{$key} ;}
  }
  
  if ($this->{saver}->{array}) {
    $shift = shift( @{$this->{saver}->{array}} ) ;
    
    if ( $#{$this->{saver}->{array}} == 0 ) {
      $this->{saver}->{back}{$key} = $this->{saver}->{array}[0] ;
      $this->{saver}->{array} = undef ;
      $this->{saver}->{i} = undef ;
    }
    elsif ( $#{$this->{saver}->{array}} < 0 ) {
      $this->{saver}->{back}{$key} = undef ;
      $this->{saver}->{array} = undef ;
      $this->{saver}->{i} = undef ;
    }
  }
  
  return $shift ;
}

sub STORESIZE {}
sub EXTEND {}

sub UNTIE {}
sub DESTROY  {}

#######################
# XML::SMART::TIEHASH #
#######################

package XML::Smart::TieHash ;

sub TIEHASH {
  my $class = shift ;
  my $saver = shift ;
  my $this = { saver => $saver } ;
  bless($this,$class) ;
}

sub FETCH {
  my $this = shift ;
  my ( $key ) = @_ ;
  my $i ;

  #print "H-FETCH>> $key , $i >> @{$this->{saver}->{keyprev}}\n" ;

  my $point = '' ;
  my $array ;
  
  if (ref($this->{saver}->{point}{$key}) eq 'ARRAY') {
    $array = $this->{saver}->{point}{$key} ;
    $point = $this->{saver}->{point}{$key}[0] ;
    $i = 0 ;
  }
  elsif ( defined $this->{saver}->{point}{$key} ) {
    $point = $this->{saver}->{point}{$key} ;
  }
  else {
    return &XML::Smart::clone($this->{saver},$key) ;
  }
  
  
  
  if (ref $point) {
    return &XML::Smart::clone($this->{saver},$point,undef,$array,$key,$i) ;
  }
  else {
    return &XML::Smart::clone($this->{saver},{} ,undef,$array,$key,$i,$point) ;
  }
}

sub FIRSTKEY {
  my $this = shift ;
   
  if (!$this->{saver}->{keyorder}) {
    $this->{saver}->{keyorder} = [ sort keys %{ $this->{saver}->{point} } ] ;
  }
  
  return( @{$this->{saver}->{keyorder}}[0] ) ; 
}

sub NEXTKEY  {
  my $this = shift ;
  my ( $key ) = @_ ;
  
  if (!$this->{saver}->{keyorder}) {
    $this->{saver}->{keyorder} = [ sort keys %{ $this->{saver}->{point} } ] ;
  }
  
  my $found ;
  foreach my $key_i ( @{$this->{saver}->{keyorder}} ) {
    if ($found) { return($key_i) ;}
    if ($key eq $key_i) { $found = 1 ;}
  }

  return ;
}

sub STORE {
  my $this = shift ;
  my $key = shift ;
  
  if ( $this->{saver}->{null} ) {
    &XML::Smart::_generate_nulltree($this->{saver},$key,$i) ;
  }
  
  if ( ref($this->{saver}->{point}{$key}) eq 'ARRAY' ) {
    return $this->{saver}->{point}{$key}[0] = $_[0] ;
  }
  else {
    if ( !defined $this->{saver}->{point}{$key} ) {
      if (!$this->{saver}->{keyorder}) {
        $this->{saver}->{keyorder} = [ sort keys %{ $this->{saver}->{point} } ] ;
      }
      push(@{$this->{saver}->{keyorder}} , $key) ;
    }
    return $this->{saver}->{point}{$key} = $_[0] ;
  }
  return ;
}

sub DELETE   {
  my $this = shift ;
  my ( $key ) = @_ ;
  if ( defined $this->{saver}->{point}{$key} ) {
    $this->{saver}->{keyorder} = undef ;
    return delete $this->{saver}->{point}{$key} ;
  }
  return ;
}

sub CLEAR {
  my $this = shift ;
  $this->{saver}->{keyorder} = undef ;
  %{$this->{saver}->{point}} = () ;
}

sub EXISTS {
  my $this = shift ;
  my ( $key ) = @_ ;
  if ( defined $this->{saver}->{point}{$key} ) { return( 1 ) ;}
  return ;
}

sub UNTIE {}
sub DESTROY  {}

#######
# END #
#######

1;

__END__

=head1 NAME

XML::Smart - A smart, easy and powerful way to access/create XML files/data.

=head1 DESCRIPTION

This module has an easy way to access/create XML data. It's based on the HASH
tree that is made of the XML data, and enable a dynamic access to it with the
Perl syntax for Hashe and Array, without needing to care if you have a Hashe or an
Array in the tree. In other words, each point in the tree work as a Hash and
Array at the same time!

=head1 WHY AND HOW IT WORKS

Every one that have tried to use Perl HASH and ARRAY to access the XML data, like in L<XML::Simple>,
have some problems to add new nodes, or to access the node when the user doesn't know if it's
inside an ARRAY, a HASH or a HASH key. I<XML::Smart> create around it a very dynamic way to
access the data, since at the same time any node/point in the tree can be a HASH and
an ARRAY. You also can make a search for nodes that have some attibute:

  my $server = $XML->{server}('type','eq','suse') ; ## This syntax is not wrong! ;-)

  ## Instead of:
  my $server = $XML->{server}[1] ;
  
  __DATA__
  <hosts>
    <server os="linux" type="redhat" version="8.0">
    <server os="linux" type="suse" version="7.0">
  </hosts>

The idea for this module, came from the problem that it has to access a complex struture in XML,
you need to know how is this structure, something that is generally made looking the XML file (what is wrong).
But in the same time is hard to always check (by code) the struture, before access it.
XML is a good and easy format to declare your data, but to extrac it in a tree way, at least in my opinion,
isn't easy. To fix that, came to my mind a way to access the data with some query language, like SQL.
The first idea was to access using something like:

  XML.foo.bar.baz{arg1}

  X = XML.foo.bar*
  X.baz{arg1}
  
  XML.hosts.server[0]{argx}

And saw that this is very similar to Hashes and Arrays in Perl:

  $XML->{foo}{bar}{baz}{arg1} ;
  
  $X = $XML->{foo}{bar} ;
  $X->{baz}{arg1} ;
  
  $XML->{hosts}{server}[0]{argx} ;

But the problem of Hash and Array, is not knowing when you have an Array reference or not.
For example, in XML::Simple:

  ## This is very diffenrent
  $XML->{server}{address} ;
  ## ... of this:
  $XML->{server}{address}[0] ;

So, why don't make both ways work? Because you need to make something crazy!

To create I<XML::Smart>, first I have created the module L<Object::MultiType>.
With it you can have an object that works at the same time as a HASH, ARRAY, SCALAR,
CODE & GLOB. So you can do things like this with the same object:

  $obj = Object::MultiType->new() ;
  
  $obj->{key} ;
  $obj->[0] ;
  $obj->method ;  
  
  @l = @{$obj} ;
  %h = %{$obj} ;
  
  &$obj(args) ;
  
  print $obj "send data\n" ;

Seems be crazy, and can be more if you use tie() inside it, and this is what I<XML::Smart> does.

For I<XML::Smart>, the access in the Hash and Array way paste through tie(). In other words, you have a tied HASH
and tied ARRAY inside it. This tied Hash and Array work together, soo B<you can access a Hash key
as the index 0 of an Array, or access an index 0 as the Hash key>:

  %hash = (
  key => ['a','b','c']
  ) ;
  
  $hash->{key}    ## return $hash{key}[0]
  $hash->{key}[0] ## return $hash{key}[0]  
  $hash->{key}[1] ## return $hash{key}[1]
  
  ## Inverse:
  
  %hash = ( key => 'a' ) ;
  
  $hash->{key}    ## return $hash{key}
  $hash->{key}[0] ## return $hash{key}
  $hash->{key}[1] ## return undef

The best thing of this new resource is to avoid wrong access to the data and warnings when you try to
access a Hash having an Array (and the inverse). Thing that generally make the script die().

Once having an easy access to the data, you can use the same resource to B<create> data!
For example:

  ## Previous data:
  <hosts>
    <server address="192.168.2.100" os="linux" type="conectiva" version="9.0"/>
  </hosts>
  
  ## Now you have {address} as a normal key with a string inside:
  $XML->{hosts}{server}{address}
  
  ## And to add a new address, the key {address} need to be an ARRAY ref!
  ## So, XML::Smart make the convertion: ;-P
  $XML->{hosts}{server}{address}[1] = '192.168.2.101' ;
  
  ## Adding to a list that you don't know the size:
  push(@{$XML->{hosts}{server}{address}} , '192.168.2.102') ;
  
  ## The data now:
  <hosts>
    <server os="linux" type="conectiva" version="9.0"/>
      <address>192.168.2.100</address>
      <address>192.168.2.101</address>
      <address>192.168.2.102</address>
    </server>
  </hosts>

Than after changing your XML tree using the Hash and Array resources you just
get the data remade (through the Hash tree inside the object):

  my $xmldata = $XML->data ;

B<But note that I<XML::Smart> always return an object>! Even when you get a final
key. So this actually returns another object, pointhing (inside it) to the key:

  $addr = $XML->{hosts}{server}{address}[0] ;
  
  ## Since $addr is an object you can TRY to access more data:
  $addr->{foo}{bar} ; ## This doens't make warnings! just return UNDEF.

  ## But you can use like a normal SCALAR too:
  
  print "$addr\n" ;
  
  $addr .= ':80' ; ## After this $addr isn't an object any more, just a SCALAR!

=head1 USAGE

  ## Create the object and load the file:
  my $XML = XML::Smart->new('file.xml') ;
  
  ## Force the use of the parser 'XML::Smart::Parser'.
  my $XML = XML::Smart->new('file.xml' , 'XML::Smart::Parser') ;

  ## Change the root:
  $XML = $XML->{hosts} ;

  ## Get the address [0] of server [0]:
  my $srv0_addr0 = $XML->{server}[0]{address}[0] ;
  ## ...or...
  my $srv0_addr0 = $XML->{server}{address} ;
  
  ## Get the server where the attibute 'type' eq 'suse':
  my $server = $XML->{server}('type','eq','suse') ;
  
  ## Get the address again:
  my $addr1 = $server->{address}[1] ;
  ## ...or...
  my $addr1 = $XML->{server}('type','eq','suse'){address}[1] ;
  
  ## Get all the addresses:
  my @addrs = @{$XML->{server}{address}} ;
  
  ## Add a new server node:
  my $newsrv = {
  os      => 'Linux' ,
  type    => 'Mandrake' ,
  version => 8.9 ,
  address => [qw(192.168.3.201 192.168.3.202)]
  } ;
  
  push(@{$XML->{server}} , $newsrv) ;

  ## Get/rebuild the XML data:
  my $xmldata = $XML->data ;
  
  ## Save in some file:
  $XML->save('newfile.xml') ;
  
  ## Send through a socket:
  print $socket $XML->data(length => 1) ; ## show the 'length' in the XML header to the
                                          ## socket know the amount of data to read.
  
  __DATA__
  <?xml version="1.0" encoding="iso-8859-1"?>
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

=head1 METHODS

=head2 new (FILE|DATA , PARSER)

Create a XML object.

B<Arguments:>

=over 10

=item FILE|DATA

The first argument can be:

  - XML data as string.
  - File path.
  - File Handle (GLOB).

=item PARSER B<(optional)>

Set the XML parser to use. Options:

  XML::Parser
  XML::Smart::Parser

If not set it will look for XML::Parser and load it.
If XML::Parser can't be loaded it will use XML::Smart::Parser, that actually is a
clone of XML::Parser::Lite.

XML::Smart::Parser can only handle basic XML data, but
is a good choice when you don't want to install big modules to parse XML, since it
comes with the main module.

=back

=head2 content

Return the content of a node:

  ## Data:
  <foo>my content</foo>
  
  ## Access:
  
  my $content = $XML->{foo}->content ;
  print "<<$content>>\n" ; ## show: <<my content>>
  
  ## or just:
  my $content = $XML->{foo} ;

=head2 tree

Return the HASH tree of the XML data.

** Note that the real HASH tree is returned here. All the other ways return an
object that works like a HASH/ARRAY through tie.

=head2 data (OPTIONS)

Return the data of the XML object (rebuilding it).

B<Options:>

=over 10

=item noident

If set to true the data isn't idented.

=item nospace

If set to true the data isn't idented and doesn't have space between the
tags (unless the CONTENT have).

=item lowtag

Make the tags lower case.

=item lowarg

Make the arguments lower case.

=item upertag

Make the tags uper case.

=item uperarg

Make the arguments uper case.

=item length

If set true, add the attribute 'length' with the size of the data to the xml header (<?xml ...?>).
This is useful when you send the data through a socket, since the socket can know the total amount
of data to read.

=back

=head2 save (FILEPATH , OPTIONS)

Save the XML data inside a file.

Accept the same OPTIONS of the method B<I<data>>.

=head1 ACCESS

To access the data you use the object in a way similar to HASH and ARRAY:

  my $XML = XML::Smart->new('file.xml') ;
  
  my $server = $XML->{server} ;

But when you get a key {server}, you are actually accessing the data through tie(),
not directly to the HASH tree inside the object, (This will fix wrong accesses): 

  ## {server} is a normal key, not an ARRAY ref:

  my $server = $XML->{server}[0] ; ## return $XML->{server}
  my $server = $XML->{server}[1] ; ## return UNDEF
  
  ## {server} has an ARRAY with 2 items:

  my $server = $XML->{server} ;    ## return $XML->{server}[0]
  my $server = $XML->{server}[0] ; ## return $XML->{server}[0]
  my $server = $XML->{server}[1] ; ## return $XML->{server}[1]

To get all the values of a multiple attribute:

  ## This work having only a string inside {address}, or with an ARRAY ref:
  my @addrsses = @{$XML->{server}{address}} ;

=head2 Select search

When you don't know the position of the nodes, you can select it by some attribute value:

  my $server = $XML->{server}('type','eq','suse') ; ## return $XML->{server}[1]

Syntax for the select search:

  (NAME, CONDITION , VALUE)


=over 10

=item NAME

The attribute name in the node (tag).

=item CONDITION

Can be

  eq  ne  ==  !=  <=  >=  <  >

For REGEX:

  =~  !~
  
  ## Case insensitive:
  =~i !~i

=item VALUE

The value.

For REGEX use like this:

  $XML->{server}('type','=~','^s\w+$') ;

=back

=head2 CONTENT

But if {server} has a content you can access it directly from the variable or
from the method:

  print "Content: $server\n" ;
  ## ...or...
  print "Content: ". $server->content ."\n" ;

So, if you use the object as a string it works as a string! ;-P

=head1 CREATE XML DATA

To create XML data is easy, you just use as a normal HASH, but you don't need
to care with multiple nodes, and ARRAY creation/convertion!

  ## Create a null XML object:
  my $XML = XML::Smart->new() ;
  
  ## Add a server to the list:
  $XML->{server} = {
  os => 'Linux' ,
  type => 'mandrake' ,
  version => 8.9 ,
  address => '192.168.3.201' ,
  } ;
  
  ## The data now:
  <server address="192.168.3.201" os="Linux" type="mandrake" version="8.9"/>
  
  ## Add a new address to the server. Have an ARRAY creation, convertion
  ## of the previous key to ARRAY:
  $XML->{server}{address}[1] = '192.168.3.202' ;
  
  ## The data now:
  <server os="Linux" type="mandrake" version="8.9">
    <address>192.168.3.201</address>
    <address>192.168.3.202</address>
  </server>ok 19

After create your XML tree you just save it or get the data:

  ## Get the data:
  my $data = $XML->data ;
  
  ## Or save it directly:
  $XML->save('newfile.xml') ;
  
  ## Or send to a socket:
  print $socket $XML->data(length => 1) ;


=head1 SEE ALSO

L<XML::Parser>, L<XML::Parser::Lite>, L<XML>.

L<Object::MultiType> - This is the module that make everything possible,
and was created specially for I<XML::Smart>. ;-P

=head1 AUTHOR

Graciliano M. P. <gm@virtuasites.com.br>

I will appreciate any type of feedback (include your opinions and/or suggestions). ;-P

Before make this module I dislike to use XML, and made everything to avoid it.
Now I can use XML fine! ;-P

=head1 COPYRIGHT

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut


