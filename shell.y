
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
#include "command.hh"

void yyerror(const char * s);
int yylex();

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
    /*printf("   Yacc: insert argument \"%s\"\n", $1); */
    Command::_currentSimpleCommand->insertArgument( $1 );
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


/*


goal:
  commands
  ;

commands:
  command
  | commands command
  ;

command: 
  simple_command
  ;

simple_command:	
  command_and_args iomodifier_opt NEWLINE {
    printf("   Yacc: Execute command\n");
    Command::_currentCommand.execute();
  }
  | NEWLINE 
  | error NEWLINE { yyerrok; }
  ;

command_and_args:
  command_word argument_list {
    Command::_currentCommand.
    insertSimpleCommand( Command::_currentSimpleCommand );
  }
  ;

argument_list:
  argument_list argument
  |  can be empty 
  ;

argument:
  WORD {
    printf("   Yacc: insert argument \"%s\"\n", $1);
    Command::_currentSimpleCommand->insertArgument( $1 );\
  }
  ;

command_word:
  WORD {
    printf("   Yacc: insert command \"%s\"\n", $1);
    Command::_currentSimpleCommand = new SimpleCommand();
    Command::_currentSimpleCommand->insertArgument( $1 );
  }
  ;

iomodifier_opt:
  GREAT WORD {
    printf("   Yacc: insert output \"%s\"\n", $2);
    Command::_currentCommand._outFile = $2;
  }
  |  can be empty 
  ;

*/


%%

void
yyerror(const char * s)
{
  fprintf(stderr,"%s", s);
}

#if 0
main()
{
  yyparse();
}
#endif
