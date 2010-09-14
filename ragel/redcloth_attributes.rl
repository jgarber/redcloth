/*
 * redcloth_attributes.rl
 *
 * Copyright (C) 2009 Jason Garber
 */
%%{

  machine redcloth_attributes;
  
  C2 = ( C_CLASS_ID | C_STYL | C_LNGE )+ ;

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
