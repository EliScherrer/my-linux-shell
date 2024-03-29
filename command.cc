/*
 * CS252: Shell project
 *
 * Template file.
 * You will need to add more code here to execute the command table.
 *
 * NOTE: You are responsible for fixing any bugs this code may have!
 *
 */

#include <cstdio>
#include <cstdlib>
#include <cstring>

#include <unistd.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <signal.h>

#include <fcntl.h>

#include "command.hh"


//command constructor
Command::Command()
{
	// Create available space for one simple command
	_numOfAvailableSimpleCommands = 1;
	_simpleCommands = (SimpleCommand **)
		malloc( _numOfSimpleCommands * sizeof( SimpleCommand * ) );

	_numOfSimpleCommands = 0;
	_outFile = 0;
	_inFile = 0;
	_errFile = 0;
	_background = 0;
  _append = 0;
  _mro = 0;
  _mri = 0;
  _mre = 0;

}

//add a command to the _simpleCommands data structure
void Command::insertSimpleCommand( SimpleCommand * simpleCommand ) {
	// allocate more space if the array of simpleCommands is full
    if ( _numOfAvailableSimpleCommands == _numOfSimpleCommands ) {
		_numOfAvailableSimpleCommands *= 2;
		_simpleCommands = (SimpleCommand **) realloc( _simpleCommands,
			 _numOfAvailableSimpleCommands * sizeof( SimpleCommand * ) );
	}
	
    //append the new command to the end of the array
	_simpleCommands[ _numOfSimpleCommands ] = simpleCommand;
	_numOfSimpleCommands++;
}

//clear all of the allocated memory
void Command:: clear() {
    //free all the memory inside the _simpleCommands array
    //for the length of the array
	for ( int i = 0; i < _numOfSimpleCommands; i++ ) {
        //for the number of arguments in the given command
		for ( int j = 0; j < _simpleCommands[ i ]->_numOfArguments; j ++ ) {
			free ( _simpleCommands[ i ]->_arguments[ j ] );
		}
		
		free ( _simpleCommands[ i ]->_arguments );
		free ( _simpleCommands[ i ] );
	}

	if ( _inFile ) {
		free( _inFile );
	}

  //if infile and errfile are equal only free once
  if (_errFile && _outFile) {
    if (strcmp(_outFile, _errFile) == 0) {
	    if ( _outFile ) {
		    free( _outFile );
	    }
      else if (_errFile ) {
		    free( _errFile );
	    }
    }
  }
  else {
	  if ( _outFile ) {
		  free( _inFile );
	  }
	  if (_errFile ) {
		  free( _errFile );
	  }
  }

	_numOfSimpleCommands = 0;
	_outFile = 0;
	_inFile = 0;
	_errFile = 0;
	_background = 0;
}

//print out the command table
void Command::print() {
	printf("\n\n");
	printf("              COMMAND TABLE                \n");
	printf("\n");
	printf("  #   Simple Commands\n");
	printf("  --- ----------------------------------------------------------\n");
	
	for ( int i = 0; i < _numOfSimpleCommands; i++ ) {
		printf("  %-3d ", i );
		for ( int j = 0; j < _simpleCommands[i]->_numOfArguments; j++ ) {
			printf("\"%s\" \t", _simpleCommands[i]->_arguments[ j ] );
		}
	}

	printf( "\n\n" );
	printf( "  Output       Input        Error        Background\n" );
	printf( "  ------------ ------------ ------------ ------------\n" );
	printf( "  %-12s %-12s %-12s %-12s\n", _outFile?_outFile:"default",
		_inFile?_inFile:"default", _errFile?_errFile:"default",
		_background?"YES":"NO");
	printf( "\n\n" );
	
}

/*
-env variable expression
   -do that shit in lex (or maybe yacc?)
   -$? keep track of error codes in your code
-wildcarding
  -do that sit in yacc
-history
  -store it in a file
-variable prompt
  -shellrc needs to be working for this

*/
//do the actual work for a command
void Command::execute() {


  // Don't do anything if there are no simple commands
	if ( _numOfSimpleCommands == 0 ) {
		prompt();
		return;
	}

	// Print contents of Command data structure
	//print();


	// Execute Command now...

  //check for multiple redirects and exit if there are
  if (_mro > 1) {
    printf("Ambiguous output redirect\n");
    exit(1);
  }
  else {
   // _mro = 0;
  }
  if (_mri > 1) {
    printf("Ambiguous input redirect\n");
    exit(1);
  }
  else {
    //_mri = 0;
  }
  if (_mre > 1) {
    printf("Ambiguous error redirect\n");
    exit(1);
  }
  else {
    //_mre = 0;
  }


  //save default in, out, error because u have to restore them at the end
  int defaultin = dup(0);
  int defaultout = dup(1);
  int defaulterr = dup(2);

  //set error
  int fderr;
  if (_errFile) {
    if (_append == 0) {
      fderr = open(_errFile, O_CREAT | O_WRONLY, 0666);
    }
    else if (_append == 1) {
      fderr = open(_errFile, O_APPEND | O_WRONLY, 0666);
    }
  }
  else {
    fderr = dup(defaulterr);
  }

  //redirect error from default 2 to whatever is in fderr
  dup2(fderr, 2);
  close(fderr);

  //set initial input
  int fdin;
  if (_inFile) {
    fdin = open(_inFile, O_RDONLY);
  }
  else {
    fdin = dup(defaultin);
  }


  int pid; //process
  int fdout; //output
  //go for every simple command
  int i;
  for (i = 0; i < _numOfSimpleCommands; i++) {

    //set currentSimpleCommand
    _currentSimpleCommand = _simpleCommands[i];

    //redirect input from default 0 to whatever is in fdin
    dup2(fdin, 0);
    close(fdin);

    //setup output
    //if its the last command check for out file...
    if (i == _numOfSimpleCommands - 1) {
      if (_outFile) {
        //todo -> perform some sort of check to decide if you should append
        if (_append == 0) {
          fdout = open(_outFile, O_CREAT | O_WRONLY, 0666);
        }
        else if (_append == 1) {
          fdout = open(_outFile, O_APPEND | O_WRONLY, 0666);
        }
      }
      else {
        fdout = dup(defaultout);
      }
    }
    //...else make pipe
    else {
      //declare array, make pipe, redirect in and out
      int fdpipe[2];
      pipe(fdpipe);
      fdout = fdpipe[1]; //write to 1
      fdin = fdpipe[0]; //read from 0
    }

    //redirect output from default 1 to whatever is in fdout
    dup2(fdout, 1);
    close(fdout);

    //if trying to change directory don't fork
    if (!strcmp(_currentSimpleCommand->_arguments[0], "cd")) {
      
      //if going to the home directory 
      if (_currentSimpleCommand->_arguments[1] == NULL) {
        chdir(getenv("HOME"));
      }
      else {
        chdir(_currentSimpleCommand->_arguments[1]);
      }

    }
    //if trying to setenv don't fork
    else if (!strcmp(_currentSimpleCommand->_arguments[0], "setenv")) {
      //printf("set env");
      int len1 = strlen(_currentSimpleCommand->_arguments[1]);
      int len2 = strlen(_currentSimpleCommand->_arguments[2]);
      char * word = new char[len1 + len2 + 1];
      strcpy(word, _currentSimpleCommand->_arguments[1]);
      strcat(word, "=");
      strcat(word, _currentSimpleCommand->_arguments[2]);

      putenv(word);
    }
    //if trying to unset env also don't fork
    else if (!strcmp(_currentSimpleCommand->_arguments[0], "unsetenv")) {
      unsetenv(_currentSimpleCommand->_arguments[1]);
    }
    //if you are trying to read from source let lex handle it 
    else if (!strcmp(_currentSimpleCommand->_arguments[0], "source")) {

      //fork new child process
      pid = fork();
    
      //error occured
      if (pid == -1) {
        perror ("fork fail");
        exit(2);
      }
    
      //fork successful
      if (pid == 0) {
        _currentSimpleCommand->_arguments++;
        execvp(_currentSimpleCommand->_arguments[0], _currentSimpleCommand->_arguments);
        //_currentSimpleCommand->_arguments[0] = (char*)"cat";
        //execvp("cat", _currentSimpleCommand->_arguments);
        
        //execvp shouldn't return if it gets here something went wrong
        perror("exec fail");
        exit(2);
      }
    }


    //else normal command, go ahead and fork
    else {
      //fork new child process
      pid = fork();
    
      //error occured
      if (pid == -1) {
        perror ("fork fail");
        exit(2);
      }
    
      //fork successful
      if (pid == 0) {
  
        /*store the pid if it is in the background
        if (_background) {
          lastBackPid = getpid();
          printf("pid: %d\n", lastBackPid);
        }
        */

        execvp(_currentSimpleCommand->_arguments[0], _currentSimpleCommand->_arguments);

        //execvp shouldn't return if it gets here something went wrong
        perror("exec fail");
        exit(2);
      }
    }
  }

  //restore in/out/err defaults
  dup2(defaultin, 0);
  dup2(defaultout, 1);
  dup2(defaulterr, 2);

  close(defaultin);
  close(defaultout);
  close(defaulterr);
  
  //wait if the proccess isn't running in the background
  if (!_background) {
    waitpid(pid, NULL, 0);
  }
  
  // Clear to prepare for next command
	clear();
	
  _mro = 0;
  _mri = 0;
  _mre = 0;

	// Print new prompt
	prompt();
}

//function that gets called when ctrl-c is pressed
extern "C" void ctrlc(int sig) {
  fprintf(stderr, "\nsig:%d    Ouch!\n", sig);
  Command::_currentCommand.prompt();
}

//function that gets called to eliminate zombies
extern "C" void zombieKill(int sig) {
  
  //wait on any child process
  //go until it returns something not a pid 
  while (waitpid(-1 , NULL, WNOHANG) >= 1);

}

// Shell implementation

void Command::prompt() {
    
  //handle ctrl-c
  struct sigaction saC;
  saC.sa_handler = ctrlc;
  sigemptyset(&saC.sa_mask);
  saC.sa_flags = SA_RESTART;
  if(sigaction(SIGINT, &saC, NULL)){
    perror("sigaction");
    exit(2);
  }

  //eliminate zombie processes
  struct sigaction saZ;
  saZ.sa_handler = zombieKill;
  sigemptyset(&saZ.sa_mask);
  saZ.sa_flags = SA_RESTART;
  if(sigaction(SIGCHLD, &saZ, NULL)){
    perror("sigaction");
    exit(2);
  }

  //prompt
  if ( isatty(0) ) {
    printf("myshell>");
  }
	fflush(stdout);

}

Command Command::_currentCommand;
SimpleCommand * Command::_currentSimpleCommand;
