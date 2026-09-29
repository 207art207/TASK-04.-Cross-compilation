#include <stdio.h>
#include <sys/utsname.h>
#include <time.h>

int print_env_info(FILE *stream, struct utsname *info, char *timestamp)
{
    return fprintf(stream,
        "=== ENVIRONMENT INFORMATION ===\n"
        "Hostname: %s\n"
        "Time: %s"
        "OS: %s\n"
        "Kernel release: %s\n"
        "Kernel version: %s\n"
        "Hardware platform: %s\n\n",
        info->nodename, timestamp, info->sysname,
        info->release, info->version, info->machine);
}

int main(int argc, char *argv[])
{
    struct utsname info;
    time_t current_time;
    char *timestamp;

    // check if argument count > 2
    if (argc > 2) {
        fprintf(stderr, "Usage: %s [file]\n", argv[0]);
        return 1;
    }

    // check success of uname()
    if (uname(&info) != 0) {
        perror("uname");
        return 1;
    }

    current_time = time(NULL);
    if (current_time == (time_t)-1) {
        perror("time");
        return 1;
    }

    timestamp = ctime(&current_time);
    if (timestamp == NULL) {
        fprintf(stderr, "Could not format time\n");
        return 1;
    }

    // check output to console
    if (print_env_info(stdout, &info, timestamp) < 0 || // Print info to console
        fflush(stdout) == EOF) {
        perror("stdout");
        return 1;
    }

    // If need write info to file
    if (argc == 2) {
        FILE *file;

        // File exist check
        file = fopen(argv[1], "r");
        if (file != NULL) {
            fprintf(stderr,
                "Warning: file '%s' already exists. "
                "Information will be appended.\n",
                argv[1]);

            fclose(file);
        }

        // Write info to file
        file = fopen(argv[1], "a");
        if (file == NULL) {
            perror("fopen");
            return 1;
        }

        if (print_env_info(file, &info, timestamp) < 0) {
            perror("fprintf");
            fclose(file);
            return 1;
        }

        if (fclose(file) == EOF) {
            perror("fclose");
            return 1;
        }
    }

    return 0;
}