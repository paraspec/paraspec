# Paraspec

Paraspec is a parallel RSpec test runner.

It is built with a producer/consumer architecture. A master process loads
the entire test suite and sets up a queue to feed the tests to the workers.
Each worker requests a test from the master, runs it, reports the results
back to the master and requests the next test until there are no more left.

This producer/consumer architecture enables a number of features:

1. The worker load is naturally balanced. If a worker happens to come across
a slow test, the other workers keep chugging away at the remaining tests.
2. Tests defined in a single file can be executed by multiple workers,
since paraspec operates on a test by test basis and not on a file by file basis.
3. Standard output and error streams can be[*] captured and grouped on a
test by test basis, avoiding interleaving output of different tests together.
This output capture can be performed for output generated by C extensions
as well as plain Ruby code.
4. Test results are seamlessly integrated by the master, such that
a parallel run produces a single progress bar with
[Fuubar](https://github.com/thekompanee/fuubar) across all workers.
5. Test grouping: paraspec can[**] group the tests by file, top level example
group, bottom level example group and individually by examples.
Larger groupings reduce overhead but limit concurrency.
Smaller groupings have more overhead but higher concurrency.
6. Paraspec is naturally resilient to worker failure. If a worker dies
for any reason the remaining tests get automatically redistributed among
the remaining workers. It is also possible, in theory, to provision
additional workers when a test run is already in progress, though this feature
is not currently on the roadmap.

[*] This feature is not yet implemented.

[**] Currently only grouping by bottom level example group is implemented.

## Performance

How much of a difference does paraspec make? The answer, as one might
expect, varies greatly with the test suite being run as well as available
hardware. Here are some examples:

| Example | Hardware | Sequential | Paraspec (c=2) | Paraspec (c=4) |
|---------|------------|----------------|----------------|----------|
| [MongoDB Ruby Driver](https://docs.mongodb.com/ruby-driver/current/) test suite | Travis CI | 16 minutes | 13 minutes | 10-11 minutes |
| [MongoDB Ruby Driver](https://docs.mongodb.com/ruby-driver/current/) test suite | 14-core workstation | 15 minutes | | 4 minutes |

[Exampe Travis build](https://travis-ci.org/p-mongo/mongo-ruby-driver-paraspec/builds/411986888)

Even on Travis, which is likely limited to a single core, using 4x concurrency
reduces the runtime by 5 minutes. On a developer workstation which doesn't
download binaries on every test run the speedup is closer to linear.
Waiting 4 minutes instead of 15 for a complete test suite means the engineers
can actually run the complete test suite as part of their normal workflow,
instead of sending the code to a CI platform and context switching to
a different project.

## Usage

Add paraspec to your Gemfile:

    gem 'paraspec'

This is necessary because paraspec has its own dependencies and loads
the application being tested into its environment, hence both paraspec's
and application's dependencies need to exist in the same Bundler environment.

Then, for a test suite with no external dependencies, using paraspec is
trivially easy. Just run:

    paraspec

To specify concurrency manually:

    paraspec -c 4

To pass options to rspec, for example to filter examples to run:

    paraspec -- -e 'My test'
    paraspec -- spec/my_spec.rb

For a test suite with external dependencies, paraspec sets the
`TEST_ENV_NUMBER` environment variable to an integer starting from 1
corresponding to the worker number, like
[parallel_tests](https://github.com/grosser/parallel_tests) does.
The test suite can then configure itself differently in each worker.

By default the master process doesn't have `TEST_ENV_NUMBER` set.
To have that set to `1` use `--master-is-1` option to paraspec:

    paraspec --master-is-1

## Advanced Usage

### Formatters

Paraspec works with any RSpec formatter, and supports multiple formatters
just like RSpec does. If your test suite is big enough for parallel execution
to make a difference, chances are the default progress and documentation
formatters aren't too useful for dealing with its output.

I recommend [Fuubar](https://github.com/thekompanee/fuubar) and
[RSpec JUnit Formatter](https://github.com/sj26/rspec_junit_formatter)
configured at the same time. Fuubar produces a very nice looking progress bar
plus it prints failures and exceptions to the terminal as soon as they
occur. JUnit output, passed through a JUnit XML to HTML converter like
[junit2html](https://gitlab.com/inorton/junit2html), is much handier
than going through terminal output when a run produces 100 or 1000
failing tests.

### Debugging

Paraspec offers several debugging aids. For interactive debugging use the
terminal option:

    paraspec -T

This option makes paraspec stay attached to the terminal it was
launched in, making it possible to insert e.g. `byebug` calls in supervisor,
master or worker code as well as anywhere in the test suite being executed
and have byebug work. Setting this option also removes internal timeouts
on interprocess waits and sets concurrency to 1, however concurrency
can be reset with a subsequent `-c` option:

    paraspec -T -c 2

Paraspec can produce copious debugging output in several facilities.
The debugging output is turned on with `-d`/`--debug` option:

    paraspec -d state   # supervisor, master, worker state transitions
    paraspec -d ipc     # IPC requests and responses
    paraspec -d perf    # timing & performance information

### Executing Tests Together

It is possible to specify that a group of tests should be executed in the
same worker rather than distributed. This is useful when the setup for
the tests is expensive and therefore is done once with multiple tests
defined on the result.

The grouping is defined by specifying `{group: true}` paraspec option on
a `describe` or a `context` block as follows:

    describe 'Run these together', paraspec: {group: true} do
      before(:all) do
        # expensive setup
      end
      
      it 'does something' do
        # ...
      end
      
      it 'does something else' do
        # ...
      end
      
      after(:all) do
        # teardown
      end
    end

## Caveats

The master and workers need to all define the same example groups and
examples, otherwise a worker may retrieve an example group from the master
that it is unable to run. RSpec provides a way to define tests conditionally
via `if:` and `unless:` options on contexts and examples, and if this
functionality is used it is important to make sure that all workers are
configured identically (especially if such conditional configuration is
dependent on external resources such as a network server).

Paraspec will check workers' example groups and examples for equality
with master and will raise an error if there is a mismatch.

## Known Issues

Aborting a test run with Ctrl-C can leave the workers still running.

## Bugs & Patches

Please report via issues and pull requests.

## License

MIT

## See Also

[Knapsack](https://docs.knapsackpro.com/ruby/knapsack#step-for-rspec)
