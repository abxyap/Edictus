#include <dlfcn.h>
#include <limits.h>
#include <spawn.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <sys/proc.h>
#import <sys/sysctl.h>

char *getProcessNameFromPID(int pid) {
    int mib[4] = { CTL_KERN, KERN_PROC, KERN_PROC_PID, pid };
    struct kinfo_proc kp;
    size_t size = sizeof(kp);
    char *name = malloc(MAXCOMLEN+1);

    if (sysctl(mib, sizeof(mib)/sizeof(*mib), &kp, &size, NULL, 0) < 0) {
        return NULL;
    }

    strncpy(name, kp.kp_proc.p_comm, MAXCOMLEN);
    name[MAXCOMLEN] = '\0';

    return name;
}

int proc_pidpath(int pid, void *buffer, uint32_t buffersize);
bool print = true;

void printhelp() {
  printf("Used for the 'Edictus' Application. And based on gizroot for Packager by Conor. If you are seeing this menu, "
         "you are special! 😉\n\nParameters:\n --help (-h): Displays this "
         "menu\n --silent (-s): Stops all logging apart from errors or program "
         "output\n --test (-t): Only elevates permissions, no commands are "
         "run\n --status (-st): Returns 1 if root, 0 if not root.\nSyntax: "
         "edictusroot (paramaters) [command]\n");
}

int main(int argc, char *argv[], char *envp[]) {
  // Check parent process, courtesy of
  // https://github.com/wstyres/Zebra/blob/master/Supersling/main.c
  pid_t pid = getppid();

  char *name = getProcessNameFromPID(pid);
  // NSLog(@"[MyEdictus] name: %s", name);
  if (strcmp(name, "Edictus") != 0) {
    fflush(stdout);
    printf("[edictusroot] you are not edictus...\n");
    return 1;
  }

  if (argc == 1) {
    printhelp();
    return 64;
  }

  bool hasFirstArg = false;

  if (argc > 1) {
    if (strcmp(argv[1], "--silent") == 0 || strcmp(argv[1], "-s") == 0) {
      print = false;
      hasFirstArg = true;
    }

    if (strcmp(argv[1], "--help") == 0 || strcmp(argv[1], "-h") == 0) {
      printhelp();
      return 0;
    }

    if (strcmp(argv[1], "--test") == 0 || strcmp(argv[1], "-t") == 0) {
      printf("[edictusroot] setting uid to 0...\n");
      setuid(0);

      if (!getuid()) {
        printf("[edictusroot] we got root! (uid is %u)\n", getuid());
        return 0;
      } else {
        printf("[edictusroot] uh oh, no root... :( (uid is %u). are permissions "
               "set correctly?\n",
               getuid());
        return 1;
      }
    }

    if (strcmp(argv[1], "--status") == 0 || strcmp(argv[1], "-st") == 0) {
      print = false;
      setuid(0);

      if (!getuid()) {
        printf("1");
        return 0;
      } else {
        printf("0");
        return 1;
      }
    }
  }

  size_t totalLength = 0;
  for (int i = (hasFirstArg ? 2 : 1); i < argc; i++) {
    totalLength += strlen(argv[i]);
    totalLength += 1;
  }

  char *c = (char *)malloc(totalLength);
  memset(c, '\0', totalLength);

  int arrayIndex = 0;
  for (int i = (hasFirstArg ? 2 : 1); i < argc; i++) {
    for (int j = 0; j < strlen(argv[i]); j++) {
      c[arrayIndex++] = argv[i][j];
    }
    if (i != argc - 1) {
      c[arrayIndex++] = ' ';
    }
  }

  if (print) {
    printf("[edictusroot] setting uid to 0...\n");
  }

  setuid(0);

  if (!getuid()) {
    if (print) {
      printf("[edictusroot] we got root! (uid is %u)\n", getuid());
      printf("[edictusroot] running command: %s\n", c);
    }

    // FILE *fp;
    // char path[1035];

    // fp = popen(c, "r");
    // if (fp == NULL) {
    //   printf("[edictusroot] failed to run command\n");
    //   return 1;
    // }

    // /* Read the output a line at a time - output it. */
    // while (fgets(path, sizeof(path), fp) != NULL) {
    //   printf("%s", path);
    // }

    // /* close */
    // pclose(fp);


    // int new_argc = argc - 1;
    // char** new_argv = malloc(new_argc * sizeof(char*));
    // memcpy(new_argv, argv + 1, new_argc * sizeof(char*));

  char* new_argv[argc];
  for (int i = 1; i < argc; i++) {
      new_argv[i-1] = argv[i];
  }
  new_argv[argc-1] = NULL;


  // for (int i = 0; i < argc-1; i++) {
  //   NSLog(@"[MyEdictus] cmd: %s\n", new_argv[i]);
  // }

    pid_t our_pid;
    int our_status;
    char *executable_path = malloc((strlen("/var/jb/usr/bin/") + strlen(new_argv[0]) + 1) * sizeof(char));
    strcat(executable_path, "/var/jb/usr/bin/");
    strcat(executable_path, new_argv[0]);
    // printf("executable_path: %s\n", executable_path);
    posix_spawn(&our_pid, executable_path, NULL, NULL, (char* const*)new_argv, NULL);
    waitpid(our_pid, &our_status, WEXITED);

    return 0;
  } else {
    if (print) {
      printf("[edictusroot] uh oh, no root... :( (uid is %u). are permissions set "
             "correctly?\n",
             getuid());
    }
    return 1;
  }
}
