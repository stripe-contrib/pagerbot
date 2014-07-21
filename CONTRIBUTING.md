# Contributing to pagerbot

Do you find pagerbot useful and want to get involved?
Thanks! There are plenty of ways you can help!

Please take a moment to review this document in order to make the contribution
process easy and effective for everyone involved.


<a name="bugs"></a>
## Bug reports

A bug is a _demonstrable problem_ that is caused by the code in the repository.
Good bug reports are extremely helpful - thank you!

Please report bugs you find on the project issue tracker and please provide
additional information if needed.


<a name="features"></a>
## Feature requests

Feature requests are welcome. Also feel free to create your own plugins to
extend the functionality of pagerbot and please submit them as pull requests.


<a name="pull-requests"></a>
## Pull requests

Good pull requests - patches, improvements, new features - are a fantastic
help. They should remain focused in scope be well-tested.

Adhering to the following this process helps get your pull request accepted
quickly:

1. [Fork](https://help.github.com/articles/fork-a-repo) the project, clone your
   fork, and configure the remotes:

   ```bash
   # Clone your fork of the repo into the current directory
   git clone https://github.com/<your-username>/pagerbot.git
   # Navigate to the newly cloned directory
   cd pagerbot
   # Assign the original repo to a remote called "upstream"
   git remote add upstream https://github.com/stripe/pagerbot.git
   ```

2. If you cloned a while ago, get the latest changes from upstream:

   ```bash
   git checkout master
   git pull upstream master
   ```

3. Create a new topic branch (off the main project development branch) to
   contain your feature, change, or fix:

   ```bash
   git checkout -b <topic-branch-name>
   ```

4. Commit your changes in logical chunks. 

5. Locally merge (or rebase) the upstream development branch into your topic branch:

   ```bash
   git pull [--rebase] upstream master
   ```

6. Push your topic branch up to your fork:

   ```bash
   git push origin <topic-branch-name>
   ```

7. [Open a Pull Request](https://help.github.com/articles/using-pull-requests/)
    with a clear title and description.

**IMPORTANT**: By submitting a patch, you agree to allow the project owners to
license your work under the terms of the [MIT License](LICENSE.md).
