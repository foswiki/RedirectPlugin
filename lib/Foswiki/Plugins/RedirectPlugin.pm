# Foswiki RedirectPlugin
#
# Copyright (C) 2009 - 2025 Foswiki Contributors
# Copyright (C) 2008 - 2009 Andrew Jones, andrewjones86@gmail.com
# Copyright (C) 2006 Motorola, thomas.weigert@motorola.com
# Copyright (C) 2006 Meredith Lesly, msnomer@spamcop.net
# Copyright (C) 2003 Steve Mokris, smokris@softpixel.com
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details, published at
# http://www.gnu.org/copyleft/gpl.html

package Foswiki::Plugins::RedirectPlugin;

use warnings;
use strict;

use Foswiki::Func ();

our $VERSION = '2.00';
our $RELEASE = '%$RELEASE%';
our $SHORTDESCRIPTION = 'Create a redirect to another topic or website.';
our $NO_PREFS_IN_TOPIC = 1;
our $core;

sub initPlugin {

  Foswiki::Func::registerTagHandler(
    'REDIRECT',
    sub {
      return getCore(shift)->REDIRECT(@_);
    }
  );

  return 1;
}

sub finishPlugin {
  undef $core;
}

sub getCore {
  unless ($core) {
    require Foswiki::Plugins::RedirectPlugin::Core;
    $core = new Foswiki::Plugins::RedirectPlugin::Core();
  }

  return $core;
}

1;
