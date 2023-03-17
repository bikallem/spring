%{%}

%token TAG_OPEN "<"
%token <string> TAG_NAME
%token TAG_CLOSE ">"
%token TAG_SLASH_CLOSE "/>"
%token TAG_OPEN_SLASH "</"
%token TAG_EQUALS "="
%token CODE_OPEN "{"
%token <string> CODE_BLOCK
%token CODE_CLOSE "}"
%token <string> ATTR_VAL
%token <string> ATTR_VAL_CODE
%token <string> CODE_ATTR
%token <string> HTML_COMMENT
%token <string> HTML_CONDITIONAL_COMMENT
%token <string> CDATA
%token <string> DTD
%token <string> HTML_TEXT
%token <string> FUNC
%token EOF


%start <Doc.doc> doc

%%

doc :
  | fun_args=FUNC? dtd=DTD? root=html_element { {Doc.dtd; root; fun_args } }

html_element :
  | TAG_OPEN tag_name=TAG_NAME attributes=attribute* TAG_CLOSE
    children=html_content*
    TAG_OPEN_SLASH TAG_NAME TAG_CLOSE 
    { Doc.element ~attributes ~children tag_name } 

  | TAG_OPEN tag_name=TAG_NAME attributes=attribute* TAG_SLASH_CLOSE 
    { Doc.element ~attributes tag_name }

html_content :
  | CODE_OPEN elements=code_element* CODE_CLOSE { Doc.Code elements }
  | comment=html_comment { comment }
  | cdata=CDATA { Doc.Cdata cdata }
  | text=HTML_TEXT { Doc.Html_text text }
  | el=html_element { el }

code_element :
  | code=CODE_BLOCK { Doc.Code_block code }
  | el=html_element { Doc.Code_element el }

html_comment :
  | comment=HTML_COMMENT {Doc.Html_comment comment }
  | comment=HTML_CONDITIONAL_COMMENT {Doc.Html_conditional_comment comment }

attribute :
  | code_block = CODE_ATTR { Doc.Code_attribute code_block }
  | name=TAG_NAME { Doc.Bool_attribute name }
  | name=TAG_NAME TAG_EQUALS attr_val=ATTR_VAL { Doc.Name_val_attribute (name, attr_val) }
  | name=TAG_NAME TAG_EQUALS attr_val=ATTR_VAL_CODE { Doc.Name_code_val_attribute (name, attr_val) }
