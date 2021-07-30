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
    FindHistory > *
    FileBrowser > File
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
