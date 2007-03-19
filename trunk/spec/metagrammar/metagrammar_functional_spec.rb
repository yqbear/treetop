require 'rubygems'
require 'spec/runner'

dir = File.dirname(__FILE__)
require "#{dir}/../spec_helper"
require "#{dir}/metagrammar_spec_context_helper"

context "A grammar for treetop grammars" do
  include MetagrammarSpecContextHelper
  
  setup do
    @metagrammar = Metagrammar.new
    @parser = @metagrammar.new_parser
  end

  specify "parses a single-quoted string as a TerminalSymbol with the correct prefix value" do
    @metagrammar.root = @metagrammar.nonterminal_symbol(:terminal_symbol)
    terminal = @parser.parse("'foo'").value
    terminal.should_be_an_instance_of TerminalSymbol
    terminal.prefix.should_eql 'foo'
  end
  
  specify "parses a double-quoted string as a TerminalSymbol with the correct prefix value" do
    @metagrammar.root = @metagrammar.nonterminal_symbol(:terminal_symbol)
    terminal = @parser.parse('"foo"').value
    terminal.should_be_an_instance_of TerminalSymbol
    terminal.prefix.should_eql 'foo'
  end
  
  specify "parses a bracketed string as a CharacterClass" do
    @metagrammar.root = @metagrammar.nonterminal_symbol(:character_class)
    char_class = @parser.parse('[A-C123\\]]').value
    char_class.should_be_an_instance_of CharacterClass
    
    parser = mock("parser")
    char_class.parse_at('A', 0, parser).should_be_success
    char_class.parse_at('B', 0, parser).should_be_success
    char_class.parse_at('C', 0, parser).should_be_success
    char_class.parse_at('1', 0, parser).should_be_success
    char_class.parse_at('2', 0, parser).should_be_success
    char_class.parse_at('3', 0, parser).should_be_success
    char_class.parse_at(']', 0, parser).should_be_success    
  end
  
  specify "parses . as an AnythingSymbol" do
    @metagrammar.root = @metagrammar.nonterminal_symbol(:anything_symbol)
    char_class = @parser.parse('.').value
    char_class.should_be_an_instance_of AnythingSymbol
  end
  
  specify "parses an unquoted string as a NonterminalSymbol and installs it in the grammar passed to value on the resulting syntax node" do
    @metagrammar.root = @metagrammar.nonterminal_symbol(:nonterminal_symbol)
    syntax_node = @parser.parse('foo')    

    grammar = Grammar.new
    nonterminal = syntax_node.value(grammar)
    nonterminal.should_be_an_instance_of NonterminalSymbol
    nonterminal.name.should_equal :foo
    grammar.nonterminal_symbol(:foo).should_equal(nonterminal)
  end
  
  specify "parses a nonterminal, string terminal, anything character, or character class with the primary parsing rule" do
    @metagrammar.root = @metagrammar.nonterminal_symbol(:primary)
    grammar = Grammar.new

    @parser.parse("'foo'").value(grammar).should_be_an_instance_of TerminalSymbol
    @parser.parse('foo').value(grammar).should_be_an_instance_of NonterminalSymbol
    @parser.parse('.').value(grammar).should_be_an_instance_of AnythingSymbol
    @parser.parse('[abc]').value(grammar).should_be_an_instance_of CharacterClass
  end
  
  specify "parses different types of whitespace with the whitespace rule" do
    @metagrammar.root = @metagrammar.nonterminal_symbol(:space)
    grammar = Grammar.new

    @parser.parse(' ').should_be_success
    @parser.parse('    ').should_be_success
    @parser.parse("\t\t").should_be_success
    @parser.parse("\n").should_be_success
  end
  
  specify "does not parse nonwhitespace characters with the whitespace rule" do
    @metagrammar.root = @metagrammar.nonterminal_symbol(:space)
    grammar = Grammar.new
    @parser.parse('g').should_be_failure
    @parser.parse('g ').should_be_failure  
  end
  
  specify "parses a series of space-separated terminals and nonterminals as a sequence" do
    @metagrammar.root = @metagrammar.nonterminal_symbol(:sequence)
    syntax_node = @parser.parse('"terminal" nonterminal1 nonterminal2')

    grammar = Grammar.new
    sequence = syntax_node.value(grammar)
    sequence.should_be_an_instance_of Sequence
    sequence.elements[0].should_be_an_instance_of TerminalSymbol
    sequence.elements[0].prefix.should_eql "terminal"
    sequence.elements[1].should_be_an_instance_of NonterminalSymbol
    sequence.elements[1].name.should_equal :nonterminal1
    sequence.elements[2].should_be_an_instance_of NonterminalSymbol
    sequence.elements[2].name.should_equal :nonterminal2
  end
  
  specify "parses a series of space-separated non-terminals as a sequence" do
    @metagrammar.root = @metagrammar.nonterminal_symbol(:sequence)
    syntax_node = @parser.parse('a b c')

    grammar = Grammar.new
    sequence = syntax_node.value(grammar)
    sequence.should_be_an_instance_of Sequence
  end
  
  specify "parses a * to a node that can modify the semantics of an expression it follows appropriately" do
    @metagrammar.root = @metagrammar.nonterminal_symbol(:suffix)
    result = @parser.parse('*')
    
    parsing_expression = mock('expression preceding the suffix')
    zero_or_more = mock('zero or more of the parsing expression')
    parsing_expression.should_receive(:zero_or_more).and_return(zero_or_more)
    
    result.value(parsing_expression).should == zero_or_more
  end

  specify "parses an expression followed immediately by a + as one or more of that expression" do
    @metagrammar.root = @metagrammar.nonterminal_symbol(:primary)
    
    result = parse_result_for('"b"+')
    result.should be_an_instance_of(OneOrMore)
  end

  specify "parses a + node that can modify the semantics of an expression it follows appropriately" do
    @metagrammar.root = @metagrammar.nonterminal_symbol(:suffix)
    result = @parser.parse('+')
    
    parsing_expression = mock('expression preceding the suffix')
    one_or_more = mock('one or more of the parsing expression')
    parsing_expression.should_receive(:one_or_more).and_return(one_or_more)
    
    result.value(parsing_expression).should == one_or_more
  end

  specify "parses a ? node that can modify the semantics of an expression it follows appropriately" do
    @metagrammar.root = @metagrammar.nonterminal_symbol(:suffix)
    result = @parser.parse('?')
    
    parsing_expression = mock('expression preceding the suffix')
    optional = mock('optional parsing expression')
    parsing_expression.should_receive(:optional).and_return(optional)
    
    result.value(parsing_expression).should == optional
  end

  specify "parses an &-predication as a primary expression" do
    @metagrammar.root = @metagrammar.nonterminal_symbol(:primary)
    result = parse_result_for('&"foo"')
    
    result.should be_instance_of(AndPredicate)
  end

  specify "parses a !-predication as a primary expression" do
    @metagrammar.root = @metagrammar.nonterminal_symbol(:primary)
    result = parse_result_for('!"foo"')
    
    result.should be_instance_of(NotPredicate)
  end
  
  specify "parses a the parses suffixes with higher precedence than prefixes" do
    @metagrammar.root = @metagrammar.nonterminal_symbol(:primary)
    result = parse_result_for('!"foo"+')
    
    result.should be_instance_of(NotPredicate)
    result.expression.should be_instance_of(OneOrMore)
  end
  
  specify "parses an & as a node that can modify the semantics of an expression it precedes appropriately" do
    @metagrammar.root = @metagrammar.nonterminal_symbol(:prefix)
    result = @parser.parse('&')
    
    parsing_expression = mock('expression following the prefix')
    and_predicate = mock('&-predicated parsing expression')
    parsing_expression.should_receive(:and_predicate).and_return(and_predicate)
    
    result.value(parsing_expression).should == and_predicate
  end

  specify "parses an ! as a node that can modify the semantics of an expression it precedes appropriately" do
    @metagrammar.root = @metagrammar.nonterminal_symbol(:prefix)
    result = @parser.parse('!')
    
    parsing_expression = mock('expression following the prefix')
    not_predicate = mock('!-predicated parsing expression')
    parsing_expression.should_receive(:not_predicate).and_return(not_predicate)
    
    result.value(parsing_expression).should == not_predicate
  end
end
