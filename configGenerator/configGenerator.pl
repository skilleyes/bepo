#!/usr/bin/perl -w

###########################################################################
#   Copyright (C) 2008 by Nicolas Chartier                                #
#   chartier.nicolas@gmail.com                                            #
#                                                                         #
#   This program is free software; you can redistribute it and/or modify  #
#   it under the terms of the GNU General Public License as published by  #
#   the Free Software Foundation; either version 3 of the License, or     #
#   (at your option) any later version.                                   #
#                                                                         #
#   This program is distributed in the hope that it will be useful,       #
#   but WITHOUT ANY WARRANTY; without even the implied warranty of        #
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         #
#   GNU General Public License for more details.                          #
#                                                                         #
#   You should have received a copy of the GNU General Public License     #
#   along with this program; if not, write to the                         #
#   Free Software Foundation, Inc.,                                       #
#   59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.             #
###########################################################################

# TODO

# xkb :
# - gestion des level four alphabetic
# compose :
# - gestion de la surcharge
# msklc :
# - gestion du capslock pour msklc
# xmodmap :
# - générer via layout.conf les touches qui sont mises en dur dans le footer
# loadkeys :
# - tout

# source C :
# - tout

# auto hotkeys :
# - tout
# allchars :
# - tout

# Notes
# le format Mac OS X est généré à partir des fichiers xkb par le script de gaetan

use strict;
use Data::Dumper;

die("Usage: $0 <layout description file> <deadkey behaviour file> <output format>\n")
    if (!defined($ARGV[2]));

my $LAYOUT_DESCRIPTION = $ARGV[0];
my $DEAKEY_BEHAVIOUR   = $ARGV[1];
my $OUTPUT_FORMAT      = $ARGV[2];

my $KEYS_FILE    = "keys.conf";
my $SYMBOLS_FILE = "symbols.conf";

# Column 0: key/symbole code
# Column 1: scancode/unicode
my $x_xkb_column     = 2;
my $x_xmodmap_column = 3;
my $win_msklc_column = 4;

my %keys      = ();
my %scanCodes = ();

my %symbols  = ();
my %unicodes = ();

my @layoutKeys = ();
my %layoutSyms = ();

my @deadKeysA = ();
my %deadKeysH = ();

sub loadKeys($)
{
    my $column = shift;

    open(FILE, "< $KEYS_FILE") or die("open: $!");

    LINE: while (<FILE>)
    {
        next LINE if /^#/;
        next LINE if /^\s*$/;

        chomp;
        s/#.*$//g;
        my @array = split(/ +|\t/);
        $scanCodes{$array[0]} = $array[1];
        $keys{$array[0]} = $array[$column];
    }

    close(FILE);

#print Dumper(\%keys);
}

sub loadSymbols($)
{
    my $column = shift;

    open(FILE, "< $SYMBOLS_FILE") or die("open: $!");

    LINE: while (<FILE>)
    {
        next LINE if /^#/;
        next LINE if /^\s*$/;

        chomp;
        s/#.*$//g;
        my @array = split(/ +|\t/);

        if (defined($unicodes{$array[0]}))
        {
            print STDERR "Duplicate unicode: ".$array[0]."\n";
            next LINE;
        }
        if (defined($symbols{$array[0]}))
        {
            print STDERR "Duplicate symbol: ".$array[0]."\n";
            next LINE;
        }

        $unicodes{$array[0]} = $array[1];
        $symbols{$array[0]} = $array[$column];
    }

    close(FILE);

#print Dumper(\%symbols);
}

sub loadLayout()
{
    open(FILE, "< $LAYOUT_DESCRIPTION") or die("open: $!");

    LINE: while (<FILE>)
    {
        next LINE if /^#/;

        if (/^\s*$/)
        {
            push(@layoutKeys, "");
            next LINE;
        }

        chomp;
        s/#.*$//g;
        my @array = split(/ +|\t/);
        my $key = $array[0];
        my %symbols = ();
        $symbols{'direct'}      = $array[1];
        $symbols{'shift'}       = $array[2];
        $symbols{'altgr'}       = $array[3];
        $symbols{'altgr+shift'} = $array[4];

        push(@layoutKeys, $key);
        $layoutSyms{$key} = \%symbols;
    }

    close(FILE);

#print Dumper(\@layoutKeys);
#print Dumper(\%layoutSyms);
}

sub loadDeadKeys()
{
    open(FILE, "< $DEAKEY_BEHAVIOUR") or die("open: $!");

    LINE: while (<FILE>)
    {
        next LINE if /^#/;

        if (/^\s*$/)
        {
            push(@deadKeysA, "");
            next LINE;
        }

        chomp;
        s/#.*$//g;
        my @array = split(/ +|\t/);
        my $symbol = pop(@array);

        push(@deadKeysA, \@array);
        $deadKeysH{\@array} = $symbol;
    }

    close(FILE);

#print Dumper(\@deadKeysA);
#print Dumper(\%deadKeysH);
}

sub gen_x_xkb_header()
{
    my $header = "partial alphanumeric_keys\nxkb_symbols \"dvorak\" {\n\n".
                 "\tname[Group1]= \"France - Bepo, ergonomic, Dvorak way\";\n";

    return $header;
}

sub gen_x_xmodmap_header()
{
    my $header = "clear    shift\n".
                 "clear    lock\n".
                 "clear    control\n".
                 "clear    mod1\n".
                 "clear    mod2\n".
                 "clear    mod3\n".
                 "clear    mod4\n".
                 "clear    mod5\n";

    return $header;
}

sub gen_win_msklc_header()
{
    my $header = "KBD\tbepo0651\t\"fr-dvorak-bépo v0.6.5.1\"\r\n".
                 "\r\n".
                 "COPYRIGHT\t\"Public Domain\"\r\n".
                 "\r\n".
                 "COMPANY\t\"wiki pour la conception d un dvorak francais\"\r\n".
                 "\r\n".
                 "LOCALENAME\t\"fr-FR\"\r\n".
                 "\r\n".
                 "LOCALEID\t\"0000040c\"\r\n".
                 "\r\n".
                 "VERSION\t1.0\r\n".
                 "\r\n".
                 "SHIFTSTATE\r\n".
                 "\r\n".
                 "0\t//Column 4\r\n".
                 "1\t//Column 5 : Shft\r\n".
                 "2\t//Column 6 :       Ctrl\r\n".
                 "6\t//Column 7 :       Ctrl Alt\r\n".
                 "7\t//Column 8 : Shft  Ctrl Alt\r\n\r\n".
                 "LAYOUT\t\t;an extra '\@' at the end is a dead key\r\n".
                 "\r\n".
                 "//SC\tVK_\t\tCap\t0\t1\t2\t6\t7\r\n".
                 "//--\t----\t\t----\t----\t----\t----\t----\t----\r\n";

    return $header;
}

sub gen_x_xkb_body()
{
    my $body = "";

    for my $key (@layoutKeys)
    {
        if ($key eq "")
        {
            $body .= "\n";
            next;
        }

        if (!defined($keys{$key}))
        {
            print STDERR "Unknown key: ".$key."\n";
            next;
        }

        my %keySymbols = %{$layoutSyms{$key}};
        my $lineEnd = " ] };\n";
        my $nextSymbolExists = 0;
        my $voidSymbol = "VoidSymbol";

        # AltGr + Shift
        if (defined($keySymbols{'altgr+shift'}) && $keySymbols{'altgr+shift'} ne "")
        {
            if (!defined($symbols{$keySymbols{'altgr+shift'}}))
            {
                print STDERR "Unknown symbol: ".$key."{'altgr+shift'}: ".$keySymbols{'altgr+shift'}."\n";
                next;
            }
            $lineEnd = ", ".$symbols{$keySymbols{'altgr+shift'}}.$lineEnd;
            $nextSymbolExists = 1;
        }

        # AltGr
        if (defined($keySymbols{'altgr'}) && $keySymbols{'altgr'} ne "")
        {
            if (!defined($symbols{$keySymbols{'altgr'}}))
            {
                print STDERR "Unknown symbol: ".$key."{'altgr'}: ".$keySymbols{'altgr'}."\n";
                next;
            }
            $lineEnd = ", ".$symbols{$keySymbols{'altgr'}}.$lineEnd;
            $nextSymbolExists = 1;
        }
        else
        {
            $lineEnd = ", ".$voidSymbol.$lineEnd
                if ($nextSymbolExists == 1);
        }

        # Shift
        if (defined($keySymbols{'shift'}) && $keySymbols{'shift'} ne "")
        {
            if (!defined($symbols{$keySymbols{'shift'}}))
            {
                print STDERR "Unknown symbol: ".$key."{'shift'}: ".$keySymbols{'shift'}."\n";
                next;
            }
            $lineEnd = ", ".$symbols{$keySymbols{'shift'}}.$lineEnd;
            $nextSymbolExists = 1;
        }
        else
        {
            $lineEnd = ", ".$voidSymbol.$lineEnd
                if ($nextSymbolExists == 1);
        }

        # Direct
        if (!defined($keySymbols{'direct'}) || $keySymbols{'direct'} eq "")
        {
            print STDERR "Unknown symbol: ".$key."{'direct'}\n";
            next;
        }
        if (!defined($symbols{$keySymbols{'direct'}}))
        {
            print STDERR "Unknown symbol: ".$key."{'direct'}: ".$keySymbols{'direct'}."\n";
            next;
        }

        $body .= "\tkey <".$keys{$key}."> { [ ".$symbols{$keySymbols{'direct'}}.$lineEnd;
    }

    return $body;
}

sub gen_x_xmodmap_body()
{
    my $body = "";

    for my $key (@layoutKeys)
    {
        if ($key eq "")
        {
            $body .= "\n";
            next;
        }

        if (!defined($keys{$key}))
        {
            print STDERR "Unknown key: ".$key."\n";
            next;
        }

        my %keySymbols = %{$layoutSyms{$key}};
        my $lineEnd = "\n";
        my $nextSymbolExists = 0;
        my $voidSymbol = "VoidSymbol";

        # AltGr + Shift
        if (defined($keySymbols{'altgr+shift'}) && $keySymbols{'altgr+shift'} ne "")
        {
            if (!defined($symbols{$keySymbols{'altgr+shift'}}))
            {
                print STDERR "Unknown symbol: ".$key."{'altgr+shift'}: ".$keySymbols{'altgr+shift'}."\n";
                next;
            }
            $lineEnd = " ".$symbols{$keySymbols{'altgr+shift'}}.$lineEnd;
            $nextSymbolExists = 1;
        }

        # AltGr
        if (defined($keySymbols{'altgr'}) && $keySymbols{'altgr'} ne "")
        {
            if (!defined($symbols{$keySymbols{'altgr'}}))
            {
                print STDERR "Unknown symbol: ".$key."{'altgr'}: ".$keySymbols{'altgr'}."\n";
                next;
            }
            $lineEnd = " ".$symbols{$keySymbols{'altgr'}}.$lineEnd;
            $nextSymbolExists = 1;
        }
        else
        {
            $lineEnd = " ".$voidSymbol.$lineEnd
                if ($nextSymbolExists == 1);
        }

        # Shift
        if (defined($keySymbols{'shift'}) && $keySymbols{'shift'} ne "")
        {
            if (!defined($symbols{$keySymbols{'shift'}}))
            {
                print STDERR "Unknown symbol: ".$key."{'shift'}: ".$keySymbols{'shift'}."\n";
                next;
            }
            $lineEnd = " ".$symbols{$keySymbols{'shift'}}.$lineEnd;
            $nextSymbolExists = 1;
        }
        else
        {
            $lineEnd = " ".$voidSymbol.$lineEnd
                if ($nextSymbolExists == 1);
        }

        # Direct
        if (!defined($keySymbols{'direct'}) || $keySymbols{'direct'} eq "")
        {
            print STDERR "Unknown symbol: ".$key."{'direct'}\n";
            next;
        }
        if (!defined($symbols{$keySymbols{'direct'}}))
        {
            print STDERR "Unknown symbol: ".$key."{'direct'}: ".$keySymbols{'direct'}."\n";
            next;
        }

        $body .= "keycode ".$keys{$key}." = ".$symbols{$keySymbols{'direct'}}.$lineEnd;
    }

    return $body;
}

sub gen_win_msklc_bodyKeys()
{
    my $body = "";

    for my $key (@layoutKeys)
    {
        if ($key eq "")
        {
            $body .= "\r\n";
            next;
        }

        if (!defined($keys{$key}))
        {
            print STDERR "Unknown key: ".$key."\n";
            next;
        }

        my %keySymbols = %{$layoutSyms{$key}};
        my $line = $scanCodes{$key}."\t".$keys{$key}."\t\t"."1"."\t";
        my $voidSymbol = "-1";

        # Direct
        if (!defined($keySymbols{'direct'}) || $keySymbols{'direct'} eq "")
        {
            print STDERR "Unknown symbol: ".$key."{'direct'}\n";
            next;
        }
        if (!defined($symbols{$keySymbols{'direct'}}))
        {
            print STDERR "Unknown symbol: ".$key."{'direct'}: ".$keySymbols{'direct'}."\n";
            next;
        }

        $line .= $symbols{$keySymbols{'direct'}}."\t";

        # Shift
        if (defined($keySymbols{'shift'}) && $keySymbols{'shift'} ne "")
        {
            if (!defined($symbols{$keySymbols{'shift'}}))
            {
                print STDERR "Unknown symbol: ".$key."{'shift'}: ".$keySymbols{'shift'}."\n";
                next;
            }
            $line .= $symbols{$keySymbols{'shift'}}."\t";
        }
        else
        {
            $line .= $voidSymbol."\t";
        }

        # Ctrl
        $line .= $voidSymbol."\t";

        # AltGr
        if (defined($keySymbols{'altgr'}) && $keySymbols{'altgr'} ne "")
        {
            if (!defined($symbols{$keySymbols{'altgr'}}))
            {
                print STDERR "Unknown symbol: ".$key."{'altgr'}: ".$keySymbols{'altgr'}."\n";
                next;
            }
            $line .= $symbols{$keySymbols{'altgr'}}."\t";
        }
        else
        {
            $line .= $voidSymbol."\t";
        }

        # AltGr + Shift
        if (defined($keySymbols{'altgr+shift'}) && $keySymbols{'altgr+shift'} ne "")
        {
            if (!defined($symbols{$keySymbols{'altgr+shift'}}))
            {
                print STDERR "Unknown symbol: ".$key."{'altgr+shift'}: ".$keySymbols{'altgr+shift'}."\n";
                next;
            }
            $line .= $symbols{$keySymbols{'altgr+shift'}};
        }
        else
        {
            $line .= $voidSymbol."\t";
        }

        $body .= $line."\r\n";
    }

    return $body;
}

sub gen_win_msklc_bodyDeadKeys()
{
    my $body = "";
    my $previousDeadKey = "";

    for my $key (@deadKeysA)
    {
        if ($key eq "")
        {
            $body .= "\r\n";
            next;
        }

        my @keyCombo = @{$key};
        my $result = $deadKeysH{$key};
        my $comboSize = $#keyCombo + 1;

        next if ($comboSize > 2); # Not supported by MSKLC

        my $deadKey = $keyCombo[0];
        my $key     = $keyCombo[1];

        if (!defined($deadKey) || $deadKey eq "")
        {
            print STDERR "Unknown deadkey\n";
            next;
        }

        if (!defined($symbols{$deadKey}) || $symbols{$deadKey} eq "")
        {
            print STDERR "Unknown deadkey: ".$deadKey."\n";
            next;
        }

        if (!defined($key) || $key eq "")
        {
            print STDERR "Unknown key\n";
            next;
        }

        if (!defined($symbols{$key}) || $symbols{$key} eq "")
        {
            print STDERR "Unknown key: ".$key."\n";
            next;
        }

        if (!defined($result) || $result eq "")
        {
            print STDERR "Unknown result symbol\n";
            next;
        }

        if (!defined($symbols{$result}) || $symbols{$result} eq "")
        {
            print STDERR "Unknown result symbol: ".$result."\n";
            next;
        }

        if ($deadKey ne $previousDeadKey)
        {
            $body .= "DEADKEY\t".$unicodes{$deadKey}."\r\n".
                     "\r\n";
            $previousDeadKey = $deadKey;
        }

        $body .= $unicodes{$key}."\t".$unicodes{$result}."\r\n";
    }

    return $body;
}

sub gen_x_xkb_footer()
{
    my $footer = "\tinclude \"level3(ralt_switch)\"\n".
                 "};\n";

    return $footer;
}

sub gen_x_xmodmap_footer()
{
    my $footer = "keycode 0x32 = Shift_L\n".
                 "keycode 0x3E = Shift_R\n".
                 "\n".
                 "keycode 0x25 = Control_L\n".
                 "keycode 0x73 = Super_L\n".
                 "keycode 0x40 = Alt_L           Meta_L\n".
#                 "keycode 0x41 = space           nobreakspace\n".
                 "keycode 0x71 = Mode_switch     Meta_R\n".
                 "keycode 0x74 = Super_R\n".
#                 "keycode 0x75 = Menu\n".
                 "keycode 0x75 = Super_R\n".
                 "keycode 0x6D = Control_R\n".
                 "\n".
                 "add  shift   = Shift_L          Shift_R\n".
                 "add  lock    = Caps_Lock\n".
                 "add  control = Control_L        Control_R\n".
                 "add  mod1    = Alt_L\n".
                 "add  mod2    = Num_Lock\n".
                 "add  mod4    = Super_L          Super_R\n".
                 "add  mod5    = ISO_Level3_Shift\n";

    return $footer;
}

sub gen_win_msklc_footer()
{
    my $footer = "KEYNAME\r\n".
                 "\r\n".
                 "01\tEsc\r\n".
                 "0e\tBackspace\r\n".
                 "0f\tTab\r\n".
                 "1c\tEnter\r\n".
                 "1d\tCtrl\r\n".
                 "2a\tShift\r\n".
                 "36\t\"Right Shift\"\r\n".
                 "37\t\"Num *\"\r\n".
                 "38\tAlt\r\n".
                 "39\tSpace\r\n".
                 "3a\t\"Caps Lock\"\r\n".
                 "3b\tF1\r\n".
                 "3c\tF2\r\n".
                 "3d\tF3\r\n".
                 "3e\tF4\r\n".
                 "3f\tF5\r\n".
                 "40\tF6\r\n".
                 "41\tF7\r\n".
                 "42\tF8\r\n".
                 "43\tF9\r\n".
                 "44\tF10\r\n".
                 "45\tPause\r\n".
                 "46\t\"Scroll Lock\"\r\n".
                 "47\t\"Num 7\"\r\n".
                 "48\t\"Num 8\"\r\n".
                 "49\t\"Num 9\"\r\n".
                 "4a\t\"Num -\"\r\n".
                 "4b\t\"Num 4\"\r\n".
                 "4c\t\"Num 5\"\r\n".
                 "4d\t\"Num 6\"\r\n".
                 "4e\t\"Num +\"\r\n".
                 "4f\t\"Num 1\"\r\n".
                 "50\t\"Num 2\"\r\n".
                 "51\t\"Num 3\"\r\n".
                 "52\t\"Num 0\"\r\n".
                 "53\t\"Num Del\"\r\n".
                 "54\t\"Sys Req\"\r\n".
                 "57\tF11\r\n".
                 "58\tF12\r\n".
                 "7c\tF13\r\n".
                 "7d\tF14\r\n".
                 "7e\tF15\r\n".
                 "7f\tF16\r\n".
                 "80\tF17\r\n".
                 "81\tF18\r\n".
                 "82\tF19\r\n".
                 "83\tF20\r\n".
                 "84\tF21\r\n".
                 "85\tF22\r\n".
                 "86\tF23\r\n".
                 "87\tF24\r\n".
                 "\r\n".
                 "KEYNAME_EXT\r\n".
                 "\r\n".
                 "1c\t\"Num Enter\"\r\n".
                 "1d\t\"Right Ctrl\"\r\n".
                 "35\t\"Num /\"\r\n".
                 "37\t\"Prnt Scrn\"\r\n".
                 "38\t\"Right Alt\"\r\n".
                 "45\t\"Num Lock\"\r\n".
                 "46\tBreak\r\n".
                 "47\tHome\r\n".
                 "48\tUp\r\n".
                 "49\t\"Page Up\"\r\n".
                 "4b\tLeft\r\n".
                 "4d\tRight\r\n".
                 "4f\tEnd\r\n".
                 "50\tDown\r\n".
                 "51\t\"Page Down\"\r\n".
                 "52\tInsert\r\n".
                 "53\tDelete\r\n".
                 "54\t<00>\r\n".
                 "56\tHelp\r\n".
                 "5b\t\"Left Windows\"\r\n".
                 "5c\t\"Right Windows\"\r\n".
                 "5d\tApplication\r\n".
                 "\r\n".
                 "KEYNAME_DEAD\r\n".
                 "\r\n".
                 "00b4\t\"ACUTE ACCENT\"\r\n".
                 "0060\t\"GRAVE ACCENT\"\r\n".
                 "005e\t\"CIRCUMFLEX ACCENT\"\r\n".
                 "02c7\t\"CARON (Mandarin Chinese third tone)\"\r\n".
                 "002f\t\"SOLIDUS\"\r\n".
                 "02db\t\"OGONEK\"\r\n".
                 "02d8\t\"BREVE\"\r\n".
                 "00a8\t\"DIAERESIS\"\r\n".
                 "02d9\t\"DOT ABOVE (Mandarin Chinese light tone)\"\r\n".
                 "00a4\t\"CURRENCY SIGN\"\r\n".
                 "00af\t\"MACRON\"\r\n".
                 "00b8\t\"CEDILLA\"\r\n".
                 "007e\t\"TILDE\"\r\n".
                 "02da\t\"RING ABOVE\"\r\n".
                 "\r\n".
                 "\r\n".
                 "DESCRIPTIONS\r\n".
                 "\r\n".
                 "0409\tFrançais (fr-dvorak-bépo v0.6.5.1)\r\n".
                 "\r\n".
                 "LANGUAGENAMES\r\n".
                 "\r\n".
                 "0409\tFrench (France)\r\n".
                 "\r\n".
                 "ENDKBD\r\n";

    return $footer;
}

sub gen_x_xkb()
{
    loadKeys   ($x_xkb_column);
    loadSymbols($x_xkb_column);
    loadLayout();
    loadDeadKeys();

    my $header = gen_x_xkb_header();
    my $body   = gen_x_xkb_body();
    my $footer = gen_x_xkb_footer();

    print $header.$body.$footer;
}

sub gen_x_xmodmap()
{
    loadKeys   ($x_xmodmap_column);
    loadSymbols($x_xmodmap_column);
    loadLayout();
    loadDeadKeys();

    my $header = gen_x_xmodmap_header();
    my $body   = gen_x_xmodmap_body();
    my $footer = gen_x_xmodmap_footer();

    print $header.$body.$footer;
}

sub gen_win_msklc()
{
    loadKeys   ($win_msklc_column);
    loadSymbols($win_msklc_column);
    loadLayout();
    loadDeadKeys();

    my $header       = gen_win_msklc_header();
    my $bodyKeys     = gen_win_msklc_bodyKeys();
    my $bodyDeadKeys = gen_win_msklc_bodyDeadKeys();
    my $footer       = gen_win_msklc_footer();

    print $header.$bodyKeys.$bodyDeadKeys.$footer;
}

SWITCH: for ($OUTPUT_FORMAT)
{
    /x_xkb/i     && do { gen_x_xkb();     last; };
    /x_xmodmap/i && do { gen_x_xmodmap(); last; };
    /win_msklc/i && do { gen_win_msklc(); last; };
    die("output format must be one of the following: x_xkb, x_xmodmap, win_msklc\n");
}

