# --
# Kernel/Output/HTML/FilterElementPost/WarnActiveFilters.pm
# Copyright (C) 2017 - 2022 Perl-Services.de, https://www.perl-services.de/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Output::HTML::FilterContent::WarnActiveFilters;

use strict;
use warnings;

use List::Util qw(first);

our @ObjectDependencies = qw(
    Kernel::System::Web::Request
    Kernel::System::User
    Kernel::Output::HTML::Layout
);

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    $Self->{UserID} = $Param{UserID};

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my $ParamObject  = $Kernel::OM->Get('Kernel::System::Web::Request');
    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $UserObject   = $Kernel::OM->Get('Kernel::System::User');
    my $JSONObject   = $Kernel::OM->Get('Kernel::System::JSON');

    # get template name
    my $Action = $ParamObject->GetParam( Param => 'Action' );

    return 1 if !$Action;
    return 1 if !$Param{Actions}->{$Action};

    # get filters stored in the user preferences
    my %Preferences = $UserObject->GetPreferences(
        UserID => $LayoutObject->{UserID},
    );


    my $StoredFiltersKey = 'UserStoredFilterColumns-' . $Action;
    my $StoredFilters    = $JSONObject->Decode(
        Data => $Preferences{$StoredFiltersKey} || '{}',
    );

    return if !$StoredFilters || !keys %{$StoredFilters};

    my $View = $ParamObject->GetParam( Param => 'View' ) || '';

    # lookup latest used view mode
    if ( !$View && $Preferences{ 'UserTicketOverview' . $Action } ) {
        $View = $Preferences{ 'UserTicketOverview' . $Action };
    }

    return 1 if !$View || $View eq 'Small';

    my $Notification = $LayoutObject->Notify(
        Priority => 'Notice',
        Data     => $LayoutObject->{LanguageObject}->Translate('There are active filters. Those can affect the shown results.'),
        Link     => $LayoutObject->{Baselink} . 'Action=' . $Action . '&DeleteFilters=1',
    );

    ${ $Param{Data} } =~ s{
        <ul \s+ id="Navigation" .*? </ul> \s+ </div> \K
    }{$Notification}xms;

    return 1;
}

1;
