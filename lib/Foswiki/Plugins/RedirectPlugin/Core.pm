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

package Foswiki::Plugins::RedirectPlugin::Core;

use warnings;
use strict;

use Foswiki::Func ();
use Foswiki::Plugins ();

sub new {
  my $class = shift;
  my $session = shift || $Foswiki::Plugins::SESSION;

  my $this = bless({
    session => $session,
    @_
  }, $class);

  $this->{anchorRegex} = Foswiki::Func::getRegularExpression('anchorRegex');

  return $this;
}

sub REDIRECT {
  my ($this, $params, $topic, $web) = @_;

  my $context = Foswiki::Func::getContext();
  my $newWeb = $web;
  my $newTopic = '';
  my $anchor = '';
  my $queryString = '';
  my $dest = $params->{'newtopic'} || $params->{_DEFAULT};
  my $dontCheckDestinationExists = Foswiki::Func::isTrue($params->{'dontcheck'}, 0);


  # Redirect only on view
  # Support Codev.ShorterURLs: do not redirect on edit
  if ( $dest
    && !$context->{'edit'}
    && !$context->{'save'}
    && !$context->{'preview'})
  {

    my $request = Foswiki::Func::getRequestObject();

    my $queryString = "";
    my $param;
    foreach my $param ($request->param) {
      #SMELL This will drop multiple-instance parameters
      foreach my $value (scalar $request->param("$param")) {
        $queryString .= "&" if $queryString;
        $queryString .= "$param=" . $value;
      }
    }

    # do not redirect when param "redirect=no" is passed
    my $noredirect = $request->param(-name => 'noredirect') || '';
    return '' if $noredirect eq 'on';

    # do not redirect when we come from an edit
    return '' if defined($ENV{HTTP_REFERER}) && $ENV{HTTP_REFERER} =~ /\bedit\b/;

    $dest = Foswiki::Func::expandCommonVariables($dest, $topic, $web) if $dest =~ /%/; # SMELL: not required

    # redirect to URL
    if ($dest =~ m/^http/) {

      return _inlineError("Cannot redirect to current topic") if $dest eq Foswiki::Func::getViewUrl($web, $topic);
      Foswiki::Func::redirectCgiQuery($request, $dest);
      return '';
    }

    # else: "topic" or "web.topic" notation
    # get the components and check if the topic exists
    my $topicLocation = "";
    if ($dest =~ /^(?:(.+)\.)?(.*?)(\#.*|\?.*)?$/) {
      $newWeb = $1 || $web || '';
      $newTopic = $2 || '';

      # ignore anchor and params here
      $topicLocation = "$newWeb.$newTopic";
    }

    return _inlineError("Cannot redirect to current topic") if $topicLocation eq "$web.$topic";
    return _inlineError("Cannot redirect to an already visited topic") if $queryString =~ /redirectedfrom=$topicLocation/;

    unless ($dontCheckDestinationExists) {
      return _inlineError("Could not redirect to topic (the topic does not seem to exist")
        unless Foswiki::Func::topicExists(undef, $topicLocation);
    }

    if ($dest =~ /($this->{anchorRegex})/) {
      $anchor = $1;
    }

    if ($dest =~ /\?(.*)/) {
      #override url params
      $queryString = $1;
    }

    # AndrewJones: allow us to use %<nop>URLPARAM{redirectfrom}%
    # in destination topic to display Wikipedia like "Redirected
    # from ..." text
    my $q = "?redirectedfrom=$web.$topic";
    $q .= "&" . $queryString if $queryString;

    # topic exists
    Foswiki::Func::redirectCgiQuery($request, Foswiki::Func::getViewUrl($newWeb, $newTopic) . $q . $anchor);
  }

  return '';
}

sub _inlineError {
  return "<span class='foswikiAlert'>ERROR: ".$_[0]."</span>";
}

1;
