#############################################################################
## Name:        Tie.pm
## Purpose:     XML::Smart::Tie - (XML::Smart::Tie::Array & XML::Smart::Tie::Hash)
## Author:      Graciliano M. P.
## Modified by:
## Created:     28/09/2003
## RCS-ID:      
## Copyright:   (c) 2003 Graciliano M. P.
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################

package XML::Smart::Tie ;

use strict ;
no warnings ;

######################
# _GENERATE_NULLTREE #
######################

sub _generate_nulltree {
  my $saver = shift ;
  my ( $K , $I ) = @_ ;
  if ( !$saver->{keyprev} ) {
    $saver->{null} = 0 ;
    return ;
  }
  
  my @tree = @{$saver->{keyprev}} ;
  if (!@tree) {
    $saver->{null} = 0 ;
    return ;  
  }
  
  if ( $I > 0 ) { push(@tree , "[$I]") ;}
  
  my $tree = $saver->{tree} ;
  
  my ($keyprev , $treeprev , $array , $key , $i) ;
  foreach my $tree_i ( @tree ) {
    if (ref($tree) ne 'HASH' && ref($tree) ne 'ARRAY') {
      my $cont = $$treeprev{$keyprev} ;
      $$treeprev{$keyprev} = {} ;
      $$treeprev{$keyprev}{CONTENT} = $cont ;
    }
      
    if ($tree_i =~ /^\[(\d+)\]$/) {
      $i = $1 ;
      if (exists $$treeprev{$keyprev}) {
        if (ref $$treeprev{$keyprev} ne 'ARRAY') {
          my $prev = $$treeprev{$keyprev} ;
          $$treeprev{$keyprev} = [$prev] ;
        }
      }
      else { $$treeprev{$keyprev} = [] ;}
      
      if (!exists $$treeprev{$keyprev}[$i]) { $$treeprev{$keyprev}[$i] = {} ;}
      
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
      if (exists $$tree{$tree_i}) {
        if (ref $$tree{$tree_i} ne 'HASH' && ref $$tree{$tree_i} ne 'ARRAY') {
          if ( $$tree{$tree_i} ne '' ) {
            my $cont = $$tree{$tree_i} ;
            $$tree{$tree_i} = {} ;
            $$tree{$tree_i}{CONTENT} = $cont ;
          }
          else { $$tree{$tree_i} = {} ;}
        }
      }
      else {
        push( @{ $$treeprev{$keyprev}{'/order'} }  , $tree_i) if $treeprev ;
        $$tree{$tree_i} = {} ;
      }
      $keyprev = $tree_i ;
      $treeprev = $tree ;
      $tree = $$tree{$tree_i} ;
      $array = undef ;
      $key = $tree_i ;
    }
  }
  
  #use Data::Dumper ; print Dumper( $saver->{tree} , $tree );
  
  $saver->{point} = $tree ;
  $saver->{back} = $treeprev ;
  $saver->{array} = $array ;
  $saver->{key} = $key ;
  $saver->{i} = $i ;

  $saver->{null} = 0 ;

  return( 1 ) ;
}

#################
# _DELETE_XPATH #
#################

sub _delete_XPATH {
  my $xpath = delete $_[0]->{XPATH} ;
  $$xpath = undef ;
}

##########################
# XML::SMART::TIE::ARRAY #
##########################

package XML::Smart::Tie::Array ;

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
  
  #print "A-FETCH>> $key , $i >> @{$this->{saver}->{keyprev}} [$this->{saver}->{null}]\n" ;
  
  if ($this->{saver}->{array}) {
    if (!exists $this->{saver}->{array}[$i] ) {
      return &XML::Smart::clone($this->{saver},"/[$i]") ;
    }
    $point = $this->{saver}->{array}[$i] ;
  }
  elsif (exists $this->{saver}->{back}{$key}) {
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
  
  #print "A-STORE>> $key , $i >> @{$this->{saver}->{keyprev}} >> [$this->{saver}->{array}]\n" ;
  
  if ( $this->{saver}->{null} ) {
    &XML::Smart::Tie::_generate_nulltree($this->{saver},$key,$i) ;
  }

  &XML::Smart::Tie::_delete_XPATH($this->{saver}) ;
  
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
    if (exists $this->{saver}->{back}{$key}) {
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
  elsif ($i == 0 && exists $this->{saver}->{back}{$key}) { return 1 ;}

  ## Always return 1! Then when the FETCH(0) is made, it returns a NULL object.
  ## This will avoid warnings!
  return 1 ;
}

sub EXISTS {
  my $this = shift ;
  my $i = shift ;
  my $key = $this->{saver}->{key} ;
  
  if ($this->{saver}->{array}) {
    if (exists $this->{saver}->{array}[$i]) { return 1 ;}
  }
  elsif ($i == 0 && exists $this->{saver}->{back}{$key}) { return 1 ;}
  
  return ;
}

sub DELETE {
  my $this = shift ;
  my $i = shift ;
  my $key = $this->{saver}->{key} ;
  
  &XML::Smart::Tie::_delete_XPATH($this->{saver}) ;
                              
  if ($this->{saver}->{array}) {
    if (exists $this->{saver}->{array}[$i]) {
      return delete $this->{saver}->{array}[$i] ;
    }
  }
  elsif ($i == 0 && exists $this->{saver}->{back}{$key}) {
    my $k = $this->{saver}->{back}{$key} ;
    delete $this->{saver}->{back}{$key} ;
    return $k  ;
  }
  
  return ;
}

sub CLEAR {
  my $this = shift ;
  my $key = $this->{saver}->{key} ;
  
  &XML::Smart::Tie::_delete_XPATH($this->{saver}) ;
  
  if ($this->{saver}->{array}) {
    return @{$this->{saver}->{array}} = () ;
  }
  elsif (exists $this->{saver}->{back}{$key}) {
    return $this->{saver}->{back}{$key} = () ;
  }
  
  return ;
}

sub PUSH {
  my $this = shift ;
  my $key = $this->{saver}->{key} ;

  #print "PUSH>> $key >> @{$this->{saver}->{keyprev}}\n" ;

  if ( $this->{saver}->{null} ) {
    &XML::Smart::Tie::_generate_nulltree($this->{saver},$key) ;
  }
  
  &XML::Smart::Tie::_delete_XPATH($this->{saver}) ;

  if ( !$this->{saver}->{array} ) {  
    if (exists $this->{saver}->{back}{$key}) {
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
    &XML::Smart::Tie::_generate_nulltree($this->{saver},$key) ;
  }
  
  &XML::Smart::Tie::_delete_XPATH($this->{saver}) ;

  if ( !$this->{saver}->{array} ) {
    if (exists $this->{saver}->{back}{$key}) {
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
    &XML::Smart::Tie::_generate_nulltree($this->{saver},$key) ;
  }
  
  &XML::Smart::Tie::_delete_XPATH($this->{saver}) ;

  if ( !$this->{saver}->{array} ) {
    if (exists $this->{saver}->{back}{$key}) {
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
  
  &XML::Smart::Tie::_delete_XPATH($this->{saver}) ;

  my $pop ;

  if (!$this->{saver}->{array} && exists $this->{saver}->{back}{$key}) {
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
  
  &XML::Smart::Tie::_delete_XPATH($this->{saver}) ;

  my $shift ;

  if (!$this->{saver}->{array} && exists $this->{saver}->{back}{$key}) {
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

#########################
# XML::SMART::TIE::HASH #
#########################

package XML::Smart::Tie::Hash ;

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
  elsif ( exists $this->{saver}->{point}{$key} ) {
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
   
  if (!$this->{saver}->{keyorder}) { $this->_keyorder ;}
  
  return( @{$this->{saver}->{keyorder}}[0] ) ; 
}

sub NEXTKEY  {
  my $this = shift ;
  my ( $key ) = @_ ;
  
  if (!$this->{saver}->{keyorder}) { $this->_keyorder ;}
    
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

  #print "H-STORE>> $key , $i >> @{$this->{saver}->{keyprev}} >> [$this->{saver}->{null}]\n" ;
  
  if ( $this->{saver}->{null} ) {
    &XML::Smart::Tie::_generate_nulltree($this->{saver},$key) ;
  }
  
  &XML::Smart::Tie::_delete_XPATH($this->{saver}) ;
  
  if ( ref($this->{saver}->{point}{$key}) eq 'ARRAY' ) {
    return $this->{saver}->{point}{$key}[0] = $_[0] ;
  }
  else {
    if ( defined $this->{saver}->{content} && ( keys %{$this->{saver}->{point}} ) < 1 ) {
      my $prev_key = $this->{saver}->{key} ;
      $this->{saver}->{back}{$prev_key} = {} ;
      $this->{saver}->{back}{$prev_key}{CONTENT} = ${$this->{saver}->{content}} ;
      delete $this->{saver}->{content} ;
      $this->{saver}->{point} = $this->{saver}->{back}{$prev_key} ;
    }
    
    if ( !exists $this->{saver}->{point}{$key} ) {
      if ($key ne '/order' && $key ne '/nodes') {
        if (!$this->{saver}->{keyorder}) { $this->_keyorder ;}
        push(@{$this->{saver}->{keyorder}} , $key) ;
        push(@{$this->{saver}->{point}{'/order'}} , $key) ;
      }
    }
    return $this->{saver}->{point}{$key} = $_[0] ;
  }
  return ;
}

sub DELETE   {
  my $this = shift ;
  my ( $key ) = @_ ;
  
  if ( exists $this->{saver}->{point}{$key} ) {
    &XML::Smart::Tie::_delete_XPATH($this->{saver}) ;
    $this->{saver}->{keyorder} = undef ;
    return delete $this->{saver}->{point}{$key} ;
  }
  
  return ;
}

sub CLEAR {
  my $this = shift ;
  &XML::Smart::Tie::_delete_XPATH($this->{saver}) ;
  $this->{saver}->{keyorder} = undef ;
  %{$this->{saver}->{point}} = () ;
}

sub EXISTS {
  my $this = shift ;
  my ( $key ) = @_ ;
  if ( exists $this->{saver}->{point}{$key} ) { return( 1 ) ;}
  return ;
}

sub UNTIE {}
sub DESTROY  {}

sub _keyorder {
  my $this = shift ;
  my @order ;
  
  if ( $this->{saver}->{point}{'/order'} ) {
    my %keys ;
    foreach my $keys_i ( @{ $this->{saver}->{point}{'/order'} } , sort keys %{ $this->{saver}->{point} } ) {
      if ($keys_i eq '' || $keys_i eq '/order' || $keys_i eq '/nodes') { next ;}
      if ( !$keys{$keys_i} ) {
        push(@order , $keys_i) ;
        $keys{$keys_i} = 1 ;
      }
    }
  }
  else {
    foreach my $Key ( sort keys %{ $this->{saver}->{point} } ) {
      if ($Key eq '' || $Key eq '/order' || $Key eq '/nodes') { next ;}
      push(@order , $Key) ;
    }
  }

  $this->{saver}->{keyorder} = \@order ;
}

#######
# END #
#######

1;


