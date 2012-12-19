package Net::Gitlab;

# ABSTRACT: Put an abstract for Net::Gitlab here

use strict;
use warnings;
use namespace::autoclean;

use Carp;
use JSON;
use LWP::UserAgent;
use Params::Validate qw( validate_with validate_pos SCALAR HASHREF );
use Regexp::Common qw( Email::Address );

{  # Hide

  my @required_parms = qw( base_url email password );

  my @other_set_get  = qw(

    branch error hook_id issue_id key_id milestone_id project_id sha snippet_id private_token user_id

  );

  my %method = (

    login => {

      action   => 'POST',
      path     => 'session',
      required => qw( email password )

    },

    users => {

      action => 'GET',
      path   => 'users',

    },

    user => {

      action   => 'GET',
      path     => 'users/<user_id>',
      required => qw( user_id )

    },

    add_user => {

      action   => 'POST',
      path     => 'users',
      required => qw( email password username name ),
      optional => qw(  skype linkedin twitter projects_limit ),

    },

    self => {

      action => 'GET',
      path   => 'user',

    },

    self_issues => {

      action => 'GET',
      path   => 'issues',

    },

    self_keys => {

      action => 'GET',
      path   => 'user/keys',

    },

    self_key => {

      action   => 'GET',
      path     => 'user/keys/<key_id>',
      required => qw( user_id )

    },

    add_key => {

      action   => 'POST',
      path     => 'user/keys',
      required => qw( title key )

    },

    remove_key => {

      action   => 'DELETE',
      path     => 'user/keys/<key_id>',
      required => qw( key_id )

    },

    projects => {

      action => 'GET',
      path   => 'projects',

    },

    add_project => {

      action   => 'POST',
      path     => 'projects',
      required => qw( name ),
      optional => qw(  code path description default_branch issues_enabled wall_enabled merge_requests_enabled wiki_enabled ),

    },

    project => {

      action   => 'GET',
      path     => 'projects/<project_id>',
      required => qw( project_id )

    },

    branches => {

      action   => 'GET',
      path     => 'projects/<project_id>/repository/branches',
      required => qw( project_id )

    },

    branch => {

      action   => 'GET',
      path     => 'projects/<project_id>/repository/branches/<branch>',
      required => qw( project_id branch )

    },

    commits => {

      action   => 'GET',
      path     => 'projects/<project_id>/repository/commits',
      required => qw( project_id )

    },

    commit => {

      action   => 'GET',
      path     => 'projects/<project_id>/repository/commits/<sha>/blob',
      required => qw( project_id sha )

    },

    tags => {

      action   => 'GET',
      path     => 'projects/<project_id>/repository/tags',
      required => qw( project_id )

    },

    hooks => {

      action   => 'GET',
      path     => 'projects/<project_id>/hooks',
      required => qw( project_id )

    },

    hook => {

      action   => 'GET',
      path     => 'projects/<project_id>/hooks/<hook_id>',
      required => qw( project_id hook_id )

    },

    issues => {

      action   => 'GET',
      path     => 'projects/<project_id>/issues',
      required => qw( project_id )

    },

    issue => {

      action   => 'GET',
      path     => 'projects/<project_id>/issues/<issue_id>',
      required => qw( project_id issue_id )

    },

    members => {

      action   => 'GET',
      path     => 'projects/<project_id>/members',
      required => qw( project_id )

    },

    member => {

      action   => 'GET',
      path     => 'projects/<project_id>/members/<user_id>',
      required => qw( project_id user_id )

    },

    milestones => {

      action   => 'GET',
      path     => 'projects/<project_id>/milestones',
      required => qw( project_id )

    },

    milestone => {

      action   => 'GET',
      path     => 'projects/<project_id>/milestones/<milestone_id>',
      required => qw( project_id milestone_id )

    },

    snippets => {

      action   => 'GET',
      path     => 'projects/<project_id>/snippets',
      required => qw( project_id )

    },

    snippet => {

      action   => 'GET',
      path     => 'projects/<project_id>/snippets/<snippet_id>',
      required => qw( project_id snippet_id )

    },

    raw_snippet => {

      action   => 'GET',
      path     => 'projects/<project_id>/snippets/<snippet_id>/raw',
      required => qw( project_id snippet_id )

    },

    add_hook => {

      action   => 'POST',
      path     => 'projects/<project_id>/hooks',
      required => qw( project_id url )

    },

    add_issue => {

      action   => 'POST',
      path     => 'projects/<project_id>/issues',
      required => qw( project_id title ),
      optional => qw(  description assignee_id milestone_id labels ),

    },

    add_member => {

      action   => 'POST',
      path     => 'projects/<project_id>/members',
      required => qw( project_id user_id )

    },

    add_milestone => {

      action   => 'POST',
      path     => 'projects/<project_id>/milestones',
      required => qw( project_id title ),
      optional => qw(  description due_date ),

    },

    add_snippet => {

      action   => 'POST',
      path     => 'projects/<project_id>/snippets',
      required => qw( project_id title file_name code ),
      optional => qw(  lifetime ),

    },

    modify_hook => {

      action   => 'POST',
      path     => 'projects/<project_id>/hooks/<hook_id>',
      required => qw( project_id hook_id url )

    },

    modify_issue => {

      action   => 'PUT',
      path     => 'projects/<project_id>/issues/<issue_id>',
      required => qw( project_id issue_id ),
      optional => qw(  title description assignee_id milestone_id labels ),

    },

    modify_member => {

      action   => 'PUT',
      path     => 'projects/<project_id>/members/<user_id>',
      required => qw( project_id user_id access_level )

    },

    modify_milestone => {

      action   => 'PUT',
      path     => 'projects/<project_id>/milestones/<milestone_id>',
      required => qw( project_id milestone_id ),
      optional => qw(  title description due_date closed ),

    },

    modify_snippet => {

      action   => 'PUT',
      path     => 'projects/<project_id>/snippets/<snippet_id>',
      required => qw( project_id snippet_id ),
      optional => qw(  title file_name lifetime code ),

    },

    remove_hook => {

      action   => 'DELETE',
      path     => 'projects/<project_id>/hooks',
      required => qw( project_id )

    },

    remove_member => {

      action   => 'DELETE',
      path     => 'projects/<project_id>/members/<user_id>',
      required => qw( project_id user_id )

    },

    remove_snippet => {

      action   => 'DELETE',
      path     => 'projects/<project_id>/snippets/<snippet_id>',
      required => qw( project_id snipped_id )

    },

  );

  my ( %action, @methods );

  for my $method ( keys %method ) {

    push @methods, $method;
    $action{ $method{ $method }->{ action } }++;

  }

  my $valid_methods = join '|', sort @valid_methods;
  my $valid_actions = join '|', sort keys %action;

  sub _set_get {

    my $self = shift;

    my ( $key, $value ) = validate_pos(
      @_,

      { type => SCALAR },
      { type => SCALAR, optional => 1 },

    );

    if ( defined $value ) {

      $self->{ $key } = $value;
      return 1;

    } else {

      croak "$key does not exist"
        unless exists $self->{ $key };

      return $self->{ $key };

    }
  } ## end sub _set_get

#########################################
  my ( $new_spec, $session_spec );

  for my $parm ( @required_parms, @other_set_get ) {

    eval "sub $parm { shift->_set_get( '$parm', \@_ ) }";
    croak $@ if $@;

    next if grep { /$parm/ } @other_set_get;

    $new_spec->{ $parm } = $session_spec->{ $parm } = { type => SCALAR };
    $new_spec->{ $parm }{ optional } = 1;

  }

  $new_spec->{ base_url }{ regex } = qr/$RE{URI}{HTTP}{-scheme => 'https?'}/;
  $new_spec->{ email }{ regex }    = qr/$RE{Email}{Address}/;
#########################################

  sub new {

    my $class = shift;
    my $self = bless {}, ref $class || $class;

    my %arg = validate_with( params => \@_, spec => $new_spec );

    $self->$_( $arg{ $_ } ) for keys %arg;

    return $self;

  }

  sub _ua { shift->{ ua } ||= LWP::UserAgent->new }

  sub call_api {

    my $self = shift;

    my ( $action, $method, $data ) = validate_pos(
      @_,

      { type => SCALAR,  regex    => qr/^($valid_actions)$/i },
      { type => SCALAR,  regex    => qr/^($valid_methods)$/ },
      { type => HASHREF },

    );

    $action = uc $action;
    my $url = sprintf "%s/%s", $self->base_url, $method{ $method }->{ path };

    $url =~ s/<$_>/delete $data{ $_ }/ge;
      for $url =~ /<([^>]*)>/g;

    my $req = HTTP::Request->new( $action => $url );

    $req->header( $field => $self->private_token );
      unless $method eq '/session';

    $req->content_type( 'application/json' );
    $req->content( encode_json $data );

    my $res = $self->_ua->request( $req );

    if ( $res->is_success ) {

      return decode_json $res->content;

    } else {

      $error = $res->status_line;
      return undef;

    }
  } ## end sub call_api

###############################################################################################

  #sub session {
  #
  #  my ( $email, $password ) = @_;
  #
  #  croak "email required" unless $email ne '';
  #  croak "password required" unless $password ne '';
  #
  #  my $data    = { 'email' => $email, 'password' => $password };
  #  my $url     = "${base_url}/session";
  #  my $session = post( $url, $data ) or croak "Problem: $error";
  #
  #  return $session;
  #
  #}
  #
  #sub user_add {
  #
  #  my $arg = shift;
  #
  #  croak "expecting hashref" unless ref $arg eq 'HASH';
  #
  #  my @fields = qw( email password username name );
  #
  #  my @missing = grep { exists $arg->{ $_ } } @fields;
  #
  #  if ( @missing ) {
  #
  #    my $missing = join ', ' @missing;
  #    croak "$missing required";
  #
  #  }
  #
  #  # these are optional
  #  push @fields, qw( skype linkedin twitter projects_limit );
  #
  #  my $data;
  #
  #  for my $field ( @fields ) {
  #
  #    $data->{ $field } = $arg->{ $field }
  #      if exists $arg->{ $field };
  #
  #  }
  #
  #  my $json = encode_json $data;
  #  my $url  = "${base_url}/users";
  #
  #}
  #
  #my $session = session( $email, $password );
  #my $token = $session->{ private_token };
  #
  # [ email password username name ]
  #my @users = (
  #
  #  [
  #);

};  # No more hiding

1;
