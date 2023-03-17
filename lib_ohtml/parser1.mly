%{%}

%token START_ELEM "<"
%token <string> TAG_NAME
%token ELEM_CLOSE ">"
%token START_ELEM_SLASH_CLOSE "/>"
%token END_ELEM_START "</"
%token <string> CODE_BLOCK
%token <string> ATTR_VAL
%token <string> ATTR_VAL_CODE
%token <string> CODE_ATTR
%token EQUAL "="
%token EOF


%start <Node2.element> doc

%%

doc :
  root = element { root }

element :
  | START_ELEM tag_name=TAG_NAME 
    attributes=attribute*
    ELEM_CLOSE 
    children=element* 
    END_ELEM_START TAG_NAME ELEM_CLOSE 
    { Node2.element ~attributes ~children tag_name } 

  | START_ELEM tag_name=TAG_NAME
    attributes=attribute*    
    START_ELEM_SLASH_CLOSE 
    { Node2.element ~attributes tag_name }

  | code_block=CODE_BLOCK { Node2.Code_block code_block }

attribute :
  | code_block = CODE_BLOCK { Node2.Code_attribute code_block }
  | name=TAG_NAME { Node2.Bool_attribute name }
  | name=TAG_NAME EQUAL attr_val=ATTR_VAL { Node2.Name_val_attribute (name, attr_val) }
  | name=TAG_NAME EQUAL attr_val=ATTR_VAL_CODE { Node2.Name_code_val_attribute (name, attr_val) }
