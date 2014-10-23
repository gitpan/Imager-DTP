package Imager::DTP::Line::Horizontal;
use base Imager::DTP::Line;
use strict;

our $VERSION = '0.01';

sub draw {
	my $self = shift;
	my %o = @_;
	my $y = ($o{y})? $o{y} : 0;
	my $x = ($o{x})? $o{x} : 0;
	# re-calculate bounding box
	$self->_calcWidthHeight();
	my $l = ($o{leading})? $o{leading} : $self->getAscent();
	# draw box - debug
	if($o{debug}){
		$o{target}->box(filled=>1,color=>'#EFEFEF',xmin=>$x,ymin=>$y,
		                xmax=>$x+$self->getWidth()-1,ymax=>$y+$l-1);
	}
	foreach my $ltr (@{$self->getLetters()}){
		my $nowy = $y + $l - $ltr->getAscent();
		my $nowx = $x + sprintf("%.0f",($ltr->getAdvancedWidth() - $ltr->getWidth()) /2);
		$ltr->draw(target=>$o{target},x=>$nowx,y=>$nowy,debug=>$o{debug},
		           others=>$o{others}) or die $ltr->errstr;
		$x += $ltr->getAdvancedWidth() + $self->getWspace();
	}
	return 1;
}

sub _calcWidthHeight {
	my $self = shift;
	return undef if($self->{isUpdated});
	return undef if(@{$self->getLetters()} == 0);
	my %o = @_;
	my ($w,$h,$a,$d) = qw(0 0 0 0);
	my $wspace = $self->getWspace();
	foreach my $ltr (@{$self->getLetters()}){
		$ltr->_calcWidthHeight();
		$w += $ltr->getAdvancedWidth() + $wspace;
		$a  = ($ltr->getAscent() > $a)? $ltr->getAscent() : $a;
		# remember, descent is a negative integer
		$d  = ($ltr->getDescent() < $d)? $ltr->getDescent() : $d;
	}
	$w -= $wspace; # don't need the last wspace
	$self->{height}  = $a+(-$d);
	$self->{width}   = $w;
	$self->{ascent}  = $a;
	$self->{descent} = $d;
	$self->{isUpdated} = 1;
	return 1;
}

sub _setText_parse {
	my $self = shift;
	my %o = @_;
	my @text = split(//,$o{text});
	foreach my $t (@text){
		my $ltr = Imager::DTP::Letter->new(text=>$t,font=>$o{font});
		push(@{$self->{letters}},$ltr);
	}
	return 1;
}

1;
__END__

=pod

=head1 NAME

Imager::DTP::Line::Horizontal - extended class of Imager::DTP::Line.

=head1 SYNOPSIS

See L<Imager::DTP::Line> for synopsis and description.

=head1 AUTHOR

Toshimasa Ishibashi <iandeth99@ybb.ne.jp>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Imager>, L<Imager::DTP>

=cut
