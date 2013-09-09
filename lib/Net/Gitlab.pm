package Net::Gitlab;

## no critic( ValuesAndExpressions::ProhibitAccessOfPrivateData )

# ABSTRACT: Talk to a Gitlab installation via its API.

=head1 METHODS

=head2 new

Create a new instance of a Gitlab object.

=cut

use strict;
use warnings;
use namespace::autoclean;

use Carp;
use JSON;
use LWP::UserAgent;

use Params::Validate::Checks ':all';
use Regexp::Common 'Email::Address';

# VERSION

{  # Hide

  Params::Validate::Checks::register
    email          => qr/$RE{Email}{Address}/,
    uri            => qr/$RE{URI}{HTTP}{-scheme => 'https?'}/,
    short_password => sub { length $_[0] > 6 };

  my %validate = (

    assignee_id  => { as 'pos_int' },
    hook_id      => { as 'pos_int' },
    issue_id     => { as 'pos_int' },
    key_id       => { as 'pos_int' },
    milestone_id => { as 'pos_int' },
    project_id   => { as 'pos_int' },
    snippet_id   => { as 'pos_int' },
    user_id      => { as 'pos_int' },

    issues_enabled         => { type => BOOLEAN },
    merge_requests_enabled => { type => BOOLEAN },
    wall_enabled           => { type => BOOLEAN },
    wiki_enabled           => { type => BOOLEAN },

    access_level   => { as 'string' },  # Are these hard coded into gitlab? if so, we can further restrict this
    branch         => { as 'string' },
    closed         => { as 'string' },
    code           => { as 'string' },
    default_branch => { as 'string' },
    description    => { as 'string' },
    due_date       => { as 'string' },
    email          => { as 'email' },
    file_name      => { as 'string' },
    key            => { as 'string' },
    labels         => { as 'string' },
    lifetime       => { as 'string' },
    linkedin       => { as 'string' },
    name           => { as 'string' },
    password       => { as 'string', as 'short_password' },
    path           => { as 'string' },
    private_token  => { as 'string' },
    projects_limit => { as 'pos_int' },
    sha            => { as 'string' },
    skype          => { as 'string' },
    title          => { as 'string' },
    twitter        => { as 'string' },
    url            => { as 'uri' },
    username       => { as 'string' },

    base_url => { as 'uri' },
    error    => { as 'string' },

  ); ## end %validate

  my %method = (

    login => {

      action   => 'POST',
      path     => 'session',
      required => [qw( email password )],

    },

    users => {

      action => 'GET',
      path   => 'users',

    },

    user => {

      action   => 'GET',
      path     => 'users/<user_id>',
      required => [qw( user_id )],

    },

    add_user => {

      action   => 'POST',
      path     => 'users',
      required => [qw( email password username name )],
      optional => [qw( skype linkedin twitter projects_limit extern_uid provider bio )],

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
      required => [qw( user_id )],

    },

    add_key => {

      action   => 'POST',
      path     => 'user/keys',
      required => [qw( title key )],

    },

    remove_key => {

      action   => 'DELETE',
      path     => 'user/keys/<key_id>',
      required => [qw( key_id )],

    },

    projects => {

      action => 'GET',
      path   => 'projects',

    },

    add_project => {

      action   => 'POST',
      path     => 'projects',
      required => [qw( name )],
      optional => [qw( code path description default_branch issues_enabled wall_enabled merge_requests_enabled wiki_enabled )],

    },

    project => {

      action   => 'GET',
      path     => 'projects/<project_id>',
      required => [qw( project_id )],

    },

    branches => {

      action   => 'GET',
      path     => 'projects/<project_id>/repository/branches',
      required => [qw( project_id )],

    },

    branch => {

      action   => 'GET',
      path     => 'projects/<project_id>/repository/branches/<branch>',
      required => [qw( project_id branch )],

    },

    commits => {

      action   => 'GET',
      path     => 'projects/<project_id>/repository/commits',
      required => [qw( project_id )],

    },

    commit => {

      action   => 'GET',
      path     => 'projects/<project_id>/repository/commits/<sha>/blob',
      required => [qw( project_id sha )],

    },

    tags => {

      action   => 'GET',
      path     => 'projects/<project_id>/repository/tags',
      required => [qw( project_id )],

    },

    hooks => {

      action   => 'GET',
      path     => 'projects/<project_id>/hooks',
      required => [qw( project_id )],

    },

    hook => {

      action   => 'GET',
      path     => 'projects/<project_id>/hooks/<hook_id>',
      required => [qw( project_id hook_id )],

    },

    issues => {

      action   => 'GET',
      path     => 'projects/<project_id>/issues',
      required => [qw( project_id )],

    },

    issue => {

      action   => 'GET',
      path     => 'projects/<project_id>/issues/<issue_id>',
      required => [qw( project_id issue_id )],

    },

    members => {

      action   => 'GET',
      path     => 'projects/<project_id>/members',
      required => [qw( project_id )],

    },

    member => {

      action   => 'GET',
      path     => 'projects/<project_id>/members/<user_id>',
      required => [qw( project_id user_id )],

    },

    milestones => {

      action   => 'GET',
      path     => 'projects/<project_id>/milestones',
      required => [qw( project_id )],

    },

    milestone => {

      action   => 'GET',
      path     => 'projects/<project_id>/milestones/<milestone_id>',
      required => [qw( project_id milestone_id )],

    },

    snippets => {

      action   => 'GET',
      path     => 'projects/<project_id>/snippets',
      required => [qw( project_id )],

    },

    snippet => {

      action   => 'GET',
      path     => 'projects/<project_id>/snippets/<snippet_id>',
      required => [qw( project_id snippet_id )],

    },

    raw_snippet => {

      action   => 'GET',
      path     => 'projects/<project_id>/snippets/<snippet_id>/raw',
      required => [qw( project_id snippet_id )],

    },

    add_hook => {

      action   => 'POST',
      path     => 'projects/<project_id>/hooks',
      required => [qw( project_id url )],

    },

    add_issue => {

      action   => 'POST',
      path     => 'projects/<project_id>/issues',
      required => [qw( project_id title )],
      optional => [qw( description assignee_id milestone_id labels )],

    },

    add_member => {

      action   => 'POST',
      path     => 'projects/<project_id>/members',
      required => [qw( project_id user_id )],

    },

    add_milestone => {

      action   => 'POST',
      path     => 'projects/<project_id>/milestones',
      required => [qw( project_id title )],
      optional => [qw( description due_date )],

    },

    add_snippet => {

      action   => 'POST',
      path     => 'projects/<project_id>/snippets',
      required => [qw( project_id title file_name code )],
      optional => [qw( lifetime )],

    },

    modify_hook => {

      action   => 'POST',
      path     => 'projects/<project_id>/hooks/<hook_id>',
      required => [qw( project_id hook_id url )],

    },

    modify_issue => {

      action   => 'PUT',
      path     => 'projects/<project_id>/issues/<issue_id>',
      required => [qw( project_id issue_id )],
      optional => [qw( title description assignee_id milestone_id labels )],

    },

    modify_member => {

      action   => 'PUT',
      path     => 'projects/<project_id>/members/<user_id>',
      required => [qw( project_id user_id access_level )],

    },

    modify_milestone => {

      action   => 'PUT',
      path     => 'projects/<project_id>/milestones/<milestone_id>',
      required => [qw( project_id milestone_id )],
      optional => [qw( title description due_date closed )],

    },

    modify_snippet => {

      action   => 'PUT',
      path     => 'projects/<project_id>/snippets/<snippet_id>',
      required => [qw( project_id snippet_id )],
      optional => [qw( title file_name lifetime code )],

    },

    remove_hook => {

      action   => 'DELETE',
      path     => 'projects/<project_id>/hooks',
      required => [qw( project_id )],

    },

    remove_member => {

      action   => 'DELETE',
      path     => 'projects/<project_id>/members/<user_id>',
      required => [qw( project_id user_id )],

    },

    remove_snippet => {

      action   => 'DELETE',
      path     => 'projects/<project_id>/snippets/<snippet_id>',
      required => [qw( project_id snippet_id )],

    },

  ); ## end %method

  my $valid_methods = join '|', sort keys %method;

  ###############################################################################

  sub _set_get {

    my $self = shift;
    my $key  = shift;

    croak "unknown attribute ($key)"
      unless exists $validate{ $key };

    my $validate = $validate{ $key };
    $validate->{ optional } = 1;

    my ( $value ) = validate_pos( @_, $validate );

    if ( defined $value ) {

      $self->{ $key } = $value;
      return 1;

    } else {

      croak "$key has not been set"
        unless exists $self->{ $key };

      return $self->{ $key };

    }
  } ## end sub _set_get

  sub _method {

    my $self = shift;
    my $m    = shift;

    croak "unkown method ($m)"
      unless exists $method{ $m };

    my $method = $method{ $m };

    my $spec;

    if ( exists $method->{ required } ) {

      croak "required needs to be an arrayref"
        unless ref $method->{ required } eq 'ARRAY';

      $spec->{ $_ } = $validate{ $_ } for @{ $method->{ required } };

    }

    if ( exists $method->{ optional } ) {

      croak "optional needs to be an arrayref"
        unless ref $method->{ optional } eq 'ARRAY';

      for my $parm ( @{ $method->{ optional } } ) {

        croak "oops ... duplicate key ($parm) in optional and required arrays for method $m"
          if exists $spec->{ $parm };

        $spec->{ $parm } = $validate{ $parm };
        $spec->{ $parm }{ optional } = 1;

      }
    }

    my %data;
    %data = validate_with( params => \@_, spec => $spec )
      if keys %$spec;

    if ( keys %data ) {

      return $self->_call_api( $m, \%data );

    } else {

      return $self->_call_api( $m );

    }
  } ## end sub _method

  our $AUTOLOAD;

  sub AUTOLOAD {

    my $self = shift;

    ( my $call = $AUTOLOAD ) =~ s/^.*:://;

    my $sub;

    if ( exists $validate{ $call } ) {

      $sub = sub { shift->_set_get( $call, @_ ) };

    } elsif ( exists $method{ $call } ) {

      $sub = sub { shift->_method( $call, @_ ) };

    } else {

      croak "Don't know  how to handle $call";

    }

    no strict 'refs'; ## no critic( TestingAndDebugging::ProhibitNoStrict )
    *$AUTOLOAD = $sub;

    unshift @_, $self;

    goto &$AUTOLOAD;

  } ## end sub AUTOLOAD

  DESTROY { }

  sub new {

    my $class = shift;
    my $self = bless {}, ref $class || $class;

    my $validate;

    for my $k ( keys %validate ) {

      $validate->{ $k } = $validate{ $k };
      $validate->{ $k }{ optional } = 1;

    }

    my %arg = validate_with( params => \@_, spec => $validate );

    $self->$_( $arg{ $_ } ) for keys %arg;

    return $self;

  } ## end sub new

  sub _ua { shift->{ ua } ||= LWP::UserAgent->new }

  sub _call_api {

    my $self = shift;

    my @specs = { type => SCALAR, regex => qr/^($valid_methods)$/ };

    push @specs, { type => HASHREF }
      if @_ > 1;

    my ( $m, $data ) = validate_pos( @_, @specs );

    croak "no action specified for $m"
      unless exists $method{ $m }->{ action };

    my $method = $method{ $m };

    my $action = $method->{ action };
    my $url = sprintf "%s/%s", $self->base_url, $method->{ path };

    $url =~ s/<$_>/delete $data->{ $_ }/ge for $url =~ /<([^>]*)>/g;

#    $url .= sprintf '?private_token=%s', $self->private_token
#       unless $method->{ path } eq '/session';

    my $req = HTTP::Request->new( $action => $url );

    $req->content_type( 'application/json' );

    $req->header( 'private_token' => $self->private_token )
      unless $method->{ path } eq '/session';

    $req->content( encode_json $data )
      if keys %$data;

    my $res = $self->_ua->request( $req );

    if ( $res->is_success ) {

      return decode_json $res->content;

    } else {

      $self->error( $res->status_line );
      return;

    }
  } ## end sub _call_api

};  # No more hiding

1;
