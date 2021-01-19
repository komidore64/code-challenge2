# Code Challenge 2

## PLEASE NOTE

This code challenge repo was originally part of an interview take-home
assignment. It has been sanitized to remove all mention of the company. As a
result of this sanitization, the original commit history can no longer be
displayed, but please rest assured it was fun and entertaining. Take it from
me: I wrote it!

## Assignment

Create a system that emulates a data collection engine.

The data collection engine should collect resources from a source API.

(A resource is what we will call an individual record that we are
collecting.)

A resource should be sent to a data processor immediately after it has
been collected. A data processor should start processing between 0 and
2 seconds after it has been sent to processing.

Each resource should take between 0 and 7 seconds to process with a 25%
chance of failing. When a resource fails to process, it should be
re-scheduled. If a resource has failed to process 3 times, it will not be
rescheduled. The data processor should add the property `processed` to `true`
or `false` depending on if it was successful and the `processing_date` for the
timestamp the resource was processed on.

You should only have 5 data processors. 4 data processors should take in
new resources. 1 data processor should be reserved for retrying failures.
Each data processor should only be able to process 5 resources at a time.
If all data processors are full, reject the resource, set `processed` to
`false`.

### Source API

For the purpose of this exercise, the source API is simply an URL that
returns json data:

_REMOVED_

_In place of a source URL, I have altered the code to take input from a file._

### Output

Your system should output the result json to a file: `output.json`.

The output should be a JSON array of the processed resources. For example:

```json
[
  {
    "id": "924c8cfbd9f94155985bf262cf2c3c67",
    "source": "MessagingSystem",
    "title": "Where are my pants?",
    "creation_date": "2030-08-24T17:16:52.228009",
    "message": "Erlang is known...",
    "tags": [
      "no",
      "collection",
      "building",
      "seeing"
    ],
    "author": "Dominic Mccormick",
    "processing_date": "2030-08-24T17:16:52.228009",
    "processed": true
  }
]
```

### Grading Criteria

Build a solution for the above requirements and fulfills the following to
the best of your ability:

- Handles all requirements described above
- Do not use any external system to accomplish (PostgreSQL, Kafka, etc).
  The solution should be self contained and the main output being logs and
  the json file.
- The delays, chance of failure, number of data processors and max
  resources that can be processed should be configurable.
- Runs successfully from command line.
- Demonstrates appropriate usage of data structures, design patterns and
  concurrency.
- Has console/log output to allow reviewers to understand the real-time
  operations of the system as they occur. Output should give a view of all
  data processors at each step.
- Provides unit test coverage.
- Has README file with instructions on how to develop and run solution.
- Include description of solution, any problems you encountered and any
  additional thoughts in README.

## Solution

OMG almost 2000 lines of code! This was a tough problem but I _extremely_
enjoyed working on this. It's been a while since I've had the opportunity to
sit down and focus on some code for hours and hours.

tree:

```
$ tree -a -I .git
.
├── bin
│   └── code-challenge2
├── .github
│   └── workflows
│       └── ruby.yml
├── lib
│   ├── code_challenge2
│   │   ├── cli.rb
│   │   ├── director.rb
│   │   ├── logging.rb
│   │   ├── processor.rb
│   │   ├── resource_pool.rb
│   │   ├── resource.rb
│   │   └── retry_processor.rb
│   └── code_challenge2.rb
├── test
│   ├── fixtures
│   │   ├── payload.json
│   │   └── record.json
│   ├── director_test.rb
│   ├── processor_test.rb
│   ├── resource_pool_test.rb
│   ├── resource_test.rb
│   ├── retry_processor_test.rb
│   └── test_helper.rb
├── Gemfile
├── Gemfile.lock
├── input.json
├── LICENSE
├── Rakefile
├── README.md
├── .rubocop.yml
├── .ruby-gemset
└── .ruby-version

7 directories, 27 files
```

Lines of code (because I found it interesting):

```
$ git ls-files | grep -v -e LICENSE -e input.json | xargs wc -l
   43 .github/workflows/ruby.yml
   51 .rubocop.yml
    1 .ruby-gemset
    1 .ruby-version
   31 Gemfile
   61 Gemfile.lock
  368 README.md
   46 Rakefile
   34 bin/code-challenge2
   25 lib/code_challenge2.rb
  195 lib/code_challenge2/cli.rb
  161 lib/code_challenge2/director.rb
   36 lib/code_challenge2/logging.rb
  144 lib/code_challenge2/processor.rb
  107 lib/code_challenge2/resource.rb
   80 lib/code_challenge2/resource_pool.rb
   41 lib/code_challenge2/retry_processor.rb
  165 test/director_test.rb
   17 test/fixtures/payload.json
   15 test/fixtures/record.json
  113 test/processor_test.rb
   82 test/resource_pool_test.rb
   82 test/resource_test.rb
   58 test/retry_processor_test.rb
   39 test/test_helper.rb
 1996 total
```

### Setup

This solution assumes [RVM](https://rvm.io) is present.

```sh
git clone https://github.com/komidore64/code-challenge2.git
cd code-challenge2
bundle install
```

### CI/CD

`rake test` for unit tests.

`rake lint` to check code styling.

`rake clean` to clean up the repo.

### Run it!

`bin/code-challenge2 input.json` to start the ~~chaos~~magic!

help output:

```
$ bin/code-challenge2 --help
USAGE: code-challenge2 [OPTIONS] INPUTFILE
        --max-attempts ATTEMPTS      Maximum times to attempt processing a single
                                     resource before considering it unprocessable.
                                     (default: 3)
        --processors PROCESSORS      Number of processors to create.
                                     (default: 4)
        --retry-processors PROCESSORS
                                     Number of retry processors to create.
                                     (default: 1)
        --max-startup-time SECONDS   Set the maximum time it can take a processor to
                                     startup after filling its bucket of resources.
                                     (default: 2)
        --bucket-size COUNT          Set the size of processor resource buckets.
                                     (default: 5)
        --max-process-time SECONDS   Set the maximum amount of time a resource can take
                                     to process.
                                     (default: 7)
        --fail-rate FAIL_RATE        Set the rate at which a resource will fail to
                                     process. [0.0 to 1.0 inclusive]
                                     (default: 0.25)
    -l, --log-level LEVEL            Set the log level. [debug, info, warn]
                                     (default: info)
        --dry-run                    Parse all arguments, describe what we would have
                                     done then exit.
```

## Notes

~~Alright, so there are 200 record entries.~~

Nevermind, I can't rely on that because I'm pulling from an API at
runtime.

---

Basic high-level steps from 10,000 feet:

1. Pull records from source API
2. Organize records into atomic units for processing
3. Begin processing resources
4. If a resource fails to process, reschedule it (with a maximum of
   2 retries)
5. If a resource processes successfully, add `processed: true` and
   a `processing_date` field.
6. Output results into an `output.json` file.

### Classes

#### Resource

This object represents a single resource.

It contains data from a single record given by the API, but also
processing metadata. This is where processing time and chance of failure
will live.

It's not theoretically necessary to use a lock on the Resource's
interface, but doing so might not hurt.

##### proposed methods:

- `process()`
- `processed?()`
- `processing_attempts()`

#### ResourcePool

The ResourcePool is a pool of all Resources that are not currently held by
a Processor.

The ResourcePool should use a semaphore any time its pool is accessed.

The ResourcePool will exclude unprocessed Resources with 3 failed
processing attempts from `request_resource()`.

The ResourcePool will return `true` or `false` when `needs_processing?()`
is called (filtering out 3 failed attempted Resources).

##### proposed methods:

- `add_resource()`
- `request_resource()` - returns a Resource, or nil if there are no Resources to hand out
- `needs_processing?()`

#### Processor

This is the object that does the resource processing.

The Processor is the "thread" in this thread-pooling scenario. The
Processor repeatedly asks the ResourcePool for an unprocessed Resource.
The Processor will greedily continue asking for unprocessed Resources
until it has 5 Resources in its posessession, or the ResourcePool returns
a nil object.

We will have two different kinds of Processors: a Processor and
a RetryProcessor. The Processor wants any Resource where `processed?()`
returns `false` and `processing_attempts()` is `0`, whereas the
RetryProcessor wants any Resource where `processed?()` returns `false` AND
`processing_attemps()` is greater than 0.

After processing a Resource, the Processor places the Resource back into
the ResourcePool regardless of success or failure.

##### Assumptions

1. The instructions make the following statement:

> A data processor should start processing between 0 and 2 seconds after
> it has been sent to processing.

I am going to interpret that to mean it takes between 0 and 2 seconds to
"start up" after it is told there are no more Resources available for it
to process. This means that it will only pause immediately after walking
away from the ResourcePool, but _not_ "starting up" before every
processing attempt.

##### proposed methods:

- `run!()`
- `resource_bucket_empty?()`

#### Director

The Director is the orchestrator.

The Director requests data from the source API.

The Director instantiates the Processors.

The Director fills the ResourcePool with Resources.

Once the Director has done the above tasks, it repeatedly asks the
ResourcePool if it has any remaining Resources that require processing
(remember that Resources that have failed 3 times to process no longer
require processing). If the ResourcePool reports that there are no more
Resources that require processing, then the Director asks each worker if
it has any Resources in their possession. If any Processor responds with
`true`, then the Director lets processing continue.

If the Director finds that all Resources have been processed, it will instruct
the workers to terminate, generate the `output.json` file, and exit.

## First run

I can't believe it ran without error. The only thing that happened
incorrectly so far is that I seem to have lost one resource somewhere. I ran it
with one processor, one retry processor, and 1 second for everything.

```
cat output.json | jq '. | length'
199
```

## Second run

The only code I changed was to tell the processor to wait a little bit before
asking the ResourcePool again for a resource when it was just handed `nil`.
This time I ran with all default settings and I didn't lose a resource!

Since the first run, I've not lost any resources so I'm not sure what happened
there.

---

The last couple things I decided to change were reducing a fair bit of log
messages from info to debug and tweaking some sleep times in the different
loops.
