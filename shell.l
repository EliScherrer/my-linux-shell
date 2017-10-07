
/*
 *
 * CS-252 Fall 2017
 * shell.l: lexical analyzer for shell
 * You have to extend it.
 *
 */

%{

#include <cstring>
#include "y.tab.hh"

static  void yyunput (int c,char *buf_ptr  );

void myunputc(int c) {
  unput(c);
}

/*

[`][^ \t\n]*[`] {
  return BACKTICKS
}
*/


%}

%%

\n {
  return NEWLINE;
}

["][^\t\n]*["] {
  yylval.string_val = strdup(yytext);
  return QUOTES;
}

[ \t] {
  /* Discard spaces and tabs */
}

">" {
  return GREAT;
}

"2>" {
  return ERRR;
}

"<" { 
  return LESS; 
}
        
">>" { 
    return GREATGREAT; 
}

">&" { 
    return GREATAMPERSAND; 
}

">>&" { 
    return GREATGREATAMPERSAND; 
} 

"&" { 
    return AMPERSAND; 
}

"|" { 
    return PIPE;
}

[^ \t\n][^ \t\n]*  {
  /* Assume that file names have only alpha chars */
  yylval.string_val = strdup(yytext);
  return WORD;
}



%%



