#!/usr/bin/perl -w

# BEGIN LICENSE BLOCK
#
# Copyright (c) 1996-2003 Jesse Vincent <jesse@bestpractical.com>
#
# (Except where explictly superceded by other copyright notices)
#
# This work is made available to you under the terms of Version 2 of
# the GNU General Public License. A copy of that license should have
# been provided with this software, but in any event can be snarfed
# from www.gnu.org.
#
# This work is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
#
# Unless otherwise specified, all modifications, corrections or
# extensions to this work which alter its source code become the
# property of Best Practical Solutions, LLC when submitted for
# inclusion in the work.
#
#
# END LICENSE BLOCK

# This code has been taken from the rt-soap-server.pl distribution available
# from:
#
# http://download.bestpractical.com/pub/rt/devel/rt-soap-server-0.1.tar.gz
#
# This code has then been modified in accordance with the GPL to suit the needs
# of the FleetConf agent tool. These changes will be submitted back to Best
# Practical Solutions, LLC. if that have not already been. I will do my best to
# delineate the places the original code has been modified.
#
# Regards,
# Sterling

use strict;

use vars qw/$VERSION/;

$VERSION = '0.2_004';

$SOAP::Constants::DO_NOT_USE_XML_PARSER = 1;

use lib ( "/opt/rt3/lib", "/opt/rt3/local/lib" );
use RT::EmailParser;

sub RT::Date::AsISO8601 {
    my $self = shift;
    my ( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday ) =
      gmtime( $self->Unix );
    if ( $self->Unix > 0 ) {
        return sprintf( "%04d-%02d-%02dT%02d:%02d:%02dZ",
                        ( $year + 1900 ),
                        ( $mon + 1 ),
                        $mday, $hour, $min, $sec );
    }
    else {
        return '';
    }
}

sub RT::Base::SOAPBuilder {
	my $self = shift;

	my $result;
	if (defined $self) {
		if (UNIVERSAL::can($self, 'for_SOAP')) {
			$result = $self->for_SOAP;
		} else {
			$result = $self;
		}
	} else {
		$result = undef;
	}

	return $result;
}

# {{{ RT object information for soap serialization

package RT::Record;
*SOAPBuilder = \&RT::Base::SOAPBuilder;

sub CustomFieldValues_for_SOAP {
	my $self = shift;

	my %CustomFieldValues;
	my $CustomFields = $self->CustomFields;
	while (my $CustomField = $CustomFields->Next) {
		my $Values = $self->CustomFieldValues($CustomField->Id);

		while (my $Value = $Values->Next) {
			push @{ $CustomFieldValues{$CustomField->Name} }, $Value->Content;
		}
	}

	return \%CustomFieldValues;
}

package RT::SearchBuilder;
*SOAPBuilder = \&RT::Base::SOAPBuilder;

sub for_SOAP {
	my $self = shift;

	return [ map { SOAPBuilder($_) } @{ $self->ItemsArrayRef } ];
}

package RT::User;
*SOAPBuilder = \&RT::Base::SOAPBuilder;

sub for_SOAP {
	my $self = shift;

	return {
		id					=> $self->id,
		Name				=> $self->Name,
		EmailAddress		=> $self->EmailAddress,
		RealName			=> $self->RealName,
	};
}

#our $SOAP_ATTRS = (
#              { Name         => { method => 'Name',         type => 'string' },
#                EmailAddress => { method => 'EmailAddress', type => 'string' },
#                RealName     => { method => 'RealName',     type => 'string' },
#                id           => { method => 'id',           type => 'int' }, }
#);
#
#sub SOAPAttrs { return $RT::User::SOAP_ATTRS; }

package RT::Attachment;
*SOAPBuilder = \&RT::Base::SOAPBuilder;

sub for_SOAP {
	my $self = shift;

	return {
		TransactionId		=> $self->TransactionId,
		Parent				=> $self->Parent,
		MessageId			=> $self->MessageId,
		Subject				=> $self->Subject,
		Filename			=> $self->Filename,
		ContentType			=> $self->ContentType,
		ContentEncoding		=> $self->ContentEncoding,
		Content				=> $self->Content,
		Headers				=> $self->Headers,
	};
}

package RT::Transaction;
*SOAPBuilder = \&RT::Base::SOAPBuilder;

sub for_SOAP {
	my $self = shift;

	return {
		id					=> $self->id,
		Description			=> $self->Description,
		OldValue			=> $self->OldValue,
		NewValue			=> $self->NewValue,
#		Attachments			=> SOAPBuilder($self->Attachments),
	};
}

#our $SOAP_ATTRS = (
#    {  id          => { method => 'id',          type => 'int' },
#       Description => { method => 'Description', type => 'string' },
#       OldValue    => { method => 'OldValue',    type => 'string' },
#       NewValue    => { method => 'NewValue',    type => 'string' },
#       Attachments => { method => 'Attachments', type => 'array' },
#
#    } );
#
#sub SOAPAttrs { return $RT::Transaction::SOAP_ATTRS; }

package RT::Link;
*SOAPBuilder = \&RT::Base::SOAPBuilder;

sub for_SOAP {
	my $self = shift;

	return {
		id					=> $self->id,
		Base				=> $self->Base,
		Target				=> $self->Target,
		Type				=> $self->Type,
	};
}

#our $SOAP_ATTRS = ( { id     => { method => 'id',     type => 'int' },
#                      Base   => { method => 'Base',   type => 'string' },
#                      Target => { method => 'Target', type => 'string' },
#                      Type   => { method => 'Target', type => 'string' }, } );
#sub SOAPAttrs { return $RT::Link::SOAP_ATTRS; }

package RT::Ticket;
*SOAPBuilder = \&RT::Base::SOAPBuilder;

sub for_SOAP {
	my $self = shift;

	my $result = {
		id					=> $self->id,
		Subject				=> $self->Subject,
		Status				=> $self->Status,
		Owner				=> SOAPBuilder($self->OwnerObj),
		Cc					=> SOAPBuilder($self->Cc->UserMembersObj),
		AdminCc				=> SOAPBuilder($self->AdminCc->UserMembersObj),
		Requestors			=> SOAPBuilder($self->Requestors->UserMembersObj),
		DependsOn			=> SOAPBuilder($self->DependsOn),
		DependedOnBy		=> SOAPBuilder($self->DependedOnBy),
		MemberOf			=> SOAPBuilder($self->MemberOf),
		Members				=> SOAPBuilder($self->Members),
		RefersTo			=> SOAPBuilder($self->RefersTo),
		ReferredToBy		=> SOAPBuilder($self->ReferredToBy),
		Transactions		=> SOAPBuilder($self->Transactions),
		Starts				=> $self->StartsObj->AsISO8601,
		Started				=> $self->StartedObj->AsISO8601,
		Due					=> $self->DueObj->AsISO8601,
		Resolved			=> $self->ResolvedObj->AsISO8601,
		Created				=> $self->CreatedObj->AsISO8601,
		Told				=> $self->ToldObj->AsISO8601,
		LastUpdated			=> $self->LastUpdatedObj->AsISO8601,
		Creator				=> $self->CreatorObj->Name,
		LastUpdatedBy		=> $self->LastUpdatedByObj->Name,
		Queue				=> $self->Queue,
		CustomFieldValues   => $self->CustomFieldValues_for_SOAP,
		CustomFields		=> SOAPBuilder($self->CustomFields),
		Type				=> $self->Type,
	};

	my $deps = $self->DependsOn;
	while (my $dep = $deps->Next) {
		next unless $dep->TargetURI->IsLocal;

		my $dep_ticket = RT::Ticket->new($NETRT::CurrentUser);
		$dep_ticket->Load($dep->LocalTarget);

		if ($dep_ticket->Status ne 'resolved') {
			$result->{UnresolvedDependency} = 1;
		}
	}

	$result->{UnresolvedDependency} ||= 0;

	return $result;
}

#$RT::Ticket::SOAP_ATTRS = (
#      { id      => { method => 'id',                       type => 'int' },
#        Subject => { method => 'Subject',                  type => 'string' },
#        Status  => { method => 'Status',                   type => 'string' },
#        Owner   => { method => 'OwnerObj' },
#        Cc      => { method => 'Cc->UserMembersObj' },
#        AdminCc => { method => 'AdminCc->UserMembersObj' },
#        Requestors   => { method => 'Requestors->UserMembersObj' },
#        DependsOn    => { method => 'DependsOn' },
#        DependedOnBy => { method => 'DependedOnBy' },
#        MemberOf     => { method => 'MemberOf' },
#        Members      => { method => 'Members' },
#        RefersTo     => { method => 'RefersTo' },
#        ReferredToBy => { method => 'ReferredToBy' },
#        Transactions => { method => 'Transactions' },
#        Starts => { method => 'StartsObj->AsISO8601', type => 'datetime' },
#        Started  => { method => 'StartedObj->AsISO8601',  type => 'datetime' },
#        Due      => { method => 'DueObj->AsISO8601',      type => 'datetime' },
#        Resolved => { method => 'ResolvedObj->AsISO8601', type => 'datetime' },
#        Created  => { method => 'CreatedObj->AsISO8601',  type => 'datetime' },
#        Told     => { method => 'ToldObj->AsISO8601',     type => 'datetime' },
#        LastUpdated =>
#          { method => 'LastUpdatedObj->AsISO8601', type => 'datetime' },
#        Creator       => { method => 'CreatorObj->Name' },
#        LastUpdatedBy => { method => 'LastUpdatedByObj->Name' },
#        Queue         => { method => 'QueueObj->Name' },
#		QueueObj      => { method => 'QueueObj' },
#		CustomFields  => { method => 'CustomFields' },
#		CustomFieldValues => { method => 'CustomFieldValues' },
#        Type          => { method => 'Type' }, } );
#
#sub SOAPAttrs { return $RT::Ticket::SOAP_ATTRS; }

package RT::CustomFields;
*SOAPBuilder = \&RT::Base::SOAPBuilder;

sub for_SOAP {
	my $self = shift;

	my %result;
	while (my $cf = $self->Next) {
		$result{$cf->Name} = SOAPBuilder($cf);
	}

	return \%result;
}

package RT::CustomField;
*SOAPBuilder = \&RT::Base::SOAPBuilder;

sub for_SOAP {
	my $self = shift;

	return {
		id					=> $self->id,
		Name				=> $self->Name,
		Type				=> $self->Type,
		MaxValues			=> $self->MaxValues,
		Pattern				=> $self->Pattern,
		Repeated			=> $self->Repeated,
		Description			=> $self->Description,
		SortOrder			=> $self->SortOrder,
		LookupType			=> $self->LookupType,
		Disabled			=> $self->Disabled,
	};
}

#$RT::CustomField::SOAP_ATTRS = (
#	{	id				=> { method => 'id',				type => 'int' },
#		Name			=> { method => 'Name', 				type => 'string' },
#		Type			=> { method => 'Type',				type => 'string' },
#		MaxValues		=> { method => 'MaxValues',			type => 'int' },
#		Pattern			=> { method => 'Pattern',			type => 'string' },
#		Repeated		=> { method => 'Repeated',			type => 'string' },
#		Description		=> { method => 'Description',		type => 'string' },
#		SortOrder		=> { method => 'SortOrder',			type => 'int' },
#		LookupType		=> { method => 'LookupType',		type => 'string' },
#		Disabled		=> { method => 'Disabled',			type => 'int' }, } );
#
#sub SOAPAttrs { return $RT::CustomField::SOAP_ATTRS; }
#
#sub SOAPMapKey { 
#	my $self = shift;
#	return $self->Name; 
#}

package RT::ObjectCustomFieldValue;
*SOAPBuilder = \&RT::Base::SOAPBuilder;

sub for_SOAP {
	my $self = shift;

	return {
		CustomField			=> $self->CustomField,
		ObjectType			=> $self->ObjectType,
		ObjectId			=> $self->ObjectId,
		SortOrder			=> $self->SortOrder,
		Content				=> $self->Content,
		LargeContent		=> $self->LargeContent,
		ContentType			=> $self->ContentType,
		ContentEncoding		=> $self->ContentEncoding,
		Disabled			=> $self->Disabled,
	};
}

package RT::Attachment;
*SOAPBuilder = \&RT::Base::SOAPBuilder;

sub for_SOAP {
	my $self = shift;

	return {
		TransactionId		=> $self->TransactionId,
		Parent				=> $self->Parent,
		MessageId			=> $self->MessageId,
		Subject				=> $self->Subject,
		Filename			=> $self->Filename,
		ContentType			=> $self->ContentType,
		ContentEncoding		=> $self->ContentEncoding,
		Content				=> $self->Content,
		Headers				=> $self->Headers,
	};
}

#$RT::ObjectCustomFieldValue::SOAP_ATTRS = (
#	{	CustomField		=> { method => 'CustomField',		type => 'int' },
#		ObjectType		=> { method => 'ObjectType',		type => 'string' },
#		ObjectId		=> { method => 'ObjectId',			type => 'int' },
#		SortOrder		=> { method => 'SortOrder',			type => 'int' },
#		Content			=> { method => 'Content',			type => 'string' },
#		LargeContent	=> { method => 'LargeContent',		type => 'string' },
#		ContentType		=> { method => 'ContentType',		type => 'string' },
#		ContentEncoding	=> { method => 'ContentEncoding',	type => 'string' },
#		Disabled		=> { method => 'Disabled',			type => 'int' }, } );
#
#sub SOAPAttrs { return $RT::ObjectCustomFieldValue::SOAP_ATTRS; }
#
#sub SOAPMapKey { 
#	my $self = shift;
#	my $cf = RT::CustomField->new($RT::SystemUser);
#	$cf->Load($self->CustomField);
#	return $cf->Name;
#}

# }}}

# {{{ Glue to turn on serializers 

#*SOAP::Serializer::as_RT__Transaction = \&SOAP::Serializer::as_RT__Record;
#*SOAP::Serializer::as_RT__User        = \&SOAP::Serializer::as_RT__Record;
#*SOAP::Serializer::as_RT__Ticket      = \&SOAP::Serializer::as_RT__Record;
#*SOAP::Serializer::as_RT__Link        = \&SOAP::Serializer::as_RT__Record;
#*SOAP::Serializer::as_RT__Links = \&SOAP::Serializer::as_RT__SearchBuilder;
#*SOAP::Serializer::as_RT__Transactions =
#  \&SOAP::Serializer::as_RT__SearchBuilder;
#*SOAP::Serializer::as_RT__Users   = \&SOAP::Serializer::as_RT__SearchBuilder;
#*SOAP::Serializer::as_RT__Tickets = \&SOAP::Serializer::as_RT__SearchBuilder;
#*SOAP::Serializer::as_RT__Attachments =
#  \&SOAP::Serializer::as_RT__SearchBuilder;
#*SOAP::Serializer::as_RT__Queue = \&SOAP::Serializer::as_RT__Record;
#*SOAP::Serializer::as_RT__CustomFields = \&SOAP::Serializer::as_RT__SearchBuilder_mapped;
#*SOAP::Serializer::as_RT__CustomField = \&SOAP::Serializer::as_RT__Record;
#*SOAP::Serializer::as_RT__ObjectCustomFieldValues = \&SOAP::Serializer::as_RT__SearchBuilder_mapped;
#*SOAP::Serializer::as_RT__ObjectCustomFieldValue = \&SOAP::Serializer::as_RT__Record;
#
## }}}
#
## {{{ Custom serializers 
##sub SOAP::Serializer::as_RT__ObjectCustomFieldValues {
##}
##
##sub SOAP::Serializer::as_RT__ObjectCustomFieldValue {
##}
#
#sub SOAP::Serializer::as_RT__SearchBuilder {
#    my ( $self, $object, $name, $type, $attrib ) = @_;
#
#    $self->{'skip_attrs'} = $object->{'SOAP_skip_attrs'}
#      unless ( $self->{'skip_attrs'} );
#
#    $attrib->{'xmlns:bp'} = "http://schema.bestpractical.com/";
#    $attrib->{'xsi:type'} = "bp:$type";
#
#    my @serialized_content;
#    while ( my $record = $object->Next ) {
#        push @serialized_content, $self->encode_object($record);
#    }
#    my $retvals = [ $name, $attrib, [@serialized_content] ];
#
#    return ($retvals);
#}
#
#sub SOAP::Serializer::as_RT__SearchBuilder_mapped {
#    my ( $self, $object, $name, $type, $attrib ) = @_;
#
#    $self->{'skip_attrs'} = $object->{'SOAP_skip_attrs'}
#      unless ( $self->{'skip_attrs'} );
#
#    $attrib->{'xmlns:bp'} = "http://schema.bestpractical.com/";
#    $attrib->{'xsi:type'} = "bp:$type";
#
#    my @serialized_content;
#    while ( my $record = $object->Next ) {
#		my $rec_name = $record->SOAPMapKey;
#		my $enc_record = $self->encode_object($record);
#		$enc_record->[0] = $rec_name;
#		push @serialized_content, $enc_record;
#    }
#    my $retvals = [ $name, $attrib, [@serialized_content] ];
#
#    return ($retvals);
#}
#
#sub SOAP::Serializer::as_RT__Record {
#    my ( $self, $object, $name, $type, $attrib ) = @_;
#
#    $self->{'skip_attrs'} = $object->{'SOAP_skip_attrs'}
#      unless ( $self->{'skip_attrs'} );
#    $attrib->{'xmlns:bp'} = "http://schema.bestpractical.com/";
#    $attrib->{'xsi:type'} = "bp:$type";
#
#    my @serialized_content;
#    my $ATTRS = $object->SOAPAttrs;
#    foreach my $attr ( keys %$ATTRS ) {
#        next if ( $self->{'skip_attrs'}->{ ref($object) }->{$attr} );
#
#		#print STDERR "Looking at ".ref($object).".".$attr."\n";
#        my $local_object = $object;  #Since we may futz with it inside the loop;
#             # though we do want it to reset on each iteration
#        my $method = $ATTRS->{$attr}->{'method'};
#        while ( $method =~ /^(.*?)\-\>(.*)$/ ) {
#            $local_object = $local_object->$1() if ( $local_object->can($1) );
#            $method = $2;
#        }
#
##        unless ( $local_object->can($method) ) {
##
##print STDERR "Can $local_object $method? -- ".($local_object->can($method)? 'yes': 'no'). "\n";
##        }
#        my $data;
#        my $type    = $ATTRS->{$attr}->{'type'};
#        my $content = $local_object->$method();
#
#
##We may want to serialize this object as something else to get it to use a different serializer
## SOAP lite should have some other facility for that.
##        if (UNIVERSAL::isa( $content, 'RT::SearchBuilder' ) ) {
##            my @values = @{$content->ItemsArrayRef};
##            $content = \@values;
##        }
#
#        $data =
#          $self->encode_object( $content, $attr, $ATTRS->{$attr}->{'type'} );
#        push @serialized_content, $data;
#    }
#    my $retvals = [ $name, $attrib, [@serialized_content] ];
#
#    return ($retvals);
#}
# }}}

package RT;

use RT;
use RT::Tickets;

# Load the config file
RT::LoadConfig();

#Connect to the database and get RT::SystemUser and RT::Nobody loaded
RT::Init();

package main;

my $port = pop (@ARGV) || 9000;
my $host = shift (@ARGV) || 'localhost';

use SOAP::Transport::HTTP;
# 
# Stand-alone servers are gross. HTTP AUTH is gross. Instead, we need to make
# sure that we use Apache and have SSL key authentication working properly.
# Agents shouldn't communicate over the clear when information might be
# sensitive anyway.
#

#use Hook::LexWrap;

#Hook::LexWrap::wrap SOAP::Transport::HTTP::Server::handle, pre => sub {
#    my $self = shift->new;
#    my ($user,$pass);
#    my $credentials = $self->request->headers->authorization_basic;
#    if ($credentials =~ /^(.*?):(.*)$/) {
#        $user = $1;
#        $pass = $2;
#    }
#    $NETRT::CurrentUser  = RT::CurrentUser->new($user);
#
#    unless ($NETRT::CurrentUser->id) {
#        undef ($NETRT::CurrentUser);
#        # this is how hook lexwrap lets us short circuit running the original sub
#        $_[-1] = $self->response(HTTP::Response->new(401)) # FORBIDDEN
#    }
#    unless ($NETRT::CurrentUser->IsPassword($pass)) {
#        undef ($NETRT::CurrentUser);
#        $_[-1] = $self->response(HTTP::Response->new(401)) # FORBIDDEN
#
#    }
#
#    unshift @_, ref($self);
# };
#
#
#
#print "Ready\n";
#SOAP::Transport::HTTP::Daemon->new( LocalPort => $port, Reuse => 1 )
#  ->dispatch_to('NETRT')->handle;

# If you need to know how to configure SSL and such, see the relavent Apache
# documentation. If you're using some other web server...uh...you're on your
# own.
#
# -- Sterling Hanenkamp

binmode STDOUT, ":utf8";

unless (defined $ENV{HTTPS} && $ENV{HTTPS} eq 'on') {
	print "HTTP/1.1 401 Unauthorized\n";
	print "Content-type: text/plain\n\n";

	print "ERROR: Only accessible when SSL enabled.\n";
}

my $commonName = $ENV{SSL_CLIENT_S_DN_CN};

unless ($commonName) {
	print "HTTP/1.1 401 Unauthorized\n";
	print "Content-type: text/plain\n\n";

	print "ERROR: Misconfiguration or an improper SSL key was given.\n";
}

$NETRT::CurrentUser = RT::CurrentUser->new($RT::SystemUser);
$NETRT::CurrentUser->LoadByName($commonName);

unless ($NETRT::CurrentUser->Id) {
	print "HTTP/1.1 401 Unauthorized\n";
	print "Content-type: text/plain\n\n";

	print "ERROR: Invalid user '$commonName' attempting to access SSL protected section.\n";
}

SOAP::Transport::HTTP::CGI
	-> dispatch_to ('NETRT')
	-> handle;

package NETRT;

use vars qw/$CurrentUser/;

our $DEBUG = 1;

sub lockTicket {
	my $self = shift;
	my $id = shift;
	my $lock_field = shift;
	my $commit_field = shift;
	my $mnemonic = shift;
	
	$RT::Handle->BeginTransaction();

	my $ticket = RT::Ticket->new($CurrentUser);
	$ticket->Load($id);

	my $values = $ticket->CustomFieldValues($lock_field);
	while (my $value = $values->Next) {
		if ($value->Content eq $mnemonic) {
			$RT::Handle->Rollback();
			return 0;
		}
	}

	my $values = $ticket->CustomFieldValues($commit_field);
	while (my $value = $values->Next) {
		if ($value->Content eq $mnemonic) {
			$RT::Handle->Rollback();
			return 0;
		}
	}

	my ($ret, $msg) = $ticket->AddCustomFieldValue(
		Field => $lock_field,
		Value => $mnemonic,
	);

	if ($ret) {
		$RT::Handle->Commit();
		return 1;
	} else {
		$RT::Handle->Rollback();
		return 0;
	}
}

sub unlockTicket {
	my $self = shift;
	my $id = shift;
	my $lock_field = shift;
	my $commit_field = shift;
	my $error_field = shift;
	my $mnemonic = shift;
	my $is_error = shift;

	$RT::Handle->BeginTransaction();

	my $ticket = RT::Ticket->new($CurrentUser);
	$ticket->Load($id);

	my $lock = RT::CustomField->new($CurrentUser);
	$lock->Load($lock_field);

	my $commit = RT::CustomField->new($CurrentUser);
	$commit->Load($commit_field);

	my $error = RT::CustomField->new($CurrentUser);
	$error->Load($error_field);

	my $success = 1;

	my ($ret, $msg) = $ticket->AddCustomFieldValue(
		Field => $commit,
		Value => $mnemonic,
	);
	$success &= $ret;

	if ($is_error) {
		my ($ret, $msg) = $ticket->AddCustomFieldValue(
			Field => $error,
			Value => $mnemonic,
		);
		$success &= $ret;
	}

	my ($ret, $msg) = $ticket->DeleteCustomFieldValue(
		Field => $lock,
		Value => $mnemonic,
	);
	$success &= $ret;

	if ($success) {
		$RT::Handle->Commit();
		return 1;
	} else {
		$RT::Handle->Rollback();
		return 0;
	}
}


# {{{ createTicket
sub createTicket {
    my $self = shift;
    my %args  = (
                @_);

    my @Actions;

    my $due = new RT::Date( $CurrentUser );
    $due->Set( Format => 'unknown', Value => $args{'Due'} );
    my $starts = new RT::Date( $CurrentUser);
    $starts->Set( Format => 'unknown', Value => $args{'Starts'} );


    my $ticket = RT::Ticket->new($CurrentUser);

    my $parser = RT::EmailParser->new();
    $parser->ParseMIMEEntityFromScalar($args{'MimeMessage'});

    my %create_args = (
        Queue           => $args{'Queue'},
        Owner           => $args{'Owner'},
        InitialPriority => $args{'InitialPriority'},
        FinalPriority   => $args{'FinalPriority'},
        TimeLeft        => $args{'TimeLeft'},
        TimeEstimated        => $args{'TimeEstimated'},
        TimeWorked      => $args{'TimeWorked'},
        Requestor       => $args{'Requestors'},
        Cc              => $args{'Cc'},
        AdminCc         => $args{'AdminCc'},
        Subject         => $args{'Subject'},
        Status          => ($args{'Status'} || 'new'),
        Due             => $due->ISO,
        Starts          => $starts->ISO,
        MIMEObj         => $parser->Entity
    );
  foreach my $arg (%args) {
        if ($arg =~ /^CustomField-(\d+)(.*?)$/) {
            $create_args{"CustomField-".$1} = $args{"$arg"};
        }
    }
    my ( $id, $Trans, $ErrMsg ) = $ticket->Create(%create_args);
    unless ( $id && $Trans ) {
        return({ status => $id, message => $ErrMsg});
    }
    my @linktypes = qw( DependsOn MemberOf RefersTo );

    foreach my $linktype (@linktypes) {
        foreach my $luri ( split ( / /, $args{"new-$linktype"} ) ) {
            $luri =~ s/\s*$//;    # Strip trailing whitespace
            my ( $val, $msg ) = $ticket->AddLink( Target => $luri, Type   => $linktype);
            push ( @Actions,  { status => $val, message => $msg }) unless ($val);
        }

        foreach my $luri ( split ( / /, $args{$linktype."-new"} ) ) {
            $luri =~ s/\s*$//;    # Strip trailing whitespace
            my ( $val, $msg ) = $ticket->AddLink( Base => $luri, Type => $linktype);
            push ( @Actions,  { status => $val, message => $msg }) unless ($val);
       }
   }


            return ( { status => $id, message => $ErrMsg });
}
# }}}

# {{{ getTicket
sub getTicket {
    my $self = shift;
    my $id   = shift;

#    print "in getTicket for $id\n";
#    print STDERR "in getTicket for $id\n";
    my $ticket = RT::Ticket->new($CurrentUser);
    $ticket->Load($id);

    return (RT::Base::SOAPBuilder($ticket));
}

# }}}

# {{{ getTickets 
sub getTickets {
    my $self  = shift;
    my $query = shift;
#    print "in getTickets for $query\n";
#    print STDERR "in getTickets for $query\n";
#    local $RT::Ticket::SOAP_ATTRS = $RT::Ticket::SOAP_ATTRS;
#    delete $RT::Ticket::SOAP_ATTRS->{'Transactions'};
    my $tix = RT::Tickets->new($CurrentUser);
    $tix->FromSQL($query);

#    foreach my $ticket (@{$tix->ItemsArrayRef}) {
#        print "Looking at ticket ".$ticket->id ."\n";
#        print STDERR "Looking at ticket ".$ticket->id ."\n";
#    }
    return (RT::Base::SOAPBuilder($tix));
}
# }}}

# {{{ updateTicket
sub updateTicket {
    my $self = shift;
    my %args = (@_);

    my $ticket = RT::Ticket->new($CurrentUser);
    $ticket->Load( $args{'id'} );
    unless ( $ticket->id ) {
        return ( { status => 0, message => "Invalid ticket id" } );
    }

    my $parser = RT::EmailParser->new();
    $parser->ParseMIMEEntityFromScalar($args{'MimeMessage'});

    if ( $args{'UpdateType'} eq 'comment' ) {
        my ( $val, $msg ) = $ticket->Comment( MIMEObj => $parser->Entity,
                                              TimeWorked => $args{'TimeWorked'},
                                              CcMessageTo  => $args{'Cc'},
                                              BccMessageTo => $args{'Bcc'} );

        return ( { status => $val, message => $msg } ) unless ($val);

    }
    elsif ( $args{'UpdateType'} eq 'reply' ) {
        my ( $val, $msg ) = $ticket->Correspond( MIMEObj => $parser->Entity,
                                              TimeWorked => $args{'TimeWorked'},
                                              CcMessageTo  => $args{'Cc'},
                                              BccMessageTo => $args{'Bcc'} );

        return ( { status => $val, message => $msg } ) unless ($val);
    }
    else {
        return ( { status => 0, message => 'Update type unknown' } );
    }

    if ( $args{'Status'} && $args{'Status'} ne $ticket->Status ) {
        my ( $val, $msg ) = $ticket->SetStatus( $args{'Status'} );

        return ( { status => $val, message => $msg } ) unless ($val);
    }

    return ( { status => 1, message => 'Ticket updated' } );
}
# }}}

# {{{ modifyTicket

sub modifyTicket {
        my $self = shift;
    my %args = (@_);
  # {{{ Set basic fields 
    my @attribs = qw(
      Subject
      FinalPriority
      Priority
      TimeEstimated
      TimeWorked
      TimeLeft
      Status
      Queue
    );



    my $ticket = RT::Ticket->new($CurrentUser);
    $ticket->Load( $args{'id'} );
    unless ( $ticket->id ) {
      return ( { status => 0, message => "Invalid ticket id" } );
    }


    my @return_values;

    if ( $args{'Queue'} and ( $args{'Queue'} !~ /^(\d+)$/ ) ) {
        my $tempqueue = RT::Queue->new($CurrentUser);
        $tempqueue->Load( $args{'Queue'} );
        if ( $tempqueue->id ) {
            $args{'Queue'} = $tempqueue->Id();
        }
    }

    @return_values = RT::SOAP::Private::_UpdateRecordObject(
        AttributesRef => \@attribs,
        Object        => $ticket,
        ARGSRef       => \%args,
    );

    # We special case owner changing, so we can use ForceOwnerChange
    if ( $args{'Owner'} && ( $ticket->Owner != $args{'Owner'} ) ) {
        my ($ChownType);
        if ( $args{'ForceOwnerChange'} ) {
            $ChownType = "Force";
        }
        else {
            $ChownType = "Give";
        }

        my ( $val, $msg ) =
          $ticket->SetOwner( $args{'Owner'}, $ChownType );
        push ( @return_values, { attrib => 'Owner', message => $msg, status => $val} );
    }
    # }}}

    
    # {{{ Set custom fields
    my $custom_fields_to_mod;
    foreach my $arg ( keys %args ) {
        if ( $arg =~ /^CustomField-(\d+)-/ ) {

            # For each of those tickets, find out what custom fields we want to work with.
            $custom_fields_to_mod->{$1} = 1;
        }
    }

    # For each custom field
    foreach my $cf ( keys %{$custom_fields_to_mod} ) {

    foreach my $arg ( keys %args) {
        next unless ( $arg =~ /^CustomField-$cf-/ );
        my @values = ( ref( $args{$arg} ) eq 'ARRAY' ) ? @{ $args{$arg} } : ( $args{$arg} );
        if ( ( $arg =~ /-AddValue$/ ) || ( $arg =~ /-Value$/ ) ) {
            foreach my $value (@values) {
                next unless ($value);
                my ( $val, $msg ) = $ticket->AddCustomFieldValue(Field => $cf,
                                                                 Value => $value
                );
                push ( @return_values, $msg );
            }
        }
        elsif ( $arg =~ /-DeleteValues$/ ) {
            foreach my $value (@values) {
                next unless ($value);
                my ( $val, $msg ) = $ticket->DeleteCustomFieldValue(
                                                                 Field => $cf,
                                                                 Value => $value
                );
                push ( @return_values, $msg );
            }
        }
        elsif ( $arg =~ /-Values/ ) {
            my $cf_values = $ticket->CustomFieldValues($cf);

            my %values_hash;
            foreach my $value (@values) {
                next unless ($value);

                # build up a hash of values that the new set has
                $values_hash{$value} = 1;

                unless ( $cf_values->HasEntry($value) ) {
                    my ( $val, $msg ) = $ticket->AddCustomFieldValue(
                                                                 Field => $cf,
                                                                 Value => $value
                    );
                    push ( @return_values, $msg );
                }

            }
            while ( my $cf_value = $cf_values->Next ) {
                unless ( $values_hash{ $cf_value->Content } == 1 ) {
                    my ( $val, $msg ) = $ticket->DeleteCustomFieldValue(
                                                     Field => $cf,
                                                     Value => $cf_value->Content
                    );
                    push ( @return_values, $msg );

                }

            }
        }
        else {
            push ( @return_values,
                   "User asked for an unknown update type for custom field "
                     . $cf->Name
                     . " for ticket "
                     . $ticket->id );
        }
    }
}


    # }}} end of custom fields stuff


# {{{ Deal with watchers
   foreach my $key ( keys %args ) {
    if ($key =~ /^(Requestors|Cc|AdminCc)$/) {
        my $type = $1;
        my $members = $ticket->$1()->UserMembersObj;
        my @current = map {$_->Name } @{$members->ItemsArrayRef};
        my @new = @{$args{$key}};


        my (@to_add, @to_delete) ;
        my %seen;
        foreach my $item (@current) {
            $seen{$item} = 1; 
        }
        foreach my $item(@new) {
            $seen{$item} += 2;
        }
        foreach my $item (keys %seen) {
            push @to_delete, $item if ($seen{$item} == 1) ;
            push @to_add, $item if ($seen{$item} == 2) ;
        }    
   
        # TODO Requestors changes to Requestor. this is lame. Fix in the core to accept both 
        $type =~ s/s$//;

        foreach my $item (@to_delete) {
            my ($id, $msg) = $ticket->DeleteWatcher(Type => $type, Email => $item);
            push (@return_values, { message => $msg, status => $id, attribute => "Delete".$type, value => $item});
        }

        foreach my $item (@to_add) {
            my ($id, $msg) = $ticket->AddWatcher(Type => $type, Email => $item);
            push (@return_values, { message => $msg, status => $id, attribute => "Add".$type, value => $item});
        }


    }
        

   } 

# }}}



    return @return_values;

}
# }}}


package RT::SOAP::Private;

# {{{ _UpdateRecordObj 
=head2 _UpdateRecordObj ( ARGSRef => \%ARGS, Object => RT::Record, AttributesRef =>
 \@attribs)

@attribs is a list of ticket fields to check and update if they differ from the  B
<Object>'s current values. ARGSRef is a ref to a paramhash.

Returns an array of success/failure hashes

=cut

sub _UpdateRecordObject {
    my %args = (
        ARGSRef       => undef,
        AttributesRef => undef,
        Object        => undef,
        AttributePrefix => undef,
        @_
    );

    my (@results);

    my $object     = $args{'Object'};
    my $attributes = $args{'AttributesRef'};
    my $ARGSRef    = $args{'ARGSRef'};
    foreach my $attribute (@$attributes) {
        my $value;
        if ( defined $ARGSRef->{$attribute} ) {
            $value = $ARGSRef->{$attribute};
        }
        elsif ( defined( $args{'AttributePrefix'} ) &&
                defined( $ARGSRef->{ $args{'AttributePrefix'} . "-" . $attribute })) {
            $value = $ARGSRef->{ $args{'AttributePrefix'} . "-" . $attribute };

        } else {
                next;
        }

            $value =~ s/\r\n/\n/gs;
        if ( $value ne $object->$attribute() ) {
            my $method = "Set$attribute";
            my ( $status, $msg ) = $object->$method($value);

            push @results,
              { attribute => $attribute,
                status    => $status,
                message   => $msg };
        }
    }
    return (@results);
}
# }}}


=head1 THE PLAN


Create wrapper objects for:

    Ticket
    User
    Group
    Queue
    Transaction
    Attachment

=cut

