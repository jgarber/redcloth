/*
 * redcloth_attributes.rl
 *
 * Copyright (C) 2009 Jason Garber
 */
%%{

  machine redcloth_attributes;
  
  C2_CLAS = ( "(" ( [^)#]+ >A %{ STORE("class_buf"); } )? ("#" [^)]+ >A %{STORE("id_buf");} )? ")" ) ;
  C2_LNGE = ( "[" [^\[\]]+ >A %{ STORE("lang_buf"); } "]" ) ;
  C2_STYL = ( "{" [^}]+ >A %{ STORE("style_buf"); } "}" ) ;
  C2 = ( C2_CLAS | C2_STYL | C2_LNGE )+ ;

  mtext_with_attributes = ( C2 mtext >A %T ) >X ;

  inline := |*

    mtext_with_attributes { SET_ATTRIBUTES(); } ;

  *|;

  link_text_with_attributes = C2 "."* " "* ( mtext+ ) >A %{ STORE("name"); } ;
  link_text_without_attributes = ( mtext+ ) >B %{ STORE_B("name_without_attributes"); } ;

  link_says := |*

    link_text_with_attributes { SET_ATTRIBUTES(); } ;
    link_text_without_attributes { SET_ATTRIBUTE("name_without_attributes", "name"); } ;

  *|;

}%%;
