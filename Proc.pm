package OS2::Proc;

use strict;
use vars qw($VERSION @ISA @EXPORT %proc_type %thread_type %prio_type);

require Exporter;
require DynaLoader;
require AutoLoader;

@ISA = qw(Exporter AutoLoader DynaLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(
	     proc_info global_info mod_info );
$VERSION = '0.01';

%proc_type = qw(
		0 FullScreen
		1 RealMode
		2 VIO
		3 PM
		4 Detached
	       );

%thread_type = qw(
		1 Ready
		2 Blocked
		5 Running
	       );

%prio_type = qw(
		0 Idle-Time
		1 Regular
		2 Time-Critical
		3 Fixed-High
	       );

bootstrap OS2::Proc $VERSION;

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

OS2::Proc - Perl extension for blah blah blah

=head1 SYNOPSIS

  use OS2::Proc;
  blah blah blah

=head1 DESCRIPTION

Stub documentation for OS2::Proc was created by h2xs. It looks like the
author of the extension was negligent enough to leave the stub
unedited.

Blah blah blah.

=head1 AUTHOR

A. U. Thor, a.u.thor@a.galaxy.far.far.away

=head1 SEE ALSO

perl(1).

=cut

sub global_info {
  my %out;
  @out{qw(threads procs modules)} = @{ global_info_int() };
  \%out;
}

sub thread_from_intnl {
  my $thread = shift;
  return { threadid => shift @$thread,
	   slotid => shift @$thread,
	   sleepid => shift @$thread,
	   priority_class => $prio_type{($_->[0]>>8) - 1},
	   priority_level => $_->[0] & 0xFF,
	   priority => shift @$thread,
	   systime => shift @$thread,
	   usertime => shift @$thread,
	   thread_state => $thread_type{$_->[0]} || "unknown",
	   state => shift @$thread,
	 };
}

sub state_to_array {
  my ($state, @arr) = (shift);
  push @arr, 'ExitList' if $state & 0x01;
  push @arr, 'ExitingT1' if $state & 0x02;
  push @arr, 'Exiting' if $state & 0x04;
  push @arr, 'NeedsWait' if $state & 0x10;
  push @arr, 'Parent-Waiting' if $state & 0x20;
  push @arr, 'Dying' if $state & 0x40;
  push @arr, 'Embrionic' if $state & 0x80;
  \@arr;
}

sub proc_info {
  my $data = proc_info_int(shift);
  my %mods = %{ mod_info($data) };
  my @procs = map {
    my @threads = map {thread_from_intnl($_)} @{ shift @$_ };
    {
      threads => \@threads,
      pid => shift @$_,
      ppid => shift @$_,
      proc_type => $proc_type{$_->[0]},
      type => shift @$_,
      status_array => state_to_array($_->[0]),
      state => shift @$_,
      sessid => shift @$_,
      module_name => $mods{$_->[0]}->{name}, # module_handle
      module_handle => shift @$_,
      threadcnt => shift @$_,
      privsem32cnt => shift @$_,
      sem16cnt => shift @$_,
      dllcnt => shift @$_,
      shrmemcnt => shift @$_,
      fdscnt => shift @$_,
      dynamic_names => [map $mods{$_}->{name}, @{$_->[0]}],
      dynamic_array => shift @$_,
    }
  } @{$data->[0]};
  return (\@procs, \%mods);
}

sub mod_info {
  my $data = shift || proc_info_int($$, 2);
  my %mods;
  my $mod;
  foreach $mod (@{$data->[1]}) {
    my $handle = shift @$mod;
    $mods{$handle} = { type => shift @$mod,
		       cnt_static => shift @$mod,
		       segcnt => shift @$mod,
		       name => shift @$mod,
		       static_handles => [@$mod],
		     };
  }
  foreach $handle (keys %mods) {
    my @static_handles = @{$mods{$handle}{static_handles}};
    $mods{$handle}{static_names} = [map { $mods{$_}{name} } @static_handles];
  }
  \%mods;
}
