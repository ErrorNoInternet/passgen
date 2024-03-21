#include <math.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>

#define BUFFER_SIZE 8192
#define PREFIX_SIZE 512

char buffer[BUFFER_SIZE];
unsigned short buffer_usage;

void generate(char keywords[64][64], unsigned char keyword_count,
              unsigned char keyword_lengths[64], char prefix[PREFIX_SIZE],
              unsigned char prefix_length, unsigned char level) {
    if (buffer_usage >= BUFFER_SIZE - prefix_length) {
        write(1, buffer, buffer_usage);
        buffer_usage = 0;
    };
    if (level == 0) {
        prefix[prefix_length] = '\n';
        memcpy(buffer + buffer_usage, prefix, prefix_length + 1);
        buffer_usage += prefix_length + 1;
    } else {
        for (unsigned char i = 0; i < keyword_count; i++) {
            unsigned char keyword_length = keyword_lengths[i];
            memcpy(prefix + prefix_length, keywords[i], keyword_length);
            generate(keywords, keyword_count, keyword_lengths, prefix,
                     prefix_length + keyword_length, level - 1);
        }
    }
}

unsigned long long calculate_combinations(unsigned long long n,
                                          unsigned int i) {
    if (i == 1) {
        return n;
    } else {
        return pow(n, i) + calculate_combinations(n, i - 1);
    }
}

int main(int argc, char *argv[]) {
    char keywords[64][64];
    unsigned char keyword_count = 0;
    unsigned char keyword_lengths[64];
    int do_calculate_combinations = 0;

    int i;
    for (i = 1; i < argc; i++) {
        if (!strcmp(argv[i], "-c")) {
            do_calculate_combinations = 1;
        } else {
            strcpy(keywords[keyword_count++], argv[i]);
        }
    }
    if (keyword_count == 0) {
        printf("no keywords specified!\n");
        return 1;
    }

    if (do_calculate_combinations) {
        unsigned long long lines =
            calculate_combinations(keyword_count, keyword_count) + 1;
        long double average_length = 0;
        for (i = 0; i < keyword_count; i++)
            average_length += strlen(keywords[i]);
        average_length /= keyword_count;
        long double bytes = 1.0;
        for (i = 1; i <= keyword_count; i++) {
            long double current_lines = pow(keyword_count, (long double)i);
            bytes += current_lines + current_lines * (average_length * i);
        }
        printf("keywords: %d\n\nlines: %llu\nbytes: %.0Lf\n",
               keyword_count, lines, bytes);
    } else {
        for (i = 0; i < keyword_count; i++) {
            keyword_lengths[i] = strlen(keywords[i]);
        };
        char prefix[PREFIX_SIZE];
        for (i = 0; i <= keyword_count; i++) {
            generate(keywords, keyword_count, keyword_lengths, prefix, 0, i);
        }
    }
    if (buffer_usage > 0)
        write(1, buffer, buffer_usage);
    return 0;
}
