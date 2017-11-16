
/*
 * CS-252
 * shell.y: parser for shell
 *
 * This parser compiles the following grammar:
 *
 *	cmd [arg]* [> filename]
 *
 * you must extend it to understand the complete shell grammar
 *
 */

%code requires 
{
#include <string>

#if __cplusplus > 199711L
#define register      // Deprecated in C++11 so remove the keyword
#endif
}

%union
{
  char        *string_val;
  // Example of using a c++ type in yacc
  std::string *cpp_string;
}

%token <string_val> WORD 
%token <string_val> QUOTES 
%token NOTOKEN GREAT NEWLINE LESS GREATGREAT AMPERSAND PIPE ERRR
%token GREATAMPERSAND GREATGREATAMPERSAND

%{
//#define yylex yylex
#include <cstdio>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

#include <sys/types.h>
#include <pwd.h>

#include "command.hh"

void yyerror(const char * s);
int yylex();

char * envExpand(char * arg); 
char * tildeExpand(char * arg);

%}

%%

goal:
  command_list
  ;

/*all of the commands*/
command_list:
  command_line
  | command_list command_line
  ;

/*a complete single command*/
command_line:	
  pipe_list io_modifier_list background  NEWLINE {
    /*printf("   Yacc: Execute command\n"); */
    Command::_currentCommand.execute();
  }
  | NEWLINE 
  | error NEWLINE { yyerrok; }
  ;

/*combines the command with the list of arguments after it*/
command_and_args:
  command_word argument_list {
    Command::_currentCommand.insertSimpleCommand( Command::_currentSimpleCommand );
  }
  ;


/*list of all argument words*/
argument_list:
  argument_list argument
  | /* if the list is empty */
  ;

/*just the argument word*/
argument:
  WORD {
    /*printf("   Yacc: insert argument \"%s\"\n", $1);*/
     
    /*tilde expansion*/
    char * check = tildeExpand($1);
    if (check != NULL) {
      $1 = strdup(check);
      /*Command::_currentSimpleCommand->insertArgument( blank );*/
    }
    else {
      /*Command::_currentSimpleCommand->insertArgument( $1 );*/
    }
    

    /*enviornment expansion*/
    check = envExpand($1);
    if (check != NULL) {
      /*char * blank = strdup(check);
      Command::_currentSimpleCommand->insertArgument( blank );*/
      $1 = strdup(check);
      Command::_currentSimpleCommand->insertArgument( $1 );

    }
    else {
      Command::_currentSimpleCommand->insertArgument( $1 );
    }
    
  }
  | QUOTES {
    memmove($1, $1+1, strlen($1));
    $1[strlen($1)-1] = '\0';
    Command::_currentSimpleCommand->insertArgument($1);
  }
  ;

/*just the command word*/
command_word:
  WORD {
    /*printf("   Yacc: insert command \"%s\"\n", $1);*/
    /*end if exit command*/
    if (!strcmp($1, "exit" )) {
      printf("Cya Later!\n");
      exit(1);
    }
    Command::_currentSimpleCommand = new SimpleCommand();
    Command::_currentSimpleCommand->insertArgument( $1 );
  }
  ;

/*just the modifier*/
io_modifier:
  GREAT WORD {
    /*printf("   Yacc: insert output \"%s\"\n", $2); */
    Command::_currentCommand._outFile = $2;
    Command::_currentCommand._mro++;
  }
  | LESS WORD {
    /*printf("   Yacc: insert input \"%s\"\n", $2); */
    Command::_currentCommand._inFile = $2;
    Command::_currentCommand._mri++;
  }
  | GREATGREAT WORD {
    /*printf("   Yacc: append output \"%s\"\n", $2); */
    Command::_currentCommand._outFile = $2;
    Command::_currentCommand._append = 1;
    Command::_currentCommand._mro++;
  }
  | GREATAMPERSAND WORD {
    /*printf("   Yacc: insert output \"%s\"\n", $2); */
    /*printf("   Yacc: insert stdrr \"%s\"\n", $2); */
    Command::_currentCommand._outFile = $2;
    Command::_currentCommand._errFile = $2;
    Command::_currentCommand._mro++;
    Command::_currentCommand._mre++;
  }
  | GREATGREATAMPERSAND WORD {
    /*printf("   Yacc: append output \"%s\"\n", $2); */
    /*printf("   Yacc: append stdrr \"%s\"\n", $2); */
    Command::_currentCommand._outFile = $2;
    Command::_currentCommand._errFile = $2;
    Command::_currentCommand._append = 1;
    Command::_currentCommand._mro++;
    Command::_currentCommand._mre++;
  }
  | ERRR WORD {
    /*printf("   Yacc: insert stdrr \"%s\"\n", $2) */;
    Command::_currentCommand._errFile = $2;
    Command::_currentCommand._mre++;
  }
  ;

/*list of all of the modifiers*/
io_modifier_list:
  io_modifier_list io_modifier
  | /*if the list is empty*/
  ;

/*combines all of the command_and_args with pipes*/
pipe_list:
  pipe_list PIPE command_and_args
  | command_and_args
  ;

/*just the ampersand symbol, tells the program to run in the background*/
background:
  AMPERSAND {
    /*printf("   Yacc: perform in background \n");*/
    Command::_currentCommand._background = 1;
  }
  | /*can be empty*/
  ;




%%

char * envExpand(char * arg) {
  /*
  -loop through arg until reaches the end
  -check for $ and { and } and save locations
  -save the part from before the $
  -save the part after }
  -create expansion
  -cat the expansion and cat the end of the string
  -replace arg with new string
  -start over from the beginning of the string to look for more expands
  */
  
  char * expanded = (char*)malloc(sizeof(char) * 512); /*store the new string*/
  char * temp = strdup(arg); /*use to index throguh arg*/
  int actually = 0; /*keep track of if you actually expanded*/
  int i = 0; /*keep track of place in string*/
  int length = strlen(arg) - 1; /*how much u loop for*/
  int last = 0; /*where the last env was at so  know where to substring off of*/


  while (i <= length) {
    
    /*expand if ${ */
    if (temp[i] == '$' && temp[i + 1] == '{') {
      /*only get the before characters if there are any*/
      if ((i - last) > 0) {
        char * before = (char*)malloc(sizeof(char) * 20); 
        strncpy(before, temp + last, i - last);
        
        /*copy if first, append if not*/
        if (expanded[0] == '\0') {
          strcpy(expanded,  before);
        }
        else {
          strcat(expanded, before);
        }
        free(before);
      }

      /*figure out where the end bracket is*/
      int j = i;
      char end = temp[j];
      while (end != '}') {
        j++;
        end = temp[j];
      }
      last = j + 1;

      /*get the enviornment variable*/
      char * env = (char*)malloc(sizeof(char) * 20); 
      strncpy(env, temp + i + 2, j - i - 2);
      char * variable;
      
      /*pid of shell*/
      if (strcmp(env, "$") == 0) {
        variable = (char*)malloc(sizeof(char) * 5); 
        sprintf(variable, "%d", getpid());
      }
      /*return code fo the last executed command*/
      else if (strcmp(env, "?") == 0) {
        variable = "?";
      }
      /*pid of the last process run in the background*/
      else if (strcmp(env, "!") == 0) {
        /*variable = (char*)malloc(sizeof(char) * 5); 
        sprintf(variable, "%d", lastBackPid);*/
        variable = "!";
      }
      /*last argument in the previous command*/
      else if (strcmp(env, "_") == 0) {
        variable = "_";
      }
      /*path to shell executable*/
      else if (strcmp(env, "SHELL") == 0) {
        variable = "/homes/escherre/cs252/lab3-src";
      }
      else {
        variable = getenv(env);
      }

      free(env);
      
      /*copy if first, append if not*/
      if (expanded[0] == '\0') {
        strcpy(expanded,  variable);
      }
      else {
         strcat(expanded, variable);
      }

      actually++;
      i = j; /*move to after expansion*/
    }

    
    i++;
  }

  /*if there was nothing to expand*/
  if (actually == 0) {
    return NULL;
  }

  /*append the last part of the string if its not at the end*/
  if (temp[last] != '\0') {
    char * end;
    strncpy(end, temp + last, length - last + 1);
    strcat(expanded, end);  
  }

  if (actually == 0) {
    return NULL;
  }
  char * real = strdup(expanded);
  /*free(expanded);*/
  
  return real;
}

char * tildeExpand(char * arg) {

  int actually = 0;
  char * expanded = (char*)malloc(sizeof(char) * 30);
  char * end1 = (char*)malloc(sizeof(char) * 25);
  
  /*if just a ~*/
  if (strcmp(arg, "~") == 0) {
    expanded = strdup(getenv("HOME"));
    return expanded;
  }

  char * full = (char*)malloc(sizeof(char) * 60);
  /*if just ~/...*/
  if (arg[0] == '~'  && arg[1] == '/') {
    
    int length = strlen(arg);

    expanded = strdup(getenv("HOME"));
    strcpy(full, expanded);

    char * end = (char*)malloc(sizeof(char) * 25);
    end =  arg + 1;
    strcat(full, end);

    return full;
  }
  /*if ~USER/... */
  else if (arg[0] == '~') { 
    
    int i = 0;
    int length = strlen(arg);

    int start;
    int nothing = 0;


    /*find where the first / is*/
    while (i < length) {
      if (arg[i] == '/') {
        start = i;
        break;
      }
      i++;
    }
    if (i == length) {
      start = i - 1;
      nothing = -1;
    }
    
    char * boi = (char*)malloc(sizeof(char) * 100);
    
    if (nothing == 0) {
      char * username = (char*)malloc(sizeof(char) * 10);
      strncpy(username, arg + 1, start - 1);

      
      expanded = strdup(getpwnam(username)->pw_dir);
      strcpy(boi, expanded);

      /*char * end1 = (char*)malloc(sizeof(char) * 25);*/
      end1 = arg + start;

      strcat(boi, end1);
      
      return boi;
    }
    /*if there is no end to cat*/
    else {
      char * username = arg + 1;

      expanded = strdup(getpwnam(username)->pw_dir);
      strcpy(full, expanded);
    
      return full;
    }

  }
  

  if (actually == 0) {
    return NULL;
  }

}

void yyerror(const char * s)
{
  fprintf(stderr,"%s", s);
}

#if 0
main()
{
  yyparse();
}
#endif
