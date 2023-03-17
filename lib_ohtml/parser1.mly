%{%}

%token TAG_OPEN "<"
%token <string> TAG_NAME
%token TAG_CLOSE ">"
%token TAG_SLASH_CLOSE "/>"
%token TAG_OPEN_SLASH "</"
%token TAG_EQUALS "="
%token <string> CODE_BLOCK
%token <string> ATTR_VAL
%token <string> ATTR_VAL_CODE
%token <string> CODE_ATTR
%token EOF


%start <Node2.element> doc

%%

doc :
  root = element { root }

element :
  | TAG_OPEN tag_name=TAG_NAME attributes=attribute* TAG_CLOSE
    children=element* 
    TAG_OPEN_SLASH TAG_NAME TAG_CLOSE 
    { Node2.element ~attributes ~children tag_name } 

  | TAG_OPEN tag_name=TAG_NAME attributes=attribute* TAG_SLASH_CLOSE 
    { Node2.element ~attributes tag_name }

  | code_block=CODE_BLOCK { Node2.Code_block code_block }

attribute :
  | code_block = CODE_BLOCK { Node2.Code_attribute code_block }
  | name=TAG_NAME { Node2.Bool_attribute name }
  | name=TAG_NAME TAG_EQUALS attr_val=ATTR_VAL { Node2.Name_val_attribute (name, attr_val) }
  | name=TAG_NAME TAG_EQUALS attr_val=ATTR_VAL_CODE { Node2.Name_code_val_attribute (name, attr_val) }
