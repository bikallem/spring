%{%}

%token Tag_open "<"
%token <string> Tag_name
%token Tag_close ">"
%token Tag_slash_close "/>"
%token Tag_open_slash "</"
%token Tag_equals "="
%token Code_open "{"
%token <string> Code_block
%token Code_close "}"
%token <string> Attr_val
%token <string> Attr_val_code
%token <string> Code_attr
%token <string> Html_comment
%token <string> Html_conditional_comment
%token <string> Cdata
%token <string> Dtd
%token <string> Html_text
%token <string> Func
%token Eof


%start <Doc.doc> doc

%%

doc :
  | fun_args=Func? dtd=Dtd? root=html_element { {Doc.dtd; root; fun_args } }

html_element :
  | Tag_open tag_name=Tag_name attributes=attribute* Tag_close
    children=html_content*
    Tag_open_slash Tag_name Tag_close 
    { Doc.element ~attributes ~children tag_name } 

  | Tag_open tag_name=Tag_name attributes=attribute* Tag_slash_close 
    { Doc.element ~attributes tag_name }

html_content :
  | Code_open code=code* Code_close { Doc.Code code }
  | comment=html_comment { comment }
  | cdata=Cdata { Doc.Cdata cdata }
  | text=Html_text { Doc.Html_text text }
  | el=html_element { el }

code :
  | code_block=Code_block { Doc.Code_block code_block }
  | el=code_element { el }
  | text=Html_text { Doc.Code_text text }

code_element :
  | Tag_open tag_name=Tag_name attributes=attribute* Tag_close
    children=code*
    Tag_open_slash Tag_name Tag_close
    { Doc.Code_element {tag_name; attributes; children } }
  | Tag_open tag_name=Tag_name attributes=attribute* Tag_slash_close 
    { Doc.Code_element {tag_name; attributes; children = [] } }

html_comment :
  | comment=Html_comment {Doc.Html_comment comment }
  | comment=Html_conditional_comment {Doc.Html_conditional_comment comment }

attribute :
  | code_block = Code_attr { Doc.Code_attribute code_block }
  | name=Tag_name { Doc.Bool_attribute name }
  | name=Tag_name Tag_equals attr_val=Attr_val { Doc.Name_val_attribute (name, attr_val) }
  | name=Tag_name Tag_equals attr_val=Attr_val_code { Doc.Name_code_val_attribute (name, attr_val) }
