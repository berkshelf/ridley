# 2.4.3

* [#245](https://github.com/RiotGames/ridley/pull/245) Fix for numeric and boolean attribute types

# 2.4.2

* [#244](https://github.com/RiotGames/ridley/pull/244) Fix a bug with deleting deeply nested environment attributes.

# 2.4.0

* Add support for Chef 11 User Objects

# 2.1.0

* [#228](https://github.com/RiotGames/ridley/pull/228) Add a new API for filtering log output. Useful for output you might not want to display because it is sensitive.

# 2.0.0

* [#227](https://github.com/RiotGames/ridley/pull/227) HostCommander and HostConnector code has been moved into its own gem - [found here](https://github.com/RiotGames/ridley-connectors)
  * As discussed by @jtimberman in [#225](https://github.com/RiotGames/ridley/issues/225) it makes sense to move this code based on Ridley's main purpose, and gives a decent performance boost to users who don't need this extra functionality.

# 1.7.1

* [#224](https://github.com/RiotGames/ridley/pull/224) Connection#stream will now return true/false on whether it copied the file that was streamed.
