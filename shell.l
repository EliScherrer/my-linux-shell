
/*
 *
 * CS-252 Fall 2017
 * shell.l: lexical analyzer for shell
 * You have to extend it.
 *
 */

%{

#include <cstring>
#include <unistd.h>

#include "y.tab.hh"

static  void yyunput (int c,char *buf_ptr  );
//char * read_line();
extern "C" char * read_line();

void myunputc(int c) {
  unput(c);
}

int mygetc(FILE * f) { 
 
  static char *p;
  char ch;
  
  if (!isatty(0)) {
    printf("wtf");
    return getc(f);
  }

  if (p == NULL || *p == 0) {
    char * s = read_line();
    p = s;
  }

  ch = *p;
  p++;

  return ch;

}

#undef getc
#define getc(f) mygetc(f)


%}

%%

\n {
  return NEWLINE;
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


[`][^`\n]*[`] {
//subshell
  //- whatever is in backticks, run it in a subshell then return and then run the whole thing
  //with it's output
  //- use a regular expression in lex to find backticks
  //- fork a child process and run execvp (proc/self/exec) <- this refrences the current process
  //- pipe the command inside backticks from the parent to the subshell
    //- use write command to write into fdpipe[1]
    //- change the stdin for the subshell -> dup(fdpipe[0], 0)
    //- also send a new line and the exit command so that after it finishes it exits
  //- create a new pipe to pipe back the result from subshell to parent
    //- change the stdout for the subshell -> dub(fdpipe[1], 1)
    //- use read command to read from the reading end of the pipe
    //- (unsure about this) how does the parent know when its done reading from the pipe? some sort of line terminator?
  //- insert the output back in as an argument

  
  //take off backticks
  char * subin = strdup(yytext + 1);
  subin[strlen(subin) - 1] = '\0';

  //save default in and out so you can restore at the end
  int defaultin = dup(0);
  int defaultout = dup(1);

  //create pipes for start and end
  int startPipe[2];
  int endPipe[2];
  pipe(startPipe);
  pipe(endPipe);

  //write the command to the write end of the start pipe
  write(startPipe[1], subin, strlen(subin));
  //also write \n exit \n so that the subshell exits after finishing
  write(startPipe[1], "\nexit\n", 6); 

  //redirect the subshell input to be the read end of the start pipe... and close
  dup2(startPipe[0], 0);
  close(startPipe[0]);
  close(startPipe[1]);

  //redirect the subshell output to be the write end of the end pipe... and close
  dup2(endPipe[1], 1);
  close(endPipe[1]);
  //close(endPipe[0]);

  //fork and call execvp on proc/self/exec
  int pid = fork();
  if (pid == -1) {
    perror ("fork fail");
    exit(2);
  }
  if (pid == 0) {
    execvp("/proc/self/exe", NULL);
    //execvp("/bin/bash", NULL);
    perror("exec fail");
    exit(2);
  }

  //restore default in and out  
  dup2(defaultin, 0);
  dup2(defaultout, 1);
  close(defaultin);
  close(defaultout);
  
  int outSize = (sizeof(char) * 100);
  int currSize = 0;
  char * subout = (char*)malloc(outSize); //store all the read in characters
  char temp; //temporarily store each read in character
  int end; //return from read, if its not > 0 then reading is done
  int i = 0; //index, also number of characters read in

  end = read(endPipe[0], &temp, sizeof(char));
  while (end > 0) {
    if (currSize + sizeof(temp) >= outSize) {
      outSize = outSize * 2;
      realloc(subout, outSize);
    }
    if (temp == '\n') {
      subout[i] = ' ';
      i++;
    }
    else {
      subout[i] = temp;
      i++;
    }
    end = read(endPipe[0], &temp, sizeof(char));
  }
  subout[i] = '\0';

  int j;
  for (j = i; j > -1; j--) {
    unput(subout[j]);
  }
  free(subout);

}

["][^\t\n]*["] {
  yylval.string_val = strdup(yytext);
  return QUOTES;
}

[^ \t\n<>|]*[\\].[^ \t\n<>|]*  {
  /*ignore characters after \, not sure if this will capture multiple in one*/
  /*go through the yytext and add each character to realWord, ignoring \'s */
  char * realWord = (char *)malloc (strlen(yytext)* sizeof(char));
  int loc = 0;
  int i = 0;
  
  for (i = 0; i < strlen(yytext); i++) {
    if (yytext[i] == '\\') {
      i++;
      realWord[loc] = yytext[i];
      loc++;
    }
    else {
      realWord[loc] = yytext[i];
      loc++;
    }
  }
  
  yylval.string_val = strdup(realWord);
  return WORD;
}

[^ \t\n<>|&][^ \t\n<>|&]*  {
  /* Assume that file names have only alpha chars */
  yylval.string_val = strdup(yytext);
  return WORD;
}



%%


