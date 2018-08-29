\input epsf

@* Introduction.
This program solves a mathematical problem:

\begingroup\narrower\narrower
\sl Given $n$ numbers $a_1, \dots, a_n$, and a number $G$.
Find an expression that consists of these $n$ numbers and arithmetic operators
(i.e., $+$, $-$, $\times$ and $\div$) and evaluates to $G$.
\par\endgroup

To simplify the program, we assume that $a_1, \dots, a_n$ and $G$ are integers.

@* Rational arithmetics.
As division is not closed on integers, we need to perform the operations on
the rational numbers.
Structure |rat_t| represents a rational number.  The fields |num| and |den|
are the numerator and denominator, respectively.  The type is unsigned.
The behavior is undefined when |den==0|.

@s rat_t int
@c
typedef struct {
	unsigned short num;
	unsigned short den;
} rat_t;

@ The Euclidean algorithm is used for finding the greatest common divisor.
@c
unsigned gcd(unsigned x, unsigned y)
{
	return y ? gcd(y, x % y) : x;
}

@ Function |mkrat| returns a reduced rational number.
@c
rat_t mkrat(unsigned num, unsigned den)
{
	rat_t z;
	unsigned g;

	g = gcd(num, den);
	z.num = num / g;
	z.den = den / g;
	return z;
}

@ Addition. ${a\over b}+{c\over d}={ad+bc\over bd}$.
@c
rat_t ratadd(rat_t x, rat_t y)
{
	return mkrat(x.num * y.den + y.num * x.den, x.den * y.den);
}

@ Subtraction. ${a\over b}-{c\over d}={ad-bc\over bd}$.
Behavior is undefined if $x$ is smaller than $y$.

@c
rat_t ratsub(rat_t x, rat_t y)
{
	return mkrat(x.num * y.den - y.num * x.den, x.den * y.den);
}

@ Comparison.
@c
int ratcmp(rat_t x, rat_t y)
{
	unsigned a, b;

	a = x.num * y.den;
	b = y.num * x.den;
	return (a < b) ? -1 : (a > b) ? 1 : 0;
}

@ Multiplication.  ${a\over b}\times{c\over d}={ac\over bd}$.
@c
rat_t ratmul(rat_t x, rat_t y)
{
	return mkrat(x.num * y.num, x.den * y.den);
}

@ Division.  ${a\over b}\div{c\over d}={ad\over bc}$.
@c
rat_t ratdiv(rat_t x, rat_t y)
{
	return mkrat(x.num * y.den, x.den * y.num);
}

@* Input/Output.
Functios |putrat| and |getrat| can be used for inputting/outputting
the rationals.  These functions works well with integers.

@c
#include <stdio.h>

@ @c
int putrat(rat_t x, FILE *f)
{
	if (x.den == 1)
		return fprintf(f, "%u", x.num);
	return fprintf(f, "%u/%u", x.num, x.den);
}

@ @c
rat_t getrat(FILE *f)
{
	rat_t x = {0, 0};

	if (fscanf(f, "%hu/%hu", &x.num, &x.den) == 1)
		x.den = 1;
	return x;
}

@* The sorting algorithm.
Here's the bubble sort algorithm for rational numbers.
@c
void bubble_sort(rat_t numbers[], int n)
{
	int i, j;

	for (i = 1; i < n; i++) {
		for (j = 0; j < n - i; j++) {
			if (ratcmp(numbers[j], numbers[j+1]) > 0) {
				rat_t t;
				t = numbers[j];
				numbers[j] = numbers[j+1];
				numbers[j+1] = t;
			}
		}
	}
}

@* The search algorithm.
We use a backtracking algorithm.  This algorithm requires a stack
(or implicitly by recursion).  In this program, we will use an explicit
stack allocated on the heap.

@c
#include <stdlib.h> /* for |calloc|, etc. */

@ The stack contains numbers or operators, which forms a (partial)
postfix expression when printed from bottom to top.

For example, a stack may have these elements:
$$\hbox{\tt 5 1 5 / - 5 *}$$
which evaluates to 24.

Each stack frame is represented by the |stack_frame| structure.
What a stack frame contains is indicated by its |idx| field:
\item{$\bullet$} When |idx>=0|, this frame contains a number in
an array specified elsewhere with the corresponding index;
\item{$\bullet$} When |idx<0|, this frame contains an operator.
$+$, $-$, $\times$ and $\div$ are numbered from $-4$ to $-1$.

\smallskip
To deal with partial postfix expression, the concept of
{\it evaluation stack\/} is introduced here.
The postfix expression can be evaluated using a stack: numbers are
pushed onto the stack, and an operator pops two numbers and pushes
the result.
While we mutate the stack, we also maintain the state of the evaluation
stack.  This is done by adding |eval| and |prev_eval| fields in the stack
frame.  These fields essentially form a linked list.

Example:
$$\tabskip\centering\halign to\displaywidth{
#\hfil&&\tt\hfil#\hfil\cr
Index&0&1&2&3&4&5&6\cr
Number/operator&5&1&5&/&-&5&*\cr
|eval|&5&1&5&1/5&24/5&5&24\cr
|prev_eval|&-1&0&1&0&-1&4&-1\cr
}$$
Or, graphically,
$$\epsfbox{calc.1}$$
In each stack frame, there is an associated evaluation stack, but the storage
of the evaluation stack is embeded in the search stack.
The evaluation stack has 2 elements at level~5, but only 1 at level~6.
When backtracking, the stack frame at level~6 is dropped, and the evaluation
stack goes back to the previous state.

@s stack_frame int
@c
typedef struct {
	rat_t eval;    /* evaluation value */
	int prev_eval; /* index to previous frame in the evaluation stack */
	int idx;       /* index to number, $[-4,-1]$ for op */
} stack_frame;

@ The |print_stack| function prints the stack from bottom to top.
It will be used for outputting solutions.

@c
void print_stack(rat_t numbers[], stack_frame *base, stack_frame *top)
{
	for (; base != top; ++base) {
		if (base->idx < 0)
			putchar("+-*/"[base->idx+4]);
		else
			putrat(numbers[base->idx], stdout);
		putchar(' ');
	}
}

@ The |print_eval_stack| function prints the evaluation stack,
which can be used for debugging purposes.

@c
void print_eval_stack(stack_frame *stack, int i)
{
	while (i != -1) {
		putrat(stack[i].eval, stdout);
		putchar(' ');
		i = stack[i].prev_eval;
	}
}

@ Here comes the most interesting part: the search function.
This is a recursive algorithm manually translated into a non-recursive
function, with the help of labels and |goto| statements.

@c
void search(rat_t numbers[], int n, rat_t goal)
{
	stack_frame *stack, *top, *sp;
	unsigned char *used;

	bubble_sort(numbers, n);
	stack = sp = calloc(n+n-1, sizeof *stack);
	top = stack + n+n-1;
	used = calloc(n, sizeof *used);

recur:  /* a new level of recursion */
	if (sp == top) {
		@<If the expression evaluates to |goal|, print it@>;
		goto ret;
	}
	@<Set |sp->idx| to |-4| if the eval stack has more than 2 elements;
		otherwise, set it to 0@>;
loop:   /* try the number/operator indicated by |sp->idx| */
	if (sp->idx < 0)
		@<Recurse over operators@>;
	@<Recurse over numbers@>;
ret:    /* return from recursion */
	if (sp != stack) {
		sp--;
		@<Increment |sp->idx|@>;
		goto loop; /* continue the loop in the previous level */
	}

	free(used);
	free(stack);
}

@ When the stack is full, the evaluation stack should contain exactly one
number, which is |sp[-1].eval|.
Note that |sp| points to the stack frame that is going to be pushed into
the stack; the top frame is |sp[-1]|.

@<If the expression evaluates...@>=
if (ratcmp(sp[-1].eval, goal) == 0) {
	print_stack(numbers, stack, sp);
	putchar('\n');
}

@ How to tell if the evaluation stack has 2 elements?
If the stack is empty (|sp==stack|), then the evaluation stack
is empty as well.
Otherwise, the top frame of the stack contains the top element 
in the eval stack.
If that frame has a valid |prev_eval|, then the evaluation stack
has at least 2 elements.
This is a very handy test condition as we do not have to maintain
counters of numbers and operators in the stack.

@<Set |sp->idx|...@>=
if (sp != stack && sp[-1].prev_eval != -1)
	sp->idx = -4;
else
	sp->idx = 0;

@ To recurse over operators, we need to pick the operands from
the evaluation stack.
The top and second top elements in the evaluation stack will be used as the
left hand side (|lhs|) and right hand side (|rhs|), respectively.

The array |opfunc| records which operators are going to be used.
Its declarator is a bit nasty: it is an array with 4 elements, each being
a pointer to a function that takes two |rat_t|s and returns a |rat_t|.
This array is not stored in the stack frame.  Therefore, its value has
to be recomputed across recursion levels, which makes the algorithm suboptimal.

@<Recurse over operators@>=
{
	stack_frame *lhs, *rhs;
	rat_t @[(*opfunc[4])@](rat_t, rat_t) = {
		ratadd, ratsub, ratmul, ratdiv
	};

	rhs = &sp[-1];
	lhs = &stack[rhs->prev_eval];
	@<Perhaps disable a few operators@>;
	for (; sp->idx < 0; sp->idx++) {
		rat_t @[(*f)@](rat_t, rat_t);
		f = opfunc[sp->idx + 4];
		if (f != NULL) {
			sp->eval = f(lhs->eval, rhs->eval);
			sp->prev_eval = lhs->prev_eval;
			sp++;
			goto recur;
		}
	}
}

@ We will disable subtraction only when |lhs<rhs| in order to avoid
negative numbers.  The division is disabled when |rhs==0|.

@<Perhaps disable...@>=
if (ratcmp(lhs->eval, rhs->eval) < 0)
	opfunc[1] = NULL;
if (rhs->eval.num == 0)
	opfunc[3] = NULL;

@ Recursing over numbers is easier.  However, we must be careful so that
the same number (i.e., the same |idx|) will not be used repeatedly.
The array |used| was created for this purpose, and was cleared initially.

@<Recurse over numbers@>=
for (; sp->idx < n; sp->idx++) {
	if (!used[sp->idx]) {
		sp->eval = numbers[sp->idx];
		sp->prev_eval = sp - stack - 1;
		used[sp->idx] = 1;
		sp++;
		goto recur;
	}
}

@ When returning to the previous level, we need to try the next |idx|.

Some complications when the current |idx| corresponds to a number:
\item{$\bullet$} The |used| array have to be updated so that |idx|
is no longer marked in use;
\item{$\bullet$} We should skip identical values so that we will not
generate duplicate expressions.  This is why the numbers were sorted
in the beginning.

@<Increment |sp->idx|@>=
if (sp->idx >= 0) {
	used[sp->idx] = 0;
	do
		sp->idx++;
	while (sp->idx < n && ratcmp(numbers[sp->idx-1], numbers[sp->idx]) == 0);
} else {
	sp->idx++;
}

@* The program.
The main program is very brief.  We define a constant |N| here for $a_1$, \dots,
$a_N$.  These numbers are read from standard input, as well as $G$.

@c

int main(int argc, char *argv[])
{
	int n = 4;
	rat_t *numbers;
	int i;
	rat_t goal;


	if (argc == 2)
		sscanf(argv[1], "%d", &n);

	numbers = malloc(n * sizeof (rat_t));
	for (i = 0; i < n; i++)
		numbers[i] = getrat(stdin);
	goal = getrat(stdin);

	search(numbers, n, goal);

	free(numbers);
	return 0;
}


@* Index.
