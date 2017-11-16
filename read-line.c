/*
 * CS354: Operating Systems. 
 * Purdue University
 * Example that shows how to read one line with simple editing
 * using raw terminal.
 */

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>

#define MAX_BUFFER_LINE 2048

extern void tty_raw_mode(void);
extern void unset_raw(void);


// Buffer where line is stored
int line_length;
int line_loc;
char line_buffer[MAX_BUFFER_LINE];

//history variables
int history_index = 0;
char ** history = NULL;
int history_length = 0;
int history_limit = 4;

void addHistory(char * newHistory) {
  //readjust size if neccesary
  if (history_length == history_limit + 1) {
    history_limit = history_limit * 2;
    history = (char**)realloc(history, sizeof(char*) * history_limit);
  } 

  //fix
  char * temp = strdup(newHistory);
  temp[strlen(temp)] = '\0';

  //add to history
  history[history_length] = temp;
  history_length++;
  history_index++;

}

void buildHistory() {
  history = (char**)malloc(sizeof(char*) * history_limit);
  char * first = "";
  addHistory(first);
}


// Simple history array
// This history does not change. 
/* Yours have to be updated.
int history_index = 0;
char * history [] = {
  "ls -al | grep x", 
  "ps -e",
  "cat read-line-example.c",
  "vi hello.c",
  "make",
  "ls -al | grep xxx | grep yyy"
};
int history_length = sizeof(history)/sizeof(char *);
*/

void read_line_print_usage()
{
  char * usage = "\n"
    " ctrl-?       Print usage\n"
    " Backspace    Deletes last character\n"
    " up arrow     See last command in the history\n";

  write(1, usage, strlen(usage));
}

/* 
 * Input a line with some basic editing.
 */
char * read_line() {

  // Set terminal in raw mode
  tty_raw_mode();

  line_length = 0;
  line_loc = 0;

  // Read one line until enter is typed
  while (1) {

    if (history == NULL) {
      buildHistory();
    }

    // Read one character in raw mode.
    char ch;
    read(0, &ch, 1);

    if (ch>=32 && ch != 127) {
      // It is a printable character. 


      if (line_loc == line_length) {
        // Do echo
        write(1,&ch,1);

        // If max number of character reached return.
        if (line_length==MAX_BUFFER_LINE-2) break; 

        // add char to buffer.
        line_buffer[line_length]=ch;
        line_length++;
        line_loc++;
      }
      //else inserting midline
      else {
        
        //insert into the buffer
        int i;
        for (i = line_length; i >= line_loc; i--) {
          line_buffer[i + 1] = line_buffer[i];
        }
        line_buffer[line_loc] = ch;
        line_length++;
        
        //write the character in and all the characters after
        for (i = line_loc; i < line_length; i++) {
          write(1, &line_buffer[i], 1);
        }
        line_loc++;
        

        //move curser back
        int distance = line_length - line_loc;
        for (i = 0; i < distance; i++) {  
          ch = 8;
          write(1, &ch, 1);
        }
        

      }
    }
    else if (ch==10) {
      // <Enter> was typed. Return line
      if (line_length > 0) {
        addHistory(line_buffer);
        history_index = history_length;
      }

      // Print newline
      write(1,&ch,1);

      break;
    }
    else if (ch == 31) {
      // ctrl-?
      read_line_print_usage();
      line_buffer[0]=0;
      break;
    }
    else if (ch == 127 || ch == 8) {
      // <backspace> was typed. Remove previous character read.
      if (line_loc > 0) {
        if (line_loc == line_length) {
          // Go back one character
          ch = 8;
          write(1,&ch,1);

          // Write a space to erase the last character read
          ch = ' ';
          write(1,&ch,1);

          // Go back one character
          ch = 8;
          write(1,&ch,1);

          // Remove one character from buffer
          line_length--;
          line_loc--;
        }
        else {
        
          //remove from buffer
          int i;
          for (i = line_loc - 1; i < line_length; i++) {
            line_buffer[i] = line_buffer[i + 1];
          }
          line_length--;
        
          // Go back one character
          ch = 8;
          write(1,&ch,1);

          //write the character in and all the characters after
          for (i = line_loc - 1; i < line_length; i++) {
            write(1, &line_buffer[i], 1);
          }
          line_loc--;
          
          // Write a space to erase the last character
          ch = ' ';
          write(1,&ch,1);
        
          //move curser back
          int distance = line_length - line_loc + 1;
          for (i = 0; i < distance; i++) {  
            ch = 8;
            write(1, &ch, 1);
          }
        

        }
      }
    }
    else if (ch == 4) {
      //delete (ctrl-d) was pressed
          if (line_loc != line_length) {
            if (line_loc == line_length - 1) {
              // Write a space to erase the last character
              ch = ' ';
              write(1,&ch,1);
              
              // Go back one character
              ch = 8;
              write(1,&ch,1);

              // Remove one character from buffer
              line_length--;
            }
            else {
        
              //remove from buffer
              int i;
              for (i = line_loc; i < line_length; i++) {
                line_buffer[i] = line_buffer[i + 1];
              }
              line_length--;
        
              //write the character in and all the characters after
              for (i = line_loc; i < line_length; i++) {
                write(1, &line_buffer[i], 1);
              }
          
              // Write a space to erase the last character
              ch = ' ';
              write(1,&ch,1);
        
              //move curser back
              int distance = line_length - line_loc + 1;
              for (i = 0; i < distance; i++) {  
                ch = 8;
                write(1, &ch, 1);
              }
            }
          }
    }
    else if (ch == 1) {
      //home (ctrl-a) was pressed
      while (line_loc > 0) {    
        ch = 8;
        write(1, &ch, 1);
        line_loc--;
      }
    
    }
    else if (ch == 5) {
      //end (ctrl-e) was pressed
        while (line_loc != line_length) {
          ch = 27;
          write(1, &ch, 1);
          ch = 91;
          write(1, &ch, 1);
          ch = 67;
          write(1, &ch, 1);
          
          line_loc++;
        }
    }
    else if (ch==27) {
      // Escape sequence. Read two chars more
      //
      // HINT: Use the program "keyboard-example" to
      // see the ascii code for the different chars typed.
      //
      char ch1; 
      char ch2;
      read(0, &ch1, 1);
      read(0, &ch2, 1);
      if (ch1==91 && ch2==65) {
	      // Up arrow. Print next line in history.

	      // Erase old line
	      // Print backspaces
	      int i = 0;
	      for (i =0; i < line_length; i++) {
	        ch = 8;
	        write(1,&ch,1);
	      }

	      // Print spaces on top
	      for (i =0; i < line_length; i++) {
	        ch = ' ';
	        write(1,&ch,1);
	      }

	      // Print backspaces
	      for (i =0; i < line_length; i++) {
	        ch = 8;
	        write(1,&ch,1);
	      }	

        if (history_index > 0) {
          history_index--;
        }
        
	      // Copy line from history
	      strcpy(line_buffer, history[history_index]);
	      line_length = strlen(line_buffer);

	      // echo line
	      write(1, line_buffer, line_length);
        line_loc = line_length;
      }
      if (ch1==91 && ch2==66) {
	      // down arrow. Print next line in history.

	      // Erase old line
	      // Print backspaces
	      int i = 0;
	      for (i =0; i < line_length; i++) {
	        ch = 8;
	        write(1,&ch,1);
	      }

	      // Print spaces on top
	      for (i =0; i < line_length; i++) {
	        ch = ' ';
	        write(1,&ch,1);
	      }

	      // Print backspaces
	      for (i =0; i < line_length; i++) {
	        ch = 8;
	        write(1,&ch,1);
	      }	

        if (history_index < history_length) {
          history_index++;
        }
        if (history_index == history_length) {
          history_index--;
        }
        else {
	        // Copy line from history
	        strcpy(line_buffer, history[history_index]);
	        line_length = strlen(line_buffer);

	        // echo line
	        write(1, line_buffer, line_length);
          line_loc = line_length;
        }
      }
      else if (ch1 == 91 && ch2== 68) {
        //left arrow
        if (line_length > 0 && line_loc > 0) {
          ch = 8;
          write(1, &ch, 1);
          line_loc--;
        }
      }
      else if (ch1 == 91 && ch2== 67) {
        //right arrow
        if (line_loc < line_length) {
          ch = 27;
          write(1, &ch, 1);
          ch = 91;
          write(1, &ch, 1);
          ch = 67;
          write(1, &ch, 1);
          
          line_loc++;
        }
      }
      else if (ch1 == 79 && ch2== 72) {
        //home key
        while (line_loc > 0) {    
          ch = 8;
          write(1, &ch, 1);
          line_loc--;
        }
      }
      else if (ch1 == 79 && ch2== 70) {
        //end key
        while (line_loc != line_length) {
          ch = 27;
          write(1, &ch, 1);
          ch = 91;
          write(1, &ch, 1);
          ch = 67;
          write(1, &ch, 1);
          
          line_loc++;
        }
      }
      else if (ch1 == 91 && ch2== 51) {
        char ch3;
        read(0, &ch3, 1);
        if (ch3 == 126) {
          //delete key was pressed
          if (line_loc != line_length) {
            if (line_loc == line_length - 1) {
              // Write a space to erase the last character
              ch = ' ';
              write(1,&ch,1);
              
              // Go back one character
              ch = 8;
              write(1,&ch,1);

              // Remove one character from buffer
              line_length--;
            }
            else {
        
              //remove from buffer
              int i;
              for (i = line_loc; i < line_length; i++) {
                line_buffer[i] = line_buffer[i + 1];
              }
              line_length--;
        
              //write the character in and all the characters after
              for (i = line_loc; i < line_length; i++) {
                write(1, &line_buffer[i], 1);
              }
          
              // Write a space to erase the last character
              ch = ' ';
              write(1,&ch,1);
        
              //move curser back
              int distance = line_length - line_loc + 1;
              for (i = 0; i < distance; i++) {  
                ch = 8;
                write(1, &ch, 1);
              }
            }
          }
        }
      }
      
    }
  }

  // Add eol and null char at the end of string
  line_buffer[line_length]=10;
  line_length++;
  line_buffer[line_length]=0;

  unset_raw();
  return line_buffer;
}

