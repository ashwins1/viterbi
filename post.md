## Hidden Markov Models and The Viterbi Algorithm

Hidden Markov models can be used to model a huge variety of phenomena.
They arise whenever you have a system that changes between a number
of different _states_ at a number of discrete time steps, and at
each step emits an _observation_ based on its current state.

To borrow an example from Wikipedia, suppose you are a doctor
observing a patient over the course of several days. You want
to determine the health of the patient during this period,
but you only have access to his symptoms: whether he is normal,
cold, or dizzy. Each day, the state of his health may change,
and each day you record an observation of his symptoms which
depends on his health that day. This is a hidden Markov
model of health: an underlying state changes every day and
emits an observation at each time step.

To take another example, suppose you are a stock trader trying
to determine the mood of the market. Every day, the market may
be bullish, bearish, or neutral; and every day, you see the
market going up or down by a certain number of points. If
we assume--and this is a very strong assumption--that the
sentiment of the market tomorrow depends only on the sentiment
of the market today, then we have another hidden Markov model:
the state is the market sentiment (bull, bear, or neutral),
and the observations are the daily price movements.

Because we never see the state itself--only observations generated
by the state--the underlying sequence of states is said to be _hidden_.
The _Markov_ part alludes to the fact that the state of the
system at the next time depends only on the current state of the system
(i.e., the system is assumed to be memoryless, an assumption often known
as the _Markov assumption_).

Concretely, then, a hidden Markov model is determined by the following:
  * A set of states, $S$
  * A set of observations, $O$
  * A prior distribution over states $\pi ~:~ S \rightarrow [0, 1]$
  * A transition probability distribution $\phi ~:~ S \cross S \rightarrow [0, 1]$ giving the probability of going from one state to another
  * An observation distribution $\psi ~:~ S \cross O \rightarrow [0, 1]$ giving the the probability of a particular state generating a particular observation

We only ever see the observations, but oftentimes we are concerned with inferring the
sequence of states that generated a given observation sequence. To return
to the doctor/patient example above, we really want to know whether the
patient is healthy or ill, so that we can prescribe medicine if needed.
As stock traders, too, we ultimately care about whether the market is
bullish or bearish on a certain day so that we make trades appropriately.
The problems are complicated by _noise_ in the observations: it is
possible for a perfectly healthy patient to present symptoms of
a fever without actually being sick, and a bullish market can indeed
trade down for a day or two. Determining whether a given observation
is the result of one underlying state or another is of paramount
importance.

Mathematically, the problem is as follows: given a sequence of
observations $(o_1, o_2, o_3, \ldots, o_n) \in O^n$, what is
the maximally likely sequence of states $(s_1, s_2, \ldots, s_n) \in S^n$
that generated these observations?

In order to maximize the likelihood function over a sequence of states,
we first have to specify what the likelihood function is.
Recall that the likelihood function maps parameters (in this case,
a sequence of states) to the probability of the data given those
parameters. In our case, this probability is the probability of

  * Starting in the state $s_1$
  * For each $i = 1, 2, \ldots, n-1$,
    * Generating observation $o_i$ from state $s_i$
    * Transitioning from state $s_i$ to $s_{i+1}$
  * Generating observation $o_n$ from state $s_n$

At first glance, computing this probability looks formidable.
However, the conditional independence assumptions we have made
will make computing this probability much simpler. In
particular, the probability of transitioning from one
state to another is assumed to depend only on the initial state.
Moreover, the probability of generating an observation from
a given state is assumed to depend only on that state itself.
This means that the likelihood function satisfies the
following equation:

$L(s_1, s_2, \ldots, s_n ; o_1, o_2, \ldots, o_n) = \pi(s_1) \Prod_{i=1}^n \phi(s_i, s_{i+1}) \psi(s_i, o_i)$

Alternatively, we can work with the log--likelihood function,
which looks like this:

$LL(s_1, s_2, \ldots, s_n ; o_1, o_2, \ldots, o_n) = \log \pi(s_1) + \sum\limits_{i=1}^n \log \phi(s_i, s_{i+1}) + \log \psi(s_i, o_i)$

From here onwards, we will stick to optimizing the log--likelihood. Because
the logarithm is a monotonic function, whatever argument maximizes the log--likelihood
will also maximize the likelihood function. Moreover, multiplying together lots of
probabilities (each of which is at most 1) often yields numbers very close to 0;
to avoid issues with these probabilities being rounded to 0 because of floating point precision
issues, we will deal with log probabilities which are typically large negative numbers.
