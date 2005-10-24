package Imager::DTP::Letter;
use strict;
use Carp;
use Imager;
use Imager::Matrix2d;
use vars qw($VERSION);

$VERSION = '0.03';

sub new {
	my $self = shift;
	my %o = @_;
	# define properties
	my $p = {
		text           => '',
		font           => '',
		width          => 0,
		height         => 0,
		descent        => 0,
		ascent         => 0,
		advanced_width => 0,
		xscale         => 1,
		yscale         => 1,
		isUpdated      => 0, # check flag for _calcWidthHeight needs
	};
	$self = bless($p,$self);
	# set properties
	$self->setText(text=>$o{text}) if(defined($o{text}));
	$self->setFont(font=>$o{font}) if(defined($o{font}));
	$self->setScale(x=>$o{xscale},y=>$o{yscale}) if($o{xscale} || $o{yscale});
	return $self;
}

sub draw {
	my($self) = shift;
	my %o = $self->_draw_init(@_);
	# recalculate bounding box
	$self->_calcWidthHeight();
	# draw box - for debug mode
	if($o{debug}){
		$o{target}->box(filled=>0,aa=>0,color=>'#999999',xmin=>$o{x},ymin=>$o{y},
		                xmax=>$o{x}+$self->getWidth()-1,ymax=>$o{y}+$self->getAscent()-1);
	}
	# scale transformation
	my($sx,$sy) = $self->getScale();
	if($sx != 1 || $sy != 1){
		my $m = Imager::Matrix2d->scale(x=>$sx,y=>$sy);
		$self->getFont()->transform(matrix=>$m);
	}
	# draw letter - using Imager::String method
	$o{target}->string(%{$o{others}},x=>$o{x},y=>$o{y},text=>$self->getText(),
	                   font=>$self->getFont(),utf8=>1,vlayout=>0,align=>0) or die $o{target}->errstr;
	return 1;
}

sub _draw_init {
	my($self) = shift;
	my %o = @_;
	# validation
	if(!defined($self->getFont()) && !defined($self->getText())){
		confess "you must define both text and font before drawing";
	}
	if(ref($o{target}) !~ /^Imager(::.+)?/){
		confess "target must be an Imager Object ($o{target})";
	}
	$o{x} = 0 if(!$o{x});
	$o{y} = 0 if(!$o{y});
	return %o;
}

sub setText {
	my $self = shift;
	my %o  = @_;
	if($o{text} eq ''){
		confess "text: must define some text";
	}
	$self->{text} = $o{text};
	$self->{isUpdated} = 0;
	return 1;
}

sub setFont {
	my $self = shift;
	my %o  = @_;
	if(!defined($o{font}) || ref($o{font}) !~ /^Imager::Font(::.+)?$/){
		confess "font: must supply an Imager::Font Object ($o{font})";
	}
	$o{font}->{utf8} = 1;
	$o{font}->{vlayout} = 0;
	$self->{font} = $o{font};
	$self->{isUpdated} = 0;
	return 1;
}

sub setScale {
	my $self = shift;
	my %o  = @_;
	# validation
	foreach my $v (qw(x y)){
		if($o{$v} && $o{$v} !~ /^\d+(\.\d+)?$/){
			confess "$v: must be a ratio value (like 0.5, 1.2, and so on)";
		}
	};
	$self->{xscale} = $o{x} if($o{x});
	$self->{yscale} = $o{y} if($o{y});
	$self->{isUpdated} = 0;
	return 1;
}

sub _calcWidthHeight {
	my $self = shift;
	return undef if($self->{isUpdated});
	return undef if($self->getText() eq '' || !$self->getFont());
	my %o  = @_;
	# validation
	foreach my $v (keys %o){
		if($o{$v} !~ /^\d+$/){
			confess "$v: must be an integer ($o{$v})";
		}
	}
	my $f = $self->getFont();
	my $b = $f->bounding_box(string=>$self->getText());
	unless(defined($b->ascent)){
		confess qq(unable to map string '$self->getText()' with the specified font.
		           Perhaps you forgot to encode your text to utf8?
		           *ATTENTION* utf8-flag must be enabled! try using \&utf8::decode() );
	}
	my ($x,$y) = $self->getScale();
	$self->{width}   = ($x != 1)? $b->total_width() * $x : $b->total_width();
	$self->{height}  = ($y != 1)? $b->text_height() * $y : $b->text_height();
	$self->{descent} = ($y != 1)? $b->descent() * $y : $b->descent();
	$self->{ascent}  = ($y != 1)? $b->ascent() * $y : $b->ascent();
	$self->{advanced_width} = ($x != 1)? $b->advance_width() * $x : $b->advance_width();
	# for blank space
	if($self->{text} eq ' '){
		$self->{ascent} = $self->{width};
		$self->{height} = $self->{width};
	}
	$self->{isUpdated} = 1;
	return 1;
}

sub getText {
	return shift->{text};
}
sub getFont {
	return shift->{font};
}
sub getScale {
	my $self = shift;
	return ($self->{xscale},$self->{yscale});
}
sub getWidth {
	my $self = shift;
	$self->_calcWidthHeight();
	return $self->{width};
}
sub getHeight {
	my $self = shift;
	$self->_calcWidthHeight();
	return $self->{height};
}
sub getAscent {
	my $self = shift;
	$self->_calcWidthHeight();
	return $self->{ascent};
}
sub getDescent {
	my $self = shift;
	$self->_calcWidthHeight();
	return $self->{descent};
}
sub getAdvancedWidth {
	my $self = shift;
	$self->_calcWidthHeight();
	return $self->{advanced_width};
}

1;
__END__

=pod

=head1 NAME

Imager::DTP::Letter - letter handling module for Imager::DTP package

=head1 SYNOPSIS

   use Imager::DTP::Letter;
   
   # first, define font & letter string
   my $font = Imager::Font->new(file=>'path/to/foo.ttf',type=>'ft2',
              size=>16);
   my $text = 'A';
   
   # create instance - basic way
   my $ltr = Imager::DTP::Letter->new();
   $ltr->setText(text=>$text);    # set text
   $ltr->setFont(font=>$font);    # set font
   $ltr->setScale(x=>1.2,y=>0.5); # set transform scale (optional)
   
   # create instance - or the shorcut way
   my $ltr = Imager::DTP::Letter->new(text=>$text,font=>$font,
             xscale=>1.2,yscale=>0.5);
   
   # and draw letter on target image
   my $target = Imager->new(xsize=>50,ysize=>50);
   $ltr->draw(target=>$target,x=>10,y=>10);

=head1 DESCRIPTION

Imager::DTP::Letter is a module intended for handling each letter/character in a whole text string (sentence or paragraph).  Each Imager::DTP::Letter instance will hold one letter/character internally, and it holds various information about the letter/character, most of it aquired from Imager::Font->bounding_box() method.  Thus, Imager::DTP::Letter is intended to act as a single letter with font information (such as ascent/descent) bundled together.  It is allowed to set more than one letter/character to a single Imager::DTP::Letter instance, but still, the whole Imager::DTP package will handle the instance as 'single letter'.

=head1 METHODS

=head2 BASIC METHODS

=head3 new

Can be called with or without options.

   use Imager::DTP::Letter;
   my $ltr = Imager::DTP::Letter->new();
   
   # or perform setText & setFont method at the same time
   my $font = Imager::Font->new(file=>'path/to/foo.ttf',type=>'ft2',
              size=>16);
   my $text = 'A';
   my $ltr  = Imager::DTP::Letter->new(text=>$text,font=>$font);
   
   # also, can setScale at the same time too.
   my $ltr  = Imager::DTP::Letter->new(text=>$text,font=>$font,
              xscale=>1.2,yscale=>0.5);

=head3 setText

Set letter/character to the instance.  You must supply some letter/character to text option (it must not be undef or '').  And for multi-byte letter/characters, text must be encoded to utf8, with it's internal utf8-flag ENABLED (This could be done by using utf8::decode() method).


   $ltr->setText(text=>'Z');
   
   # each time setText is called, previous text will be cleared.
   # like this, internal property will be 'X', not 'ZX'.
   $ltr->setText(text=>'X'); 

=head3 setFont

Must supply an Imager::Font object with freetype option (type=>'ft2').  Might work just fine with other font types like type=>'t1' and type=>'tt' too... it's just that I haven't tried yet :P

   my $font = Imager::Font->new(file=>'path/to/foo.ttf',type=>'ft2',
              size=>16);
   $ltr->setFont(font=>$font);

The following Imager::Font options are forced to these values internally.  Other options will work fine.

=over

=item * utf8 => 1

=item * vlayout => 0

=back

=head3 setScale

By setting x and y scaling to ratios other than 1.0 (default setting), you can make letters wider/narrower, or longer/shorter (width and height transformation).

   # make width of letter to 80%
   $ltr->setScale(x=>0.8);
   
   # make width 120% and height 60%
   $ltr->setScale(x=>1.2,y=>0.6);

Transformation is done by using L<Imager::Font>->transform() method, with the help of L<Imager::Matrix2d> module.

=head3 draw

Draw letter/character to the target image (Imager object).

   my $target = Imager->new(xsize=>50,ysize=>50);
   $ltr->draw(target=>$target,x=>10,y=>10);

Imager->String() method is called internally, so you can pass any extra Imager::String options to it by setting in 'others' option.

   # passing Imager::String options
   $ltr->draw(target=>$target,x=>10,y=>10,others=>{aa=>1});

But the following Imager::String options are forced to these values internally, meant for proper result.  Other options will work fine.

=over

=item * utf8 => 1

=item * vlayout => 0

=item * align => 0

=back

There is an extra debug option, which will draw a 'letter width x letter ascent' gray box around the letter. Handy for checking the letter's bounding size/position.

   # debug mode
   $ltr->draw(target=>$target,x=>10,y=>10,debug=>1);

=head2 GETTER METHODS

Calling these methods will return a property value corresponding to the method name.

=head3 getText

Returns the letter/character string.

=head3 getFont

Returns a reference (pointer) to the Imager::Font object.

=head3 getScale

Returns an array containing the current x/y scale setting.

   my($x,$y) = $self->getScale();

=head3 getWidth

Returns the width (in pixels) of the instance.

=head3 getHeight

Returns the height (in pixels) of the instance.

=head3 getAscent

Returns the ascent (in pixels) of the instance.

=head3 getDescent

Returns the descent (in pixels) of the instance.

=head3 getAdvancedWidth

Returns the advanced width (in pixels) of the instance.

=head1 TODO

=over

=item * change Carp-only error handling to something more elegant.

=back

=head1 AUTHOR

Toshimasa Ishibashi, C<< <iandeth99@ybb.ne.jp> >>

=head1 COPYRIGHT & LICENSE

Copyright 2005 Toshimasa Ishibashi, all rights reserved.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

L<Imager>, L<Imager::DTP>

=cut
