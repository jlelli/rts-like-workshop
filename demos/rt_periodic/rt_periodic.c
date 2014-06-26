#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <linux/unistd.h>
#include <sys/syscall.h>
#include <pthread.h>
#include <math.h>
#include "rt_utils.h"

static volatile int done;

static inline void busywait(struct timespec *to)
{
	struct timespec t_step;
	while (1) {
		clock_gettime(CLOCK_THREAD_CPUTIME_ID, &t_step);
		if (!timespec_lower(&t_step, to))
			break;
	}
}

static void run(struct timespec *exec)
{
	struct timespec t_start, t_exec, t_totexec = *exec;
	
	/* get the start time */
	clock_gettime(CLOCK_THREAD_CPUTIME_ID, &t_start);

	/* compute finish time for CPUTIME_ID clock */
	t_exec = timespec_add(&t_start, &t_totexec);
	busywait(&t_exec);
}


void *run_deadline(void *data)
{
	unsigned int wcet, runtime, deadline, period;
	long slack;
	struct timespec t_next, t_wcet, t_deadline, t_abs_deadline, t_period;

	printf("deadline thread started [%ld]\n", gettid());

	/**
	 * Parameters (10/30 bw):
	 * WCET = 8ms
	 * budget = 10ms
	 * deadline = 30ms
	 * period = 30ms
	 */
	wcet = 8;
	runtime = 10;
	period = deadline = 30;
	
	t_wcet = usec_to_timespec(wcet * USEC_PER_MSEC);
	t_deadline = nsec_to_timespec(deadline * NSEC_PER_MSEC);
	t_period = nsec_to_timespec(period * NSEC_PER_MSEC);

	/* create a reservation */
	set_deadline(runtime, deadline, period);

	clock_gettime(CLOCK_MONOTONIC, &t_next);
	t_abs_deadline = timespec_add(&t_next, &t_deadline);
	while (!done) {
		struct timespec t_start, t_end, t_slack;

		clock_gettime(CLOCK_MONOTONIC, &t_start);
		run(&t_wcet);
		clock_gettime(CLOCK_MONOTONIC, &t_end);

		t_slack = timespec_sub(&t_abs_deadline, &t_end);
		slack = timespec_to_lusec(&t_slack);
		printf("slack = %ld\n", slack);
		if (slack < 0) {
			done = 0;
			perror("!!!DEADLINE MISS!!!");
			exit(-1);
		}

		t_next = timespec_add(&t_next, &t_period);
		t_abs_deadline = timespec_add(&t_next, &t_deadline);
		clock_nanosleep(CLOCK_MONOTONIC, TIMER_ABSTIME, &t_next, NULL);
	}

	printf("deadline thread dies [%ld]\n", gettid());
	return NULL;
}

int main (int argc, char **argv)
{
	pthread_t thread;

	printf("main thread [%ld]\n", gettid());

	pthread_create(&thread, NULL, run_deadline, NULL);

	sleep(10);

	done = 1;
	pthread_join(thread, NULL);

	printf("main exits [%ld]\n", gettid());

	return 0;
}
