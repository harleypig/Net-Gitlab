package Net::Gitlab;

## efm skip lint

# ABSTRACT: Talk to a Gitlab installation via its API.

=head1 METHODS

=head2 new

Create a new instance of a Gitlab object.

=cut

use utf8;
use strict;
use warnings;
use namespace::autoclean;

use Carp;
use HTTP::Request ();
use JSON;
use LWP::UserAgent ();
use Params::Validate::Checks ':all';
use Regexp::Common 'Email::Address';

## no critic ( ValuesAndExpressions::ProhibitMagicNumbers )
my $PASSWD_LENGTH = 6;
## use critic ( ValuesAndExpressions::ProhibitMagicNumbers )

# VERSION

{  # Hide

  Params::Validate::Checks::register
    email          => qr/$RE{Email}{Address}/,
    uri            => qr/$RE{URI}{HTTP}{-scheme => 'https?'}/,
    short_password => sub { length $_[0] > $PASSWD_LENGTH };

  my %validate = (

    access_level           => { as 'string' },
    admin                  => { type => BOOLEAN },
    assignee_id            => { as 'pos_int' },
    base_url               => { as 'uri' },
    bio                    => { type => SCALAR },
    branch                 => { as 'string' },
    can_create_group       => { type => BOOLEAN },
    closed                 => { as 'string' },
    code                   => { as 'string' },
    default_branch         => { as 'string' },
    description            => { type => SCALAR },
    due_date               => { as 'string' },
    email                  => { as 'email' },
    error                  => { as 'string' },
    extern_uid             => { as 'string' },
    file_name              => { as 'string' },
    hook_id                => { as 'pos_int' },
    issue_id               => { as 'pos_int' },
    issues_enabled         => { type => BOOLEAN },
    key                    => { as 'string' },
    key_id                 => { as 'pos_int' },
    labels                 => { as 'string' },
    lifetime               => { as 'string' },
    linkedin               => { as 'string' },
    login                  => { as 'string' },
    merge_requests_enabled => { type => BOOLEAN },
    milestone_id           => { as 'pos_int' },
    name                   => { as 'string' },
    password               => { as 'string', as 'short_password' },
    path                   => { as 'string' },
    private_token          => { as 'string' },
    project_id             => { as 'pos_int' },
    projects_limit         => { as 'pos_int' },
    provider               => { as 'string' },
    sha                    => { as 'string' },
    skype                  => { as 'string' },
    snippet_id             => { as 'pos_int' },
    status_code            => { as 'pos_int' },
    title                  => { as 'string' },
    twitter                => { as 'string' },
    url                    => { as 'uri' },
    user_id                => { as 'pos_int' },
    username               => { as 'string' },
    wall_enabled           => { type => BOOLEAN },
    website_url            => { as 'uri' },
    wiki_enabled           => { type => BOOLEAN },

  ); ## end %validate

  my %method = (

    ## no critic qw( Tics::ProhibitLongLines )

    login => {

      action   => 'POST',
      path     => 'session',
      required => [qw( login|email password )],

    },

    #######################################################
    ## USERS

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
      optional => [ qw(

          skype linkedin twitter website_url projects_limit extern_uid provider
          bio admin can_create_group

          ),
      ],

    },

    modify_user => {

      action   => 'PUT',
      path     => 'users/<user_id>',
      optional => [ qw(

          email password username name skype linkedin twitter website_url
          projects_limit extern_uid provider bio admin can_create_group

          ),
      ],
    },

    delete_user => {

      action => 'DELETE',
      path   => 'users/<user_id>',

    },

    self => {

      action => 'GET',
      path   => 'user',

    },

    self_keys => {

      action => 'GET',
      path   => 'user/keys',

    },

    self_issues => {

      action => 'GET',
      path   => 'issues',

    },

    self_key => {

      action   => 'GET',
      path     => 'user/keys/<key_id>',
      required => [qw( user_id )],

    },

    user_keys => {

      action => 'GET',
      path   => 'user/<user_id>',

    },

    get_key => {

      action => 'GET',
      path   => 'user/keys/<key_id>',

    },

    add_key => {

      action   => 'POST',
      path     => 'user/keys',
      required => [qw( title key )],

    },

    add_user_key => {

      action   => 'POST',
      path     => 'users/<user_id>/keys',
      required => [qw( user_id title key )],

    },

    remove_key => {

      action   => 'DELETE',
      path     => 'user/keys/<key_id>',
      required => [qw( key_id )],

    },

    remove_user_key => {

      action => 'DELETE',
      path   => 'users/<user_id>/keys/<key_id>',

    },

    #######################################################
    ## Projects

    projects => {

      action => 'GET',
      path   => 'projects',

    },

    projects_owned => {

      action => 'GET',
      path   => 'projects/owned',

    },

    all_projects => {

      action => 'GET',
      path   => 'projects/all',

    },

    project => {

      action   => 'GET',
      path     => 'projects/<project_id>',
      required => [qw( project_id )],

    },

    project_events => {

      action   => 'GET',
      path     => 'projects/<project_id>/events',
      required => [qw( project_id )],

    },

    add_project => {

      action   => 'POST',
      path     => 'projects',
      required => [qw( name )],
      optional => [ qw(

          description import_url issues_enabled merge_requests_enabled
          namespace_id public snippets_enabled visibility_level wiki_enabled

          ),
      ],

    },

    add_user_project => {

      action   => 'POST',
      path     => 'projects/user/<user_id>',
      required => [qw( user_id name )],
      optional => [ qw(

          default_branch description issues_enabled merge_requests_enabled
          public visibility_level

          ),
      ],
    },

    delete_project => {

      action   => 'DELETE',
      path     => 'projects/<project_id>',
      required => [qw( project_id )],

    },

    #######################################################
    ## Team Members

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

    add_member => {

      action   => 'POST',
      path     => 'projects/<id>/members',
      required => [qw( project_id user_id access_level)],

    },

    modify_member => {

      action   => 'PUT',
      path     => 'projects/<project_id>/members/<user_id>',
      required => [qw( project_id user_id access_level )],

    },

    remove_member => {

      action   => 'DELETE',
      path     => 'projects/<project_id>/members/<user_id>',
      required => [qw( project_id user_id )],

    },

    #######################################################
    ## Hooks

    project_hooks => {

      action   => 'GET',
      path     => 'projects/<project_id>/hooks',
      required => [qw( project_id )],

    },

    project_hook => {

      action   => 'GET',
      path     => 'projects/<project_id>/hooks/<hook_id>',
      required => [qw( project_id hook_id )],

    },

    add_project_hook => {

      action   => 'POST',
      path     => 'projects/<project_id>/hooks',
      required => [qw( project_id url )],
      optional => [qw( push_events issues_events merge_requests_events )],

    },

    modify_project_hook => {

      action   => 'PUT',
      path     => 'projects/<project_id>/hooks/<hook_id>',
      required => [qw( project_id hook_id url )],
      optional => [qw( push_events issues_events merge_requests_events )],

    },

    remove_project_hook => {

      action   => 'DELETE',
      path     => 'projects/<project_id>/hooks/<hook_id>',
      required => [qw( project_id hook_id )],

    },

    #######################################################
    ## Branches

    branches => {

      action   => 'GET',
      path     => 'projects/<project_id>/repository/branches',
      required => [qw( project_id )],

    },

    branch => {

      action   => 'GET',
      path     => 'projects/<project_id>/repository/branches/<branch_name>',
      required => [qw( project_id branch_name )],

    },

    protect_branch => {

      action   => 'PUT',
      path     => 'projects/<project_id>/repository/branches/<branch_name>/protect',
      required => [qw( project_id branch_name )],

    },

    unprotect_branch => {

      action   => 'PUT',
      path     => 'projects/<project_id>/repository/branches/<branch_name>/unprotect',
      required => [qw( project_id branch_name )],

    },

    create_branch => {

      action   => 'POST',
      path     => 'projects/<project_id>/repository/branches',
      required => [qw( project_id branch_name ref )],

    },

    delete_branch => {

      action   => 'DELETE',
      path     => 'projects/<project_id>/repository/branches/<branch_name>',
      required => [qw( project_id branch_name )],

    },

    #######################################################
    ## Forks

    create_fork => {

      action   => 'POST',
      path     => 'projects/<project_id>/fork/<forked_project_id>',
      required => [qw( project_id forked_project_id )],

    },

    delete_fork => {

      action => 'DELETE',
      path   => 'projects/<project_id>/fork',

    },

    #######################################################
    ## Labels

    labels => {

      action   => 'GET',
      path     => 'projects/<project_id>/labels',
      required => [qw( project_id )],
    },

    #######################################################
    ## Snippets

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

    add_snippet => {

      action   => 'POST',
      path     => 'projects/<project_id>/snippets',
      required => [qw( project_id title file_name code )],

    },

    modify_snippet => {

      action   => 'PUT',
      path     => 'projects/<project_id>/snippets/<snippet_id>',
      required => [qw( project_id snippet_id )],
      optional => [qw( title file_name code )],

    },

    remove_snippet => {

      action   => 'DELETE',
      path     => 'projects/<project_id>/snippets/<snippet_id>',
      required => [qw( project_id snippet_id )],

    },

    raw_snippet => {

      action   => 'GET',
      path     => 'projects/<project_id>/snippets/<snippet_id>/raw',
      required => [qw( project_id snippet_id )],

    },

    #######################################################
    ## Repositories

    tags => {

      action   => 'GET',
      path     => 'projects/<project_id>/repository/tags',
      required => [qw( project_id )],

    },

    add_tag => {

      action   => 'POST',
      path     => 'projects/<project_id>/repository/tags',
      required => [qw( project_id tag_name ref )],

    },

    tree => {

      action   => 'GET',
      path     => 'projects/<project_id>/repository/tree',
      required => [qw( project_id )],
      optional => [qw( path ref_name )],

    },

    blob => {

      action   => 'GET',
      path     => 'projects/<project_id>/repository/blobs/<sha>',
      required => [qw( project_id sha filepath )],

    },

    raw_blob => {

      action   => 'GET',
      path     => 'projects/<project_id>/repository/raw_blobs/<sha>',
      required => [qw( project_id sha )],

    },

    archive => {

      action   => 'GET',
      path     => 'projects/<project_id>/repository/archive',
      required => [qw( project_id )],
      optional => [qw( sha )],

    },

    compare => {

      action   => 'GET',
      path     => 'projects/<project_id>/repository/compare',
      required => [qw( project_id from to )],

    },

    contributors => {

      action   => 'GET',
      path     => 'projects/<project_id>/repository/contributors',
      required => [qw( project_id )],

    },

    #######################################################
    ## Repository Files

    file => {

      action   => 'GET',
      patch    => 'projects/<project_id>/repository/files',
      required => [qw( file_path ref )],

    },

    create_file => {

      action   => 'POST',
      path     => 'projects/<project_id>/repository/files',
      required => [qw( file_path branch_name content commit_message )],
      optional => [qw( encoding )],

    },

    modify_file => {

      action   => 'PUT',
      path     => 'projects/<project_id>/repository/files',
      required => [qw( file_path branch_name content commit_message )],
      optional => [qw( encoding )],

    },

    delete_file => {

      action   => 'DELETE',
      path     => 'projects/<project_id>/repository/files',
      required => [qw( file_path branch_name commit_message )],

    },

    #######################################################
    ## Commits

    commits => {

      action   => 'GET',
      path     => 'projects/<project_id>/repository/commits',
      required => [qw( project_id )],
      optional => [qw( ref_name )],

    },

    commit => {

      action   => 'GET',
      path     => 'projects/<project_id>/repository/commits/<sha>',
      required => [qw( project_id sha )],

    },

    diff => {

      action   => 'GET',
      path     => 'projects/<project_id>/repository/commits/<sha>/diff',
      required => [qw( project_id sha )],

    },

    #######################################################
    ## Merge Requests

    merge_requests => {

      action   => 'GET',
      path     => 'projects/<project_id>/merge_requests',
      required => [qw( project_id )],
      optional => [qw( state )],

    },

    merge_request => {

      action   => 'GET',
      path     => 'projects/<project_id>/merge_request/<merge_request_id>',
      required => [qw( project_id merge_request_id )],

    },

    create_merge_request => {

      action   => 'POST',
      path     => 'projects/<project_id>/merge_requests',
      required => [qw( project_id source_branch target_branch title )],
      optional => [qw( assignee_id target_project_id )],

    },

    update_merge_request => {

      action   => 'PUT',
      path     => 'projects/<project_id>/merge_request/<merge_request_id>',
      required => [qw( project_id merge_request_id )],
      optional => [qw( source_branch target_branch assignee_id title state_event )],

    },

    accept_merge_request => {

      action   => 'PUT',
      path     => 'projects/<project_id>/merge_request/<merge_request_id/merge',
      required => [qw( project_id merge_request_id )],
      optional => [qw( merge_commit_message )],

    },

    comment_merge_request => {

      action   => 'POST',
      path     => 'projects/:project_id/merge_request/:merge_request_id/comments',
      required => [qw( project_id merge_request_id note )],

    },

    merge_request_comments => {

      action   => 'GET',
      path     => '/projects/<project_id>/merge_request/<merge_request_id>/comments',
      required => [qw( project_id merge_request_id )],

    },

    #######################################################
    ## Issues

    project_issues => {

      action   => 'GET',
      path     => '/projects/<project_id>/issues',
      required => [qw( project_id )],

    },

    issue => {

      action   => 'GET',
      path     => '/projects/<project_id>/issues/<issue_id>',
      required => [qw( project_id issue_id )],

    },

    new_issue => {

      action   => 'POST',
      path     => '/projects/<project_id>/issues',
      required => [qw( project_id title )],
      optional => [qw( description assignee_id milestone_id labels )],

    },

    edit_issue => {

      action   => 'PUT',
      path     => '/projects/<project_id>/issues/<issue_id>',
      required => [qw( project_id issue_id )],
      optional => [qw( title description assignee_id milestone_id labels state_event )],

    },

    #######################################################
    ## Milestones

    milestones => {

      action   => 'GET',
      path     => '/projects/<project_id>/milestones',
      required => [qw( project_id )],

    },

    milestone => {

      action   => 'GET',
      path     => '/projects/<project_id>/milestones/<milestone_id>',
      required => [qw( project_id milestone_id )],

    },

    create_milestone => {

      action   => 'POST',
      path     => '/projects/<project_id>/milestones',
      required => [qw( project_id title )],
      optional => [qw( description due_date )],

    },

    edit_milestone => {

      action   => 'PUT',
      path     => '/projects/<project_id>/milestones/<milestone_id>',
      required => [qw( project_id milestone_id )],
      optional => [qw( title description due_date state_event )],

    },

    #######################################################
    ## Notes

    notes => {

      action   => 'GET',
      path     => '/projects/<project_id>/issues/<issue_id>notes',
      required => [qw( project_id issue_id )],

    },

    note => {

      action   => 'GET',
      path     => '/projects/<project_id>/issues/<issue_id>notes/<note_id>',
      required => [qw( project_id issue_id note_id )],

    },

    create_note => {

      action   => 'POST',
      path     => '/projects/<project_id>/issues/<issue_id>notes',
      required => [qw( project_id issue_id body )],

    },

    snippet_notes => {

      action   => 'GET',
      path     => '/projects/<project_id>/snippets/<snippet_id>notes',
      required => [qw( project_id snippet_id )],

    },

    snippet_note => {

      action   => 'GET',
      path     => '/projects/<project_id>/snippets/<snippet_id>notes/<note_id>',
      required => [qw( project_id snippet_id note_id )],

    },

    create_snippet_note => {

      action   => 'POST',
      path     => '/projects/<project_id>/snippets/<snippet_id>notes',
      required => [qw( project_id snippet_id body )],

    },

    merge_request_notes => {

      action   => 'GET',
      path     => '/projects/<project_id>/merge_requests/<merge_request_id>notes',
      required => [qw( project_id merge_request_id )],

    },

    merge_request_note => {

      action   => 'GET',
      path     => '/projects/<project_id>/merge_requests/<merge_request_id>notes/<note_id>',
      required => [qw( project_id merge_request_id note_id )],

    },

    create_merge_request_note => {

      action   => 'POST',
      path     => '/projects/<project_id>/merge_requests/<merge_request_id>notes',
      required => [qw( project_id merge_request_id body )],

    },

    #######################################################
    ## Deploy Keys

    deploy_keys => {

      action   => 'GET',
      path     => '/projects/<project_id>/keys',
      required => [qw( project_id )],

    },

    deploy_key => {

      action   => 'GET',
      path     => '/projects/<project_id>/keys/<key_id>',
      required => [qw( project_id key_id )],

    },

    add_deploy_key => {

      action   => 'POST',
      path     => '/projects/<project_id>/keys',
      required => [qw( project_id title key )],

    },

    delete_deploy_key => {

      action   => 'DELETE',
      path     => '/projects/<project_id>/keys/<key_id>',
      required => [qw( project_id key_id )],

    },

    #######################################################
    ## System Hooks

    system_hooks => {

      action => 'GET',
      path   => '/hooks',

    },

    add_system_hook => {

      action   => 'POST',
      path     => '/hooks',
      required => [qw( url )],

    },

    test_system_hook => {

      action   => 'GET',
      path     => '/hooks/:hook_id',
      required => [qw( hook_id )],

    },

    delete_system_hook => {

      action   => 'DELETE',
      path     => '/hooks/:hook_id',
      required => [qw( hook_id )],

    },

    #######################################################
    ## Groups

    groups => {

      action => 'GET',
      path   => '/groups',

    },

    group => {

      action   => 'GET',
      path     => '/groups/:group_id',
      required => [qw( group_id )],

    },

    add_group => {

      action   => 'POST',
      path     => '/groups',
      required => [qw( name path )],

    },

    move_project_to_group => {

      action   => 'POST',
      path     => '/groups/:group_id/projects/:project_id',
      required => [qw( group_id project_id )],

    },

    remove_group => {

      action   => 'DELETE',
      path     => '/groups/:group_id',
      required => [qw( group_id )],

    },

    group_members => {

      action   => 'GET',
      path     => '/groups/:group_id/members',
      required => [qw( group_id )],

    },

    add_group_member => {

      action   => 'POST',
      path     => '/groups/:group_id/members',
      required => [qw( group_id user_id access_level )],

    },

    remove_group_member => {

      action   => 'DELETE',
      path     => '/groups/:group_id/members/:user_id',
      required => [qw( group_id user_id )],

    },
  ); ## end %method

  my $valid_methods = join '|', sort keys %method;

  #############################################################################

  sub _set_get {

    # This is ugly, but I want to specifically get rid of the first two
    # elements.

    my ( $self, $key ) = ( shift, shift );

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

  ## no critic qw( Tics::ProhibitLongLines )

  # https://stackoverflow.com/questions/13371583/paramsvalidate-how-to-require-one-of-two-parameters
  # This let's us do something like required => [qw( this|that something )]
  # allowing us to define one parameter or the other, but not both.

  ## use critic qw( Tics::ProhibitLongLines )

  sub _xor_param {
    my $param = shift;
    return sub { defined $_[0] && ! defined $_[1]->{ $param } };
  }

  sub _method {

    my $self = shift;
    my $m    = shift;

    croak "unkown method ($m)"
      unless exists $method{ $m };

    my $method = $method{ $m };

    my $spec;

    if ( exists $method->{ required } ) {

      croak 'required needs to be an arrayref'
        unless ref $method->{ required } eq 'ARRAY';

      $spec->{ $_ } = $validate{ $_ } for @{ $method->{ required } };

      for my $m ( @{ $method->{ required } } ) {

        ## no critic ( RegularExpressions::ProhibitEscapedMetacharacters )

        if ( $m =~ /\|/ ) {

          ## no critic ( NamingConventions::ProhibitAmbiguousNames )

          # _xor_param only supports two arguments
          my ( $first, $second ) = split /\|/, $m, 2;

          ## no critic ( Tics::ProhibitLongLines )
          $spec->{ $first }
            = { $validate{ $first }, callbacks => { "Only one of $first or $second is required" => _xor_param( $second ), }, };

          $spec->{ $second }
            = { $validate{ $second }, callbacks => { "Only one of $first or $second is required" => _xor_param( $first ), }, };

        } else {

          $spec->{ $m } = $validate{ $m };

        }
      } ## end for my $m ( @{ $method...})
    } ## end if ( exists $method...)

    if ( exists $method->{ optional } ) {

      croak 'optional needs to be an arrayref'
        unless ref $method->{ optional } eq 'ARRAY';

      for my $parm ( @{ $method->{ optional } } ) {

        ## no critic qw( Tics::ProhibitLongLines )
        croak "oops ... duplicate key ($parm) in optional and required arrays for method $m"
          if exists $spec->{ $parm };

        $spec->{ $parm } = $validate{ $parm };
        $spec->{ $parm }{ optional } = 1;

      }
    }

    my %data;
    %data = validate_with( params => \@_, spec => $spec )
      if keys %$spec; ## no critic qw( References::ProhibitDoubleSigils )

    if ( keys %data ) {

      return $self->_call_api( $m, \%data );

    } else {

      return $self->_call_api( $m );

    }
  } ## end sub _method

  our $AUTOLOAD;

  sub AUTOLOAD { ## no critic qw( ClassHierarchies::ProhibitAutoloading )

    return if $AUTOLOAD =~ /DESTROY/;

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

    ## no critic qw( References::ProhibitDoubleSigils )
    no strict 'refs'; ## no critic( TestingAndDebugging::ProhibitNoStrict )
    *$AUTOLOAD = $sub;
    use strict 'refs';

    unshift @_, $self;

    goto &$AUTOLOAD;

  } ## end sub AUTOLOAD

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

  sub _ua { return shift->{ ua } ||= LWP::UserAgent->new() }

  sub _call_api {

    my $self = shift;

    my @specs = { type => SCALAR, regex => qr/^($valid_methods)$/ };

    push @specs, { type => HASHREF }
      if scalar @_ > 1;

    my ( $m, $data ) = validate_pos( @_, @specs );

    croak "no action specified for $m"
      unless exists $method{ $m }->{ action };

    my $method = $method{ $m };

    my $action = $method->{ action };
    my $url = sprintf '%s/%s', $self->base_url(), $method->{ path };

    $url =~ s/<$_>/delete $data->{ $_ }/ge for $url =~ /<([^>]*)>/g;

    my $req = HTTP::Request->new( $action => $url );

    $req->content_type( 'application/json' );

    $req->header( 'private_token' => $self->private_token() )
      unless $method->{ path } eq '/session';

    $req->content( encode_json $data )
      if keys %$data; ## no critic ( References::ProhibitDoubleSigils )

    my $res = $self->_ua->request( $req );
    $self->status_code( $res->code() );

    if ( $res->is_success ) {

      return decode_json $res->content;

    } else {

      $self->error( $res->status_line );
      return;

    }
  } ## end sub _call_api
}  # No more hiding

1;
