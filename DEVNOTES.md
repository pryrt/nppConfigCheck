# 2021-July-17 : INITIAL NOTES

Need a place for taking notes
So I updated script_path to correcectly override the PATH/env-vars to prevent it
from finding notepad++.exe in my path... but that's replicating coverage from
nppcc_dir.t, and is actually testing to outputs that won't be in the final
version of the script; so testing something that isn't there. :-(

What script_path was _supposed_ to be testing was how the -path argument to the
script would affect it; but until I know what the real outputs are of the
script, how can I effectively test the -path option's results (or any other
option, for that matter).

Even worse, while writing this up, I saw that the Action cpanm--test is
no longer passing, even though it was before.  But I don't want to debug that
problem, since it's debugging something I put in that won't be valid in the
future.

I need to figure out what this script is really doing, and what it's output
will be, because without that design, I cannot make a reasonable test with
any expectation that it will work. :-(

# 2021-Jul-27 : XML config file parsing

Quick search of perlmonks shows that XML::Twig or XML::Rules are good ideas;
Haukex seems to like XML::Rules.
```
looking at [haukex] [id://830550|scratchpad] with XML::Rules links
  [id://1232006] => barebones example getting it into consistent structure
  [id://11131501] => examples that change the structure
      raw => [tagname => attrs] pushed into parent tag's _content
      pass => tag's hash dissolved into parent's
          useful if the root-level isn't interesting (like <NotepadPlus>)
      as is => tagname => { ...hash...} gets added to parent object
      as array => [tagname => {...hash...}] gets added to parent object
      by name => <tagname name="blah"> would be added as blah => {...}

  Comparing "raw" vs "as array":
      * similar: order of tags is preserved
      * diff: raw uses _content key containing an arrayref, whereas
              as array uses individual keys for
      * diff: if there are mutiple <example ...> tags,
          raw will have [example=>{...}],[example=>{...}]

  I am leaning to 'as array', because I don't like the extra _content level

want to compare XML::Rules vs XML::Twig to see if I have a preference
  I couldn't immediately see a way to get the simple structure from ::Twig
  that Haukex showed for ::Rules.  I think I'll stick with ::Rules

```
## Example using XML::Rules on contextMenu.xml, getting rid of <NotepadPlus> parent
```
if(1){
    my $parser = XML::Rules->new(
        stripspaces => 3|4,
        rules => [ _default => 'as array', NotepadPlus => 'pass' ],
    );
    dd 'as array => ',
    $parser->parse_file('C:/usr/local/apps/notepad++/contextMenu.xml');
}
```

# 2021-July-28 XML::Rules

see [id://11135437] and replies:
  it looks like I can use `handlers => {}` in XML::Rules->new() to
  define my own handlers for XML Comments and XMLDecl... but as I progressed, I
  couldn't figure out how to add to the the current location in the data structure,
  which is what I was really hoping for; using the same retval as the example rules
  did _not_ work.

  [haukex] says that for roundtripping, I am better off using XML::LibXML . :-(

# 2021-July-28 XML::LibXML

The main perldoc for XML::LibXML points to [Perl XML::LibXML By Example](http://grantm.github.io/perl-libxml-by-example/),
  which might be a tolerable starting point.

After some experimentation, the following snippet will parse the contextMenu, modify **Edit > Copy** to have a comment attribute,
  and add a `<Item MenuEntryName="Edit" MenuItemName="Join Lines" comment="pryrt" />` after the **Edit > Copy**:

```
    my $contextMenu = XML::LibXML->load_xml(no_blanks => 1, location => 'C:/usr/local/apps/notepad++/contextMenu.xml');
    #print "contextMenu:Item = $_" for $contextMenu->findnodes('//Item');
    print "contextMenu:StyleAll = $_" for $contextMenu->findnodes('//Item[@FolderName="Style all occurrences of token"]');

    print "first Copy node: ",
    my ($firstCopy) = $contextMenu->findnodes('//Item[@MenuItemName="Copy"]');
    $firstCopy->setAttribute( comment => "peter's comment");
    print "edited Copy node: ", $firstCopy;
    print "firstCopy's parent: ",
    my $parent = $firstCopy->parentNode;

    my $newElement = XML::LibXML::Element->new('Item');
    $newElement->setAttribute(MenuEntryName=>'Edit');
    $newElement->setAttribute(MenuItemName=>'Join Lines');
    $newElement->setAttribute(comment => 'pryrt');
    print 'creating element: ', $newElement, " -- not yet attached";
    $parent->insertAfter($newElement, $firstCopy);
    print 'found inserted node: ',
    my ($findNewElement) = $contextMenu->findnodes('//Item[@comment="pryrt"]');

    my $str = $contextMenu->toString(1);
    $str =~ s/(^|\G)(  |\t)/    /gm;
    print "final edited parent:\n\n-----\n$str\n=====\n\n";
```
(I included code to make the indentation consistently 4 spaces per tab before printing it out)

# 2021-July-30 : XML structure

Take a brief look at the XML structure, to see what kinds of Nodes and attributes I will need to be comparing...

```
langs(.model).xml
    Languages > Language{name}
    Languages > Language > Keywords{name} (value)
stylers(.model).xml and themes\*.xml
    LexerStyles > LexerType{name}
    LexerStyles > LexerType > WordsStyle (optional value)
shortcuts.xml
    InternalCommands > Shortcut
    Macros > Macro{name} > Action{name}
    UserDefinedCommands > Command{name}
    PluginCommands > PluginCommand
    ScintillaKeys > ScintKey > opt:NextKey
contextMenu.xml
    SctintillaContextMenu > Item{id|MenuItemName|PluginCommandItemName}
config.xml
    FindHistory > attr:*
    ProjectPanels > ProjectPanel{id}
    GUIConfigs > GUIConfig{name}
    GUIConfigs > GUIConfig{DockingManager} > *
autoCompletion\*.xml
    AutoComplete > Environment
    AutoComplete > Keyword{name}
    AutoComplete > Keyword{name} > Overload > Param{name}
localization\*.xml & nativeLang.xml
    NativeLangue > * > *{m/id|name/i}
functionList\overrideMap.xml
    functionList > associationMap > association{LangID|userDefinedLangName}
functionList\*.xml
    functionList > parser > *
```

# 2021-Aug-13 : giving up on run_script

Even after all my fixes, and thinking I solved everything, as soon as I run the main
  script, it's come back.

I had been hoping to use this project as a learning platform for testing scripts as well
  as the libraries underneath, but there appears to be something fundamental that
  I'm missing.  I have decided to just implement as much as I can in the library
  module, where I can test individual functions with full coverage, then just rely on
  my development of the script to make sure it's working right; try to keep it nearly
  all glue.

After deleting all the d# and delme and script-running attempts, I realized that I
  probably should have kept something and moved it to xt\ for doing author tests.
  I suppose if I really want to, I could go through the git history on those commits
  and find their source later.

# 2021-Sep-16 : XML replicate missing attribute

Experiment with a replicate-missing-attribute example

```
#!perl

use 5.012; # strict, //
use warnings;

use XML::LibXML;

sub myindent4 {
    my ($node) = @_;
    my $str = $node->toString(1);
    $str =~ s/(^|\G)(  |\t)/    /gm;
    return $str;
}

{
    # this example searches the source for <Item> nodes
    #   it then looks for an <Item> node in destination that has the same id or name
    #   for each matching dst:<Item>, it looks through the attributes of the src node and makes sure that dst has a similar attribute; if not, it adds it
    # This will make sure that for all of the same Item, it has any new attributes with the default value from the source
    #
    # TODO: if there is no matching node in dst, need to copy the src-node to the destination
    #

    my $src = XML::LibXML->load_xml(string => <<EOSRC);
<top>
    <Item name="unique" first="1" extra="2" />
    <Item id="314159" first="1" extra="2" />
</top>
EOSRC
    my $dst = XML::LibXML->load_xml(string => <<EODST);
<top>
    <Item name="unique" first="one" file="dest" />
    <Item name="differnt" first="last" file="dest" />
    <Item id="271828" first="one" file="dest" />
    <Item id="314159" extra=".ext" file="dest" />
</top>
EODST

    for my $node ( $src->findnodes('//Item') ) {
        printf STDERR "source node found: '%s'\n", $node->toString(0);
        my ($id_attr, $id_val) = $node->hasAttribute('id') ? ('id', $node->getAttribute('id')) : $node->hasAttribute('name') ? ('name', $node->getAttribute('name')) : undef;
        next unless defined $id_val;
        printf STDERR "\t%-40.40s => %s\n", 'name', $id_val;
        for my $dnode ( $dst->findnodes(qq{//Item[\@$id_attr="$id_val"]}) ) {
            printf STDERR "  destination match: '%s'\n", $node->toString(0);
            printf STDERR "  compare to source attributes:\n";
            for my $attr ( $node->attributes ) {
                $attr =~ s/^\s*(.*?)\s*=\s*(.*)/$1/;
                next if $attr eq $id_attr;
                my $val = $node->getAttribute($attr);
                printf STDERR "    looking for '%s' in destination node (src val='%s')...\n", $attr//'<undef>', $val//'<undef>';
                if( $dnode->hasAttribute($attr) ) {
                    printf STDERR "      already has %s=%s\n", $attr, $dnode->getAttribute($attr);
                } else {
                    printf STDERR "      add %s='%s' to destination\n", $attr, $val;
                    $dnode->setAttribute($attr, $val);
                }
            }
        }
        print "\n"x2;
    }

    printf STDERR "\n\n__DESTINATION__\n\n";
    print STDERR myindent4($dst);
    printf STDERR "\n\n__END__\n\n";

}
```

# 2021-Oct-7 : temporarily giving up on github-actions

Turned off github actions, because I could not get XML::LibXML to
install on the github windows-latest environment.

Enabling appveyor with .appveyor.yml to handle ci

# 2021-Oct-7 : idea for getting contents of file

Create a new module, which will do a wrapper that will call either
the Archive::Zip or a roll-you-own, so that I can have the same
interface to get $obj->contents($xmlFileName).  If it's a zipfile,
just use the existing object method; otherwise, use a lookup table
to map the xmlFileName to the appropriate location to find that
file.  That then makes it easy for me to uncomment the
compareConfigFiles() function once it's ready.

DONE: in directory version, map filenames to paths
DONE: move zip-specific missing-files check to after the if-block,
    and make it work on either ZIP or the SRC (source archives
    require all files; destination archives do not) -- so will
    need a new constructor-parameter to determine whether SRC or
    DST.
DONE: increase test coverage of the missing-files-check for SRC directory
TODO: populate the rest of the config-file-defaults
DONE: mergeContents: need to handle values-merging for some of the
    config elements, not just elements and attributes

$ 2021-Oct-11 merging values

completed the mergeContents TODO for values
