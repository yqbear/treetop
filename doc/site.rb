require 'rubygems'
require 'erector'
require "#{File.dirname(__FILE__)}/sitegen"

class Layout < Erector::Widget
  def render
    html do
      head do
        link :rel => "stylesheet",
        :type => "text/css",
        :href => "./screen.css"
      end

      body do
        div :id => 'top' do
          div :id => 'main_navigation' do
            main_navigation
          end
        end
        div :id => 'middle' do
          div :id => 'content' do
            content
          end
        end
        div :id => 'bottom' do

        end
      end
    end
  end

  def main_navigation
    ul do
      li { link_to "Documentation", SyntacticRecognition, Documentation }
      li { link_to "Contribute", Contribute }
      li { link_to "Home", Index }
    end
  end

  def content
  end
end

class Index < Layout
  def content
    bluecloth "index.markdown"
  end
end

class Documentation < Layout
  abstract

  def content
    div :id => 'secondary_navigation' do
      ul do
        li { link_to 'Syntax', SyntacticRecognition }
        li { link_to 'Semantics', SemanticInterpretation }
        li { link_to 'Using In Ruby', UsingInRuby }
        li { link_to 'Advanced Techniques', PitfallsAndAdvancedTechniques }
      end
    end

    documentation_content
  end
end

class SyntacticRecognition < Documentation
  def documentation_content
    bluecloth "syntactic_recognition.markdown"
  end
end

class SemanticInterpretation < Documentation
  def documentation_content
    bluecloth "semantic_interpretation.markdown"
  end
end

class UsingInRuby < Documentation
  def documentation_content
    bluecloth "using_in_ruby.markdown"
  end
end

class PitfallsAndAdvancedTechniques < Documentation
  def documentation_content
    bluecloth "pitfalls_and_advanced_techniques.markdown"
  end
end


class Contribute < Layout

end


Layout.generate_site